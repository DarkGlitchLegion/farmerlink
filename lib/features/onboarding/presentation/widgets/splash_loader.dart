import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading FarmerLink',
      child: SizedBox(
        width: 42,
        height: 16,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final phase = (_controller.value - index * .18) % 1;
              final opacity = .28 + .72 * (1 - (phase - .5).abs() * 2);
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.harvestYellow.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
