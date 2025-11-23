import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../repositories/user_repository.dart';
import '../utils/user_utils.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _loadUserStream();
  }

  void _loadUserStream() {
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
    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: true,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final userModel = snapshot.data!;
            final theme = Theme.of(context);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ProfileAvatar(
                    radius: 50,
                    showBorder: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userModel?.displayName ?? 'User',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (userModel.username != null)
                    Text(
                      '@${userModel.username}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                  if (userModel.createdAt != null)
                    Text(
                      'Joined ${DateFormat.yMMMMd().format(userModel.createdAt!)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  if (userModel.updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Profile updated at ${DateFormat.yMd().add_jm().format(userModel.updatedAt!)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.cherryBlossom,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildUserInfoTile(
                          context,
                          label: 'First Name',
                          value: userModel.firstName ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Middle Name',
                          value: userModel.middleName ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Last Name',
                          value: userModel.lastName ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Sex',
                          value: userModel.sex ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Date of Birth',
                          value: userModel.dateOfBirth != null
                              ? DateFormat.yMMMMd()
                                  .format(userModel.dateOfBirth!)
                              : 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Contact Number',
                          value: userModel.contactNumber ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Region',
                          value: userModel.region ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Province',
                          value: userModel.province ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Municipality/City',
                          value: userModel.municipality ?? 'Not set',
                          showDivider: false,
                        ),
                        _buildUserInfoTile(
                          context,
                          label: 'Barangay',
                          value: userModel.barangay ?? 'Not set',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('User not found.'));
          }
        },
      ),
    );
  }

  Widget _buildUserInfoTile(BuildContext context,
      {required String label, required String value, bool showDivider = true}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          if (showDivider) const Divider(),
        ],
      ),
    );
  }
}
