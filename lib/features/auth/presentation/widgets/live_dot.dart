// lib/features/auth/presentation/widgets/live_dot.dart
//
// Animated pulsing green dot that signals real-time data / live listings.
// Shows a solid core with an expanding, fading ring — classic "live" broadcast style.

import 'package:flutter/material.dart';

class LiveDot extends StatefulWidget {
  /// The dot colour. Defaults to green (live broadcast convention).
  final Color color;

  /// Diameter of the solid core dot. The pulsing ring expands to ~2× this.
  final double size;

  const LiveDot({
    super.key,
    this.color = const Color(0xFF22C55E),
    this.size = 8,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 2.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: ConstantTween(2.4),
        weight: 10,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 2.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween:
            Tween(begin: 0.55, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 0.55).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.6,
      height: widget.size * 2.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // pulsing fading ring
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: _opacity.value),
                ),
              ),
            ),
          ),
          // solid core
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
