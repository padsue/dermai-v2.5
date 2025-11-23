import 'package:flutter/material.dart';
import 'profile_avatar.dart';
import '../utils/app_colors.dart';

class ProfileTile extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;
  final double avatarRadius;
  final bool showBorder;
  final Widget? trailing;
  final bool showChevron;

  const ProfileTile({
    super.key,
    this.imageUrl,
    required this.name,
    this.subtitle,
    this.onTap,
    this.avatarRadius = 20.0,
    this.showBorder = false,
    this.trailing,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: imageUrl,
            radius: avatarRadius,
            showBorder: showBorder,
            borderColor: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showChevron)
            Icon(
              Icons.chevron_right,
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondary
                  : AppColors.textSecondary.withOpacity(0.7),
            ),
        ],
      ),
    );
  }
}