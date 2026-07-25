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
  const StarfieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarfieldPainter(),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  // Fixed seed so the star positions are stable across rebuilds/hot reload.
  static const int _seed = 42;

  @override
  void paint(Canvas canvas, Size size) {
    _paintStars(canvas, size);
    _paintContinentPlaceholder(canvas, size);
  }

  void _paintStars(Canvas canvas, Size size) {
    final rand = Random(_seed);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final dimStarPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);

    // Concentrate stars in the upper ~55% of the screen, same as the
    // mockup — the lower half is dominated by the illustration + CTA.
    for (int i = 0; i < 70; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height * 0.55;
      final r = rand.nextDouble() * 1.1 + 0.3;
      final paint = rand.nextBool() ? starPaint : dimStarPaint;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    // A handful of slightly larger "sparkle" stars, matching the small
    // four-point sparkle accents visible near the illustration in the
    // mockup.
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final sparklePositions = [
      Offset(size.width * 0.18, size.height * 0.46),
      Offset(size.width * 0.82, size.height * 0.40),
      Offset(size.width * 0.72, size.height * 0.52),
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

  void _paintContinentPlaceholder(Canvas canvas, Size size) {
    final continentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    // Rough Africa-like silhouette, centered behind the illustration area.
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.34)
      ..cubicTo(
        size.width * 0.44, size.height * 0.30,
        size.width * 0.58, size.height * 0.31,
        size.width * 0.64, size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.70, size.height * 0.48,
        size.width * 0.66, size.height * 0.58,
        size.width * 0.62, size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.58, size.height * 0.76,
        size.width * 0.50, size.height * 0.80,
        size.width * 0.44, size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.38, size.height * 0.64,
        size.width * 0.30, size.height * 0.58,
        size.width * 0.31, size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.32, size.height * 0.40,
        size.width * 0.30, size.height * 0.37,
        size.width * 0.34, size.height * 0.34,
      )
      ..close();

    canvas.drawPath(path, continentPaint);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => false;
}