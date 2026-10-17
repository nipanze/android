import 'package:flutter/material.dart';

import '../../domain/entities/provider_category_type.dart';

class ProviderTypeCard extends StatelessWidget {
  const ProviderTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ProviderCategoryType type;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: title,
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
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
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
