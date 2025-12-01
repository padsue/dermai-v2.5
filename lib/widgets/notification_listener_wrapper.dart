import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/auth_service.dart';

class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;

  const NotificationListenerWrapper({Key? key, required this.child})
      : super(key: key);

  @override
  State<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends State<NotificationListenerWrapper> {
  // Keep track of notification IDs we've already seen to avoid duplicates
  // or alerting on initial load.
  final Set<String> _knownNotificationIds = {};
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return widget.child;
    }

    final notificationRepository = context.read<NotificationRepository>();

    return StreamBuilder<List<NotificationModel>>(
      stream: notificationRepository.getNotificationsStreamForUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final notifications = snapshot.data!;

          // On first load, just populate the known IDs without alerting
          if (_isFirstLoad) {
            for (var notification in notifications) {
              _knownNotificationIds.add(notification.id);
            }
            // Use addPostFrameCallback to safely update state during build if needed
            // but here we just flip the flag.
            // We do this in a microtask to avoid "setState during build" if we were setting state.
            // Since we are just flipping a boolean for the next run, it's safe.
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) {
                 setState(() {
                   _isFirstLoad = false;
                 });
               }
             });
          } else {
            // Check for new notifications
            for (var notification in notifications) {
              if (!_knownNotificationIds.contains(notification.id)) {
                _knownNotificationIds.add(notification.id);

                // Only alert if it's not read (though new ones usually aren't)
                if (!notification.isRead) {
                  // Trigger local notification
                  // We use a microtask or post frame callback to avoid side effects during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notificationRepository.showLocalNotification(
                      title: notification.title,
                      body: notification.body,
                    );
                  });
                }
              }
            }
          }
        }

        return widget.child;
      },
    );
  }
}
