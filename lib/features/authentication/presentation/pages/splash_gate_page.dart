import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../onboarding/presentation/pages/splash_page.dart';
import '../providers/authentication_provider.dart';
import '../../../../core/router/app_router.dart';

class SplashGatePage extends ConsumerStatefulWidget {
  const SplashGatePage({super.key});

  @override
  ConsumerState<SplashGatePage> createState() => _SplashGatePageState();
}

class _SplashGatePageState extends ConsumerState<SplashGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authenticationProvider.notifier).restoreSession();
      if (!mounted) return;
      final auth = ref.read(authenticationProvider);
      context.go(
        auth.isAuthenticated
            ? roleDashboardLocation(auth.user!.role)
            : '/login',
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SplashPage();
}
