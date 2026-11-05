import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/authentication_provider.dart';

class RoleDashboardPage extends ConsumerWidget {
  const RoleDashboardPage({super.key, required this.role});
  final String role;

  String get _title => switch (role) {
    'farmer' => 'Farmer dashboard',
    'buyer' => 'Buyer dashboard',
    'business_buyer' => 'Business buyer dashboard',
    'admin' => 'Admin dashboard',
    _ => 'Dashboard',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.eco_rounded,
                color: AppColors.primaryGreen,
                size: 54,
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome, ${user?.firstName ?? ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${_title.toLowerCase()} is ready for the next FarmerLink features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
