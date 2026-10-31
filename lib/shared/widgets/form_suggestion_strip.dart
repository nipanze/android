import 'package:flutter/material.dart';

class FormSuggestionStrip extends StatelessWidget {
  const FormSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.label = 'Suggestions',
    this.selectedValue,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final String label;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final values = suggestions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (values.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map((value) {
                  final selected = value == selectedValue;
                  return Material(
                      color: selected
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => onSelected(value),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 8),
                          child: Text(value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                              )),
                        ),
                      ),
                    );
                })
                .toList(),
          ),
        ],
      ),
    );
  }
}
