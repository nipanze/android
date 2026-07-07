import 'package:flutter/material.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
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
