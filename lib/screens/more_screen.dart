import 'package:dermai/models/user_model.dart';
import 'package:dermai/repositories/user_repository.dart';
import 'package:dermai/screens/auth_screen.dart';
import 'package:dermai/screens/edit_profile_screen.dart';
import 'package:dermai/screens/privacy_policy_screen.dart';
import 'package:dermai/screens/profile_screen.dart';
import 'package:dermai/screens/terms_of_use_screen.dart';
import 'package:dermai/screens/scan_history_screen.dart';
import 'package:dermai/services/auth_service.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/utils/user_utils.dart';
import 'package:dermai/widgets/profile_avatar.dart';
import 'package:dermai/widgets/sign_out_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about_screen.dart';
import 'faq_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Ensure the widget is still mounted before accessing context.
    if (!mounted) return;
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      setState(() {
        _userStream = context.read<UserRepository>().getUserStream(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          Widget profileContent;
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            profileContent = const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final userModel = snapshot.data!;
            profileContent = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProfileAvatar(radius: 50, showBorder: true),
                const SizedBox(height: 12),
                Text(
                  (userModel?.displayName ?? 'User').toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if ((userModel.email ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      userModel.email ?? '',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfileScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      minimumSize: Size.fromHeight(36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Edit profile'),
                  ),
                ),
              ],
            );
          } else {
            profileContent = const SizedBox(height: 220);
          }

          return Column(
            children: [
              Center(child: profileContent),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.cherryBlossom,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      context,
                      icon: Icons.account_circle_outlined,
                      title: 'Personal Information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'FAQ & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FaqScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Terms of Use',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TermsOfUseScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'About DermAI',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.credit_card,
                      title: 'Subscription',
                      onTap: () {
                        // TODO: Navigate to Subscription Screen
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SignOutDialog(user: snapshot.data);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);
    final color =
        isLogout ? theme.colorScheme.error : theme.colorScheme.primary;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isLogout ? color : null,
          fontWeight: isLogout ? FontWeight.w600 : null,
        ),
      ),
      trailing: isLogout
          ? null
          : Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }
}
