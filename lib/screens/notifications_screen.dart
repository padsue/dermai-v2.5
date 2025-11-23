import 'package:dermai/models/notification_model.dart';
import 'package:dermai/repositories/notification_repository.dart';
import 'package:dermai/repositories/review_repository.dart';
import 'package:dermai/services/auth_service.dart';
import 'package:dermai/utils/date_grouping_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<NotificationModel>>? _notificationsStream;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId != null) {
      setState(() {
        _notificationsStream = context
            .read<NotificationRepository>()
            .getNotificationsStreamForUser(userId);
      });
    }
  }

  void _markAsRead(NotificationModel notification) {
    if (!notification.isRead) {
      context.read<NotificationRepository>().markAsRead(notification);
    }

    // Show review dialog for completed bookings
    if (notification.type == 'booking_completed' &&
        notification.doctorId != null) {
      _showReviewDialog(notification);
    }
  }

  void _showReviewDialog(NotificationModel notification) {
    int _rating = 0;
    final TextEditingController _commentController = TextEditingController();
    String _errorMessage = ''; // hold dialog error messages
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null || notification.doctorId == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double dialogWidth = MediaQuery.of(context).size.width -
                80; // same horizontal inset as default delete dialog

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              title: const Text('Leave a Review'),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How would you rate your experience?'),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                  _errorMessage =
                                      ''; // clear error when user changes rating
                                });
                              },
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // display dialog error (if any)
                      if (_errorMessage.isNotEmpty) ...[
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Informational text about visibility of reviews (moved below error)
                      Text(
                        'Reviews are public and may be visible to others.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Share your experience (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_rating <= 0) {
                      setState(() {
                        _errorMessage = 'Please select a rating.';
                      });
                      return;
                    }

                    setState(() {
                      _errorMessage = ''; // clear previous error
                    });

                    try {
                      // Create review
                      await context.read<ReviewRepository>().createReview(
                            userId: userId,
                            doctorId: notification.doctorId!,
                            rating: _rating.toDouble(),
                            comment: _commentController.text.trim(),
                          );

                      // Send notification to doctor
                      final reviewMessage = _commentController.text
                              .trim()
                              .isNotEmpty
                          ? 'You have received a new $_rating-star review. Message: ${_commentController.text.trim()}'
                          : 'You have received a new $_rating-star review.';

                      await context
                          .read<NotificationRepository>()
                          .createNotification(
                            userId: notification.doctorId!,
                            title: 'New Feedback Received',
                            body: reviewMessage,
                            type: 'feedback_new',
                            relatedId: notification.relatedId,
                            doctorId: notification.doctorId,
                            senderType: 'patient',
                          );

                      // Notify the current user locally that their review was submitted
                      final localBody = notification.doctorId != null
                          ? 'You successfully gave a $_rating-star review to the doctor.'
                          : 'You successfully gave a $_rating-star review.';
                      await context
                          .read<NotificationRepository>()
                          .showLocalNotification(
                            title: 'Review Submitted',
                            body: localBody,
                          );

                      Navigator.of(context).pop(); // close dialog on success
                    } catch (e) {
                      // show error inside dialog
                      setState(() {
                        _errorMessage =
                            'Failed to submit review. Please try again.';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCategoryFilters(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<NotificationModel>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No notifications.'));
                  }

                  final allNotifications = snapshot.data!;
                  final filteredNotifications =
                      _filterNotifications(allNotifications);

                  if (filteredNotifications.isEmpty) {
                    return Center(
                        child: Text(
                            'No "${_selectedCategory.toLowerCase()}" notifications.'));
                  }

                  final grouped = DateGroupingHelper.groupItemsByDate(
                      filteredNotifications, (item) => item.createdAt);

                  final List<dynamic> flatList = [];
                  grouped.forEach((key, value) {
                    flatList.add(key); // Add header
                    flatList.addAll(value); // Add items
                  });

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: flatList.length,
                    itemBuilder: (context, index) {
                      final item = flatList[index];

                      if (item is String) {
                        // This is a header
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            item,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      final notification = item as NotificationModel;
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text(
                                    'Are you sure you want to delete this notification?'),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(80, 36),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(80, 36),
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          context
                              .read<NotificationRepository>()
                              .deleteNotification(notification.id);
                        },
                        child: NotificationCard(
                          notification: notification,
                          onTap: () => _markAsRead(notification),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
      List<NotificationModel> notifications) {
    switch (_selectedCategory) {
      case 'Read':
        return notifications.where((n) => n.isRead).toList();
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      default:
        return notifications;
    }
  }

  Widget _buildCategoryFilters() {
    final categories = ["All", "Read", "Unread"];
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          final theme = Theme.of(context);
          final chipTheme = theme.chipTheme;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              }
            },
            backgroundColor: theme.scaffoldBackgroundColor,
            selectedColor: AppColors.primary,
            labelStyle: chipTheme.labelStyle?.copyWith(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            shape: const StadiumBorder(
              side: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const NotificationCard(
      {Key? key, required this.notification, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = DateGroupingHelper.timeAgo(notification.createdAt);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? theme.scaffoldBackgroundColor
            : AppColors.primary.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.notifications, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeAgo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
