// lib/shared/widgets/shared_widgets.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';


// ─── Risk Badge ────────────────────────────────────────────────────────────────

enum RiskLevel { low, medium, high }

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key});

  factory RiskBadge.fromString(String s) {
    final level = switch (s.toLowerCase()) {
      'low' => RiskLevel.low,
      'high' => RiskLevel.high,
      _ => RiskLevel.medium,
    };
    return RiskBadge(level);
  }

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      RiskLevel.low => ('Low risk', AppColors.success),
      RiskLevel.medium => ('Med risk', AppColors.warning),
      RiskLevel.high => ('High risk', AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─── UGX Amount Text ──────────────────────────────────────────────────────────

class UgxAmount extends StatelessWidget {
  const UgxAmount(
    this.amount, {
    super.key,
    this.fontSize = 20,
    this.color,
  });

  final int amount;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatUgx(amount);
    return Text(
      'UGX $formatted',
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.accent,
      ),
    );
  }

  String _formatUgx(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ─── Currency-aware Amount Text ───────────────────────────────────────────────
/// Displays a formatted monetary amount with the given currency code prefix.
/// Replaces [UgxAmount] for multi-country listings.
class CurrencyAmount extends StatelessWidget {
  const CurrencyAmount(
    this.amount, {
    super.key,
    required this.currency,
    this.fontSize = 20,
    this.color,
  });

  final int amount;
  final String currency;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return Text(
      '$currency $buffer',
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.accent,
      ),
    );
  }
}

// ─── Live Dot ─────────────────────────────────────────────────────────────────

class LiveDot extends StatefulWidget {
  const LiveDot({super.key});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

class SkeletonBox extends StatefulWidget {
  const SkeletonBox(
      {super.key, required this.width, required this.height, this.radius = 8});

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Gate Card ───────────────────────────────────────────────────

class SubscriptionGateCard extends StatelessWidget {
  const SubscriptionGateCard({
    super.key,
    required this.requiredPlan,
    required this.reason,
    required this.onUpgrade,
  });

  final String requiredPlan;
  final String reason;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 32, color: AppColors.purple),
            const SizedBox(height: 12),
            Text(
              'Subscription required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onUpgrade,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              child: Text('Upgrade to $requiredPlan'),
            ),
          ],
        ),
      ),
    );
  }
}
