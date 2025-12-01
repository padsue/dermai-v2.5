import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'consultations_screen.dart';
import 'scan_main_screen.dart';
import 'notifications_screen.dart';
import 'more_screen.dart';
import 'conversation_list_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/brand_name.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import 'scan_history_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/notification_listener_wrapper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ConsultationsScreen(),
    const ScanScreen(),
    const ConversationListScreen(),
    const ScanHistoryScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    final appProvider = context.watch<AppProvider>();

    return WillPopScope(
      onWillPop: () async {
        // If not on home tab, navigate to home tab
        if (appProvider.currentIndex != 0) {
          appProvider.changeTab(0);
          return false; // Prevent the route from being popped
        }
        // If already on home tab, allow app to exit
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: const BrandName(
            size: BrandNameSize.large,
            useSecondaryColor: true,
            alignment: MainAxisAlignment.start,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              padding: EdgeInsets.zero,
            ),
            GestureDetector(
              onTap: () {
                // Navigate to the MoreScreen which has profile options
                context.read<AppProvider>().changeTab(5);
              },
              child: const ProfileAvatar(
                radius: 16,
                showBorder: true,
              ),
            ),
          ],
          showBackButton: false,
        ),
        body: NotificationListenerWrapper(
          child: IndexedStack(
            index: appProvider.currentIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: CustomBottomNavBar(
            currentIndex: appProvider.currentIndex,
            onTap: (index) => context.read<AppProvider>().changeTab(index),
          ),
        ),
      ),
    );
  }
}
