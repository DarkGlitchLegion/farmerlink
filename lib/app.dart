import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/onboarding/presentation/pages/splash_page.dart';

class FarmerLinkApp extends StatelessWidget {
  const FarmerLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmerLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashPage(),
    );
  }
}
