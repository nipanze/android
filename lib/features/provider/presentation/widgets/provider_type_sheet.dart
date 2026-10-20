import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/provider_category_type.dart';

class ProviderTypeCard extends StatelessWidget {
  const ProviderTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.isCurrent = false,
    this.currentLabel,
    super.key,
  });

  final ProviderCategoryType type;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool isCurrent;
  final String? currentLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label:
          isCurrent && currentLabel != null ? '$title, $currentLabel' : title,
      hint: description,
      button: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: .08)
                  : colors.surface,
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                  type == ProviderCategoryType.individual
                      ? Icons.person_outline
                      : Icons.business_outlined,
                  color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Row(children: [
                      Expanded(
                        child: Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (isCurrent && currentLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: .12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: .35),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(currentLabel!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.outline),
            ]),
          ),
        ),
      ),
    );
  }
}
