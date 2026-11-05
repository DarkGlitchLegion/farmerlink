import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../data/models/dashboard_models.dart';
import '../../shared/widgets/agricultural_dashboard_header.dart';

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

    return AgriculturalDashboardHeader(
      eyebrow: _greeting(),
      title: title.isEmpty ? 'Farmer' : title,
      subtitle: location.isEmpty ? 'Farm location not set' : location,
      avatar: user.avatar,
      onSignOut: onSignOut,
      status: _VerificationBadge(status: verification),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final time = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return '$time, ${user.firstName}';
  }
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
