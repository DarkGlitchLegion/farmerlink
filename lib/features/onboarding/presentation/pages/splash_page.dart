import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/splash_brand.dart';
import '../widgets/splash_illustration.dart';
import '../widgets/splash_loader.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B6038), AppColors.darkGreen, Color(0xFF103F2A)],
            stops: [0, .55, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -100, right: -95, child: _GlowCircle(size: 280)),
            const Positioned(bottom: 85, left: -130, child: _GlowCircle(size: 260)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 360 ? 22 : 30,
                      vertical: height < 650 ? 12 : 20,
                    ),
                    child: Column(
                      children: [
                        const SplashBrand(),
                        SizedBox(height: height < 650 ? 12 : 20),
                        Flexible(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 480,
                                maxHeight: height * .39,
                              ),
                              child: const SplashIllustration(),
                            ),
                          ),
                        ),
                        SizedBox(height: height < 650 ? 10 : 18),
                        const SplashLoader(),
                        const SizedBox(height: 13),
                        Text(
                          'MADE FOR FARMERS IN DAVAO DEL NORTE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.cream.withValues(alpha: .58),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.65,
                          ),
                        ),
                        SizedBox(height: height < 650 ? 2 : 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.accentGreen.withValues(alpha: .13), Colors.transparent],
        ),
      ),
    ),
  );
}
