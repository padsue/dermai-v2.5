import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? loadingWidget;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool autoLoadUserPhoto;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20.0,
    this.loadingWidget,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.autoLoadUserPhoto = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-load user photo from stream if no imageUrl provided
    if (autoLoadUserPhoto && imageUrl == null) {
      final authService = context.read<AuthService>();
      final userRepository = context.read<UserRepository>();
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        return StreamBuilder<UserModel?>(
          stream: userRepository.getUserStream(currentUser.uid),
          builder: (context, snapshot) {
            // Use the photoUrl from the stream data if available
            final photoUrl = snapshot.data?.photoUrl;
            return _buildAvatar(context, theme, photoUrl);
          },
        );
      }
    }

    // Fallback to original behavior if not auto-loading or if imageUrl is provided
    return _buildAvatar(context, theme, imageUrl);
  }

  Widget _buildAvatar(BuildContext context, ThemeData theme, String? photoUrl) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ??
          (theme.brightness == Brightness.dark
              ? AppColors.champagne.withOpacity(0.1)
              : AppColors.champagne),
      backgroundImage: photoUrl == null || photoUrl.isEmpty
          ? const AssetImage('assets/images/default_avatar.png')
          : (photoUrl.startsWith('http')
              ? CachedNetworkImageProvider(photoUrl)
              : AssetImage(photoUrl)) as ImageProvider,
      onBackgroundImageError: (_, __) {},
    );

    final decoratedAvatar = showBorder
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? theme.colorScheme.primary,
                width: borderWidth,
              ),
            ),
            child: avatar,
          )
        : avatar;

    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: decoratedAvatar,
          )
        : decoratedAvatar;
  }
}
