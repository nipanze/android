import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class ListingExpiryIndicator extends StatefulWidget {
  const ListingExpiryIndicator({
    super.key,
    required this.listedAt,
    required this.expiresAt,
  });

  final DateTime listedAt;
  final DateTime? expiresAt;

  @override
  State<ListingExpiryIndicator> createState() => _ListingExpiryIndicatorState();
}

class _ListingExpiryIndicatorState extends State<ListingExpiryIndicator> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ListingExpiryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.listedAt != widget.listedAt) {
      _now = DateTime.now();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.expiresAt == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) return const SizedBox.shrink();

    final total = expiresAt.difference(widget.listedAt);
    final remaining = expiresAt.difference(_now);
    if (total.isNegative && remaining > Duration.zero) {
      return const SizedBox.shrink();
    }

    final progress = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds.clamp(0, total.inMilliseconds) /
                total.inMilliseconds)
            .toDouble();
    final color = remaining.isNegative
        ? AppColors.danger
        : remaining.inHours < 6
            ? AppColors.danger
            : remaining.inHours < 24
                ? AppColors.warning
                : AppColors.accent;
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.listingExpiryTooltip,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _ListingExpirySheet(expiresAt: expiresAt),
      ),
      icon: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingExpirySheet extends StatefulWidget {
  const _ListingExpirySheet({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_ListingExpirySheet> createState() => _ListingExpirySheetState();
}

class _ListingExpirySheetState extends State<_ListingExpirySheet> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _remainingLabel(AppLocalizations l10n, Duration remaining) {
    if (remaining.isNegative || remaining == Duration.zero) {
      return l10n.expired;
    }
    if (remaining.inDays > 0) {
      return l10n.listingRemainingDaysHours(
        remaining.inDays,
        remaining.inHours % 24,
      );
    }
    if (remaining.inHours > 0) {
      return l10n.listingRemainingHoursMinutes(
        remaining.inHours,
        remaining.inMinutes % 60,
      );
    }
    if (remaining.inMinutes > 0) {
      return l10n.listingRemainingMinutes(remaining.inMinutes);
    }
    return l10n.listingRemainingSeconds(remaining.inSeconds.clamp(1, 59));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.expiresAt.difference(_now);
    final expired = remaining.isNegative || remaining == Duration.zero;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.listingExpiryTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _remainingLabel(l10n, remaining),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: expired ? AppColors.danger : AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
