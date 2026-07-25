// lib/features/auth/presentation/widgets/starfield_background.dart
//
// Subtle scattered-dot starfield + a faint Africa-continent silhouette,
// matching the dark welcome screen in the design mockup. Painted once with
// a fixed random seed so stars don't reposition on every rebuild, and
// cheap enough to sit behind the whole welcome screen without a perf hit.
//
// NOTE: the continent shape below is a hand-drawn placeholder path. If you
// have (or can export) an actual africa_silhouette.png — a single-color
// continent shape at ~4% white opacity, transparent background — swap the
// `_paintContinentPlaceholder` call for an `Image.asset` inside a
// `Positioned.fill` + `Opacity(opacity: 0.04)`. That will match the
// mockup's silhouette shape exactly; the painted path only approximates it.

import 'dart:math';
import 'package:flutter/material.dart';

class StarfieldBackground extends StatelessWidget {
  const StarfieldBackground({super.key, this.isDark = true});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarfieldPainter(isDark: isDark),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter({required this.isDark});

  final bool isDark;

  // Fixed seed so the star positions are stable across rebuilds/hot reload.
  static const int _seed = 42;

  @override
  void paint(Canvas canvas, Size size) {
    _paintAmbientGlow(canvas, size);
    _paintStars(canvas, size);
  }

  void _paintAmbientGlow(Canvas canvas, Size size) {
    final glowColor = isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
        : const Color(0xFF8B5CF6).withValues(alpha: 0.05);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor, Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.22),
          radius: size.width * 0.65,
        ),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  void _paintStars(Canvas canvas, Size size) {
    final rand = Random(_seed);
    final baseColor = isDark ? Colors.white : const Color(0xFF7C3AED);
    final starPaint = Paint()..color = baseColor.withValues(alpha: isDark ? 0.35 : 0.15);
    final dimStarPaint = Paint()..color = baseColor.withValues(alpha: isDark ? 0.15 : 0.08);

    // Concentrate stars in the upper ~45% of the screen above the illustration
    for (int i = 0; i < 50; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height * 0.45;
      final r = rand.nextDouble() * 1.1 + 0.3;
      final paint = rand.nextBool() ? starPaint : dimStarPaint;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    final sparklePaint = Paint()..color = baseColor.withValues(alpha: isDark ? 0.5 : 0.25);
    final sparklePositions = [
      Offset(size.width * 0.15, size.height * 0.20),
      Offset(size.width * 0.85, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.32),
    ];
    for (final pos in sparklePositions) {
      _drawSparkle(canvas, pos, 4.5, sparklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.28, center.dy - size * 0.28)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx + size * 0.28, center.dy + size * 0.28)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.28, center.dy + size * 0.28)
      ..lineTo(center.dx - size, center.dy)
      ..lineTo(center.dx - size * 0.28, center.dy - size * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}