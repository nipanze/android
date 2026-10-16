import 'package:flutter/material.dart';

class FormSuggestionStrip extends StatelessWidget {
  const FormSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.label = 'Suggestions',
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final String label;

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
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SizedBox(
              height: 24,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final value = values[index];
                  return Tooltip(
                    message: value,
                    child: Material(
                      color: colors.onSurface.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(5),
                      child: InkWell(
                        onTap: () => onSelected(value),
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          child: Text(
                            value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: colors.onSurface.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
