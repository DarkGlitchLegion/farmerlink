import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AgriculturalDashboardHeader extends StatelessWidget {
  const AgriculturalDashboardHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.avatar,
    this.notificationCount = 0,
    this.onNotifications,
    this.onSignOut,
    this.onAvatarTap,
    this.status,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String? avatar;
  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignOut;
  final VoidCallback? onAvatarTap;
  final Widget? status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 23),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryGreen, AppColors.darkGreen],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.eco_rounded,
              color: AppColors.harvestYellow,
              size: 25,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'FarmerLink  DAVNOR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: .2,
                ),
              ),
            ),
            if (onNotifications != null)
              IconButton(
                tooltip: notificationCount == 0
                    ? 'Notifications'
                    : '$notificationCount unread notifications',
                onPressed: onNotifications,
                color: Colors.white,
                icon: Badge(
                  isLabelVisible: notificationCount > 0,
                  label: Text(
                    notificationCount > 99 ? '99+' : '$notificationCount',
                  ),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ...actions,
            if (onSignOut != null)
              IconButton(
                tooltip: 'Sign out',
                onPressed: onSignOut,
                color: Colors.white.withValues(alpha: .9),
                icon: const Icon(Icons.logout_rounded, size: 21),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          eyebrow,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .76),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'FarmerLink' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .76),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onAvatarTap,
              child: onAvatarTap == null
                  ? _HeaderAvatar(value: avatar)
                  : Tooltip(
                      message: 'Account profile',
                      child: _HeaderAvatar(value: avatar),
                    ),
            ),
          ],
        ),
        if (status != null) ...[const SizedBox(height: 10), status!],
      ],
    ),
  );
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    final avatar = value;
    if (avatar != null && avatar.startsWith('data:image/')) {
      try {
        final separator = avatar.indexOf(',');
        if (separator > 0) {
          return CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.memory(
                base64Decode(avatar.substring(separator + 1)),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            ),
          );
        }
      } on FormatException {
        return _fallback();
      }
    }
    if (avatar != null &&
        (avatar.startsWith('https://') || avatar.startsWith('http://'))) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(avatar),
        onBackgroundImageError: (error, stackTrace) {},
      );
    }
    return _fallback();
  }

  Widget _fallback() => const CircleAvatar(
    radius: 24,
    backgroundColor: Color(0xFFEAF3E5),
    child: Icon(Icons.person_rounded, color: AppColors.primaryGreen),
  );
}
