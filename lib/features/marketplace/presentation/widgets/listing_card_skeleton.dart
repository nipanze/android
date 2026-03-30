import 'package:flutter/material.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 140, height: 14),
              Spacer(),
              SkeletonBox(width: 60, height: 20, radius: 10),
            ],
          ),
          SizedBox(height: 6),
          SkeletonBox(width: 80, height: 11),
          SizedBox(height: 10),
          SkeletonBox(width: 160, height: 22),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 3, radius: 2),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonBox(width: 90, height: 10),
              Spacer(),
              SkeletonBox(width: 60, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
