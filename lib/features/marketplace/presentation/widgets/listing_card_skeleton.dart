import 'package:flutter/material.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A28)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE1E1DD),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 140, height: 14),
              Spacer(),
              SkeletonBox(width: 48, height: 16, radius: 8),
            ],
          ),
          SizedBox(height: 3),
          SkeletonBox(width: 80, height: 11),
          SizedBox(height: 8),
          SkeletonBox(width: 150, height: 22),
          SizedBox(height: 7),
          SkeletonBox(width: 210, height: 10),
          SizedBox(height: 7),
          SkeletonBox(width: double.infinity, height: 3, radius: 2),
          SizedBox(height: 4),
          Row(
            children: [
              SkeletonBox(width: 70, height: 10),
              Spacer(),
              SkeletonBox(width: 42, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
