// lib/shared/widgets/ticker_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TickerCard extends StatelessWidget {
  const TickerCard({
    super.key,
    required this.label,
    required this.value,
    required this.deltaLabel,
    required this.isPositive,
    required this.sparklineValues,
  });

  final String label;
  final String value;
  final String deltaLabel;
  final bool isPositive;
  final List<double> sparklineValues;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55))),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 18,
              child: CustomPaint(
                painter:
                    _SparklinePainter(values: sparklineValues, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(deltaLabel,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : maxV - minV;

    final path = Path();
    final stepX = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * size.height);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastX = (values.length - 1) * stepX;
    final lastY = size.height -
        (((values.last - minV) / range) * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
