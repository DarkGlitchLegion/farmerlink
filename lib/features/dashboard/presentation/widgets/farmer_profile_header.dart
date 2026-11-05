import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../data/models/dashboard_models.dart';

class FarmerProfileHeader extends StatelessWidget {
  const FarmerProfileHeader({
    super.key,
    required this.user,
    this.profile,
    required this.onSignOut,
  });

  final AuthUser user;
  final FarmerProfileData? profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final title = profile?.farmName.trim().isNotEmpty == true
        ? profile!.farmName
        : user.fullName;
    final location = [
      profile?.municipality,
      profile?.province,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
    final verification = profile?.verificationStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.darkGreen],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.harvestYellow,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FarmerLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'DAVNOR',
                      style: TextStyle(
                        color: AppColors.harvestYellow,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: onSignOut,
                color: Colors.white.withValues(alpha: .88),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FarmerAvatar(avatar: user.avatar),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Farmer' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _VerificationBadge(status: verification),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withValues(alpha: .72),
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location.isEmpty
                                ? 'Farm location not set'
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .76),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmerAvatar extends StatelessWidget {
  const _FarmerAvatar({this.avatar});
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final value = avatar;
    if (value != null && value.startsWith('data:image/')) {
      final separator = value.indexOf(',');
      if (separator > 0) {
        try {
          return CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.memory(
                base64Decode(value.substring(separator + 1)),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
            ),
          );
        } on FormatException {
          return _placeholder();
        }
      }
    }
    if (value != null &&
        (value.startsWith('https://') || value.startsWith('http://'))) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(value),
        onBackgroundImageError: (error, stackTrace) {},
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => const CircleAvatar(
    radius: 30,
    backgroundColor: Color(0xFFEAF2E6),
    child: Icon(Icons.person_rounded, color: AppColors.primaryGreen, size: 32),
  );
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'approved' => (
        label: 'Verified producer',
        icon: Icons.verified_rounded,
        color: AppColors.accentGreen,
      ),
      'rejected' => (
        label: 'Verification not approved',
        icon: Icons.info_outline_rounded,
        color: AppColors.harvestYellow,
      ),
      'pending' => (
        label: 'Verification pending',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.harvestYellow,
      ),
      _ => null,
    };
    if (config == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 13),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
