import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SplashIllustration extends StatelessWidget {
  const SplashIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.56,
      child: CustomPaint(
        painter: const _FarmLandscapePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FarmLandscapePainter extends CustomPainter {
  const _FarmLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final clip = RRect.fromRectAndRadius(rect, const Radius.circular(30));
    canvas.save();
    canvas.clipRRect(clip);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF527F52), Color(0xFFB9C980)],
        ).createShader(rect),
    );

    // A warm sun and soft evening glow.
    canvas.drawCircle(Offset(w * .77, h * .27), h * .15,
        Paint()..color = AppColors.harvestYellow.withValues(alpha: .88));
    canvas.drawCircle(Offset(w * .77, h * .27), h * .23,
        Paint()..color = AppColors.harvestYellow.withValues(alpha: .12));

    _hill(canvas, w, h, const Color(0xFF79985A), [
      Offset(0, .58), Offset(.18, .47), Offset(.35, .54),
      Offset(.56, .40), Offset(.77, .52), Offset(1, .42),
    ]);
    _hill(canvas, w, h, const Color(0xFF416F43), [
      Offset(0, .72), Offset(.2, .57), Offset(.40, .65),
      Offset(.62, .51), Offset(.82, .62), Offset(1, .53),
    ]);
    _hill(canvas, w, h, const Color(0xFF285D38), [
      Offset(0, .82), Offset(.2, .70), Offset(.43, .75),
      Offset(.68, .64), Offset(.86, .73), Offset(1, .65),
    ]);

    // Field rows recede toward the horizon.
    final field = Path()
      ..moveTo(0, h * .73)
      ..quadraticBezierTo(w * .52, h * .63, w, h * .72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(field, Paint()..color = const Color(0xFF1C5533));
    final rowPaint = Paint()
      ..color = const Color(0xFF9BBE5A).withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 7; i++) {
      final x = i / 6;
      final path = Path()
        ..moveTo(w * (.5 + (x - .5) * .11), h * .69)
        ..quadraticBezierTo(w * x, h * .84, w * x, h * 1.12);
      canvas.drawPath(path, rowPaint);
    }

    // Foreground crop clusters with leafy tops.
    _plant(canvas, Offset(w * .14, h * .92), h * .32);
    _plant(canvas, Offset(w * .28, h * .96), h * .26);
    _plant(canvas, Offset(w * .79, h * .94), h * .30);
    _plant(canvas, Offset(w * .91, h * .98), h * .24);

    // Small harvest baskets add a visual cue without crowding the scene.
    final basketPaint = Paint()..color = const Color(0xFFB8793E);
    final basket = Path()
      ..moveTo(w * .43, h * .91)
      ..lineTo(w * .57, h * .91)
      ..lineTo(w * .55, h * .99)
      ..lineTo(w * .45, h * .99)
      ..close();
    canvas.drawPath(basket, basketPaint);
    canvas.drawArc(Rect.fromLTWH(w * .44, h * .87, w * .12, h * .11), 3.14, 3.14,
        false, Paint()..color = const Color(0xFFE5B36E)..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.restore();
  }

  void _hill(Canvas canvas, double w, double h, Color color, List<Offset> points) {
    final path = Path()..moveTo(0, h * points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(w * points[i].dx, h * points[i].dy);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _plant(Canvas canvas, Offset base, double height) {
    final stem = Paint()
      ..color = const Color(0xFFB7D665)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base.translate(0, -height * .62), stem);
    final leaves = <(double, double, double)>[
      (-.09, -.34, -1), (.09, -.43, 1), (-.07, -.54, -1), (.07, -.63, 1),
    ];
    for (final (dx, dy, direction) in leaves) {
      final start = base.translate(0, height * dy);
      final end = start.translate(height * dx, -height * .08);
      final leaf = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + height * dx * .45, start.dy - height * .18,
            end.dx, end.dy)
        ..quadraticBezierTo(start.dx + height * dx * .3, start.dy - height * .02,
            start.dx, start.dy)
        ..close();
      canvas.drawPath(leaf, Paint()..color = direction < 0
          ? const Color(0xFF9CC650) : const Color(0xFF6FAE48));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
