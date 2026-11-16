import 'package:flutter/material.dart';

class FormSuggestionStrip extends StatelessWidget {
  const FormSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.label = 'Suggestions',
    this.selectedValue,
    this.topPadding = 10,
    this.moreLabel = 'More',
    this.maxVisibleChoices,
    this.moreSubtitle = 'Select an option to continue.',
    this.moreDescriptions = const {},
    this.pinnedChoices = const {},
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final String label;
  final String? selectedValue;
  final double topPadding;
  final String moreLabel;
  final int? maxVisibleChoices;
  final String moreSubtitle;
  final Map<String, String> moreDescriptions;
  final Set<String> pinnedChoices;

  IconData _iconForOption(String value) {
    final text = value.toLowerCase();
    if (text.contains('catering') || text.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (text.contains('decor') || text.contains('flor')) {
      return Icons.celebration_rounded;
    }
    if (text.contains('photograph') || text.contains('photo')) {
      return Icons.photo_camera_rounded;
    }
    if (text.contains('dj') || text.contains('entertainment')) {
      return Icons.music_note_rounded;
    }
    if (text.contains('venue')) return Icons.location_city_rounded;
    if (text.contains('event planning') || text.contains('planner')) {
      return Icons.event_available_rounded;
    }
    if (text.contains('sound') ||
        text.contains('stage') ||
        text.contains('lighting')) {
      return Icons.speaker_rounded;
    }
    if (text.contains('event equipment')) return Icons.event_rounded;
    if (text.contains('makeup') || text.contains('nail')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (text.contains('hair') || text.contains('styling')) {
      return Icons.content_cut_rounded;
    }
    if (text.contains('tailor') ||
        text.contains('fashion') ||
        text.contains('attire')) {
      return Icons.checkroom_rounded;
    }
    if (text.contains('cleaning') || text.contains('household')) {
      return Icons.cleaning_services_rounded;
    }
    if (text.contains('childcare')) return Icons.child_care_rounded;
    if (text.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (text.contains('home cooking') || text.contains('cook')) {
      return Icons.restaurant_rounded;
    }
    if (text.contains('dental') ||
        text.contains('medical') ||
        text.contains('lab')) {
      return Icons.medical_services_rounded;
    }
    if (text.contains('physiotherapy') || text.contains('home nursing')) {
      return Icons.health_and_safety_rounded;
    }
    if (text.contains('sacco') ||
        text.contains('savings') ||
        text.contains('loan') ||
        text.contains('financing')) {
      return Icons.account_balance_rounded;
    }
    if (text.contains('currency exchange'))
      return Icons.currency_exchange_rounded;
    if (text.contains('financial planning')) return Icons.calculate_rounded;
    if (text.contains('traditional attire')) return Icons.checkroom_rounded;
    if (text.contains('cultural') || text.contains('ceremony host')) {
      return Icons.diversity_3_rounded;
    }
    if (text.contains('house move') || text.contains('business deliveries')) {
      return Icons.local_shipping_rounded;
    }
    if (text.contains('podcast') || text.contains('interview')) {
      return Icons.mic_rounded;
    }
    if (text.contains('music video') || text.contains('live session')) {
      return Icons.video_camera_back_rounded;
    }
    if (text.contains('short film') || text.contains('product video')) {
      return Icons.movie_creation_rounded;
    }
    if (text.contains('event coverage'))
      return Icons.video_camera_front_rounded;
    if (text.contains('hajj') ||
        text.contains('umrah') ||
        text.contains('holiday') ||
        text.contains('trip') ||
        text.contains('abroad')) {
      return Icons.flight_takeoff_rounded;
    }
    if (text.contains('water') ||
        text.contains('pump') ||
        text.contains('irrigation')) {
      return Icons.water_drop_rounded;
    }
    if (text.contains('solar') ||
        text.contains('power') ||
        text.contains('energy')) {
      return Icons.bolt_rounded;
    }
    if (text.contains('visa') ||
        text.contains('travel') ||
        text.contains('flight') ||
        text.contains('pilgrim')) {
      return Icons.flight_takeoff_rounded;
    }
    if (text.contains('legal') ||
        text.contains('contract') ||
        text.contains('document')) {
      return Icons.gavel_rounded;
    }
    if (text.contains('social media') || text.contains('influencer')) {
      return Icons.share_rounded;
    }
    if (text.contains('brand')) return Icons.palette_rounded;
    if (text.contains('public relations') || text.contains('press')) {
      return Icons.record_voice_over_rounded;
    }
    if (text.contains('marketing') ||
        text.contains('advertising') ||
        text.contains('campaign') ||
        text.contains('promotion') ||
        text.contains('content')) {
      return Icons.campaign_rounded;
    }
    if (text.contains('part') || text.contains('component')) {
      return Icons.settings_rounded;
    }
    if (text.contains('safety')) return Icons.health_and_safety_rounded;
    if (text.contains('building supply') ||
        text.contains('roof') ||
        text.contains('pipe') ||
        text.contains('plumb') ||
        text.contains('electrical') ||
        text.contains('construction') ||
        text.contains('painting')) {
      return Icons.construction_rounded;
    }
    if (text.contains('seed') ||
        text.contains('fertilizer') ||
        text.contains('livestock') ||
        text.contains('irrigation') ||
        text.contains('harvester') ||
        text.contains('crop') ||
        text.contains('tractor') ||
        text.contains('farm')) {
      return Icons.grass_rounded;
    }
    if (text.contains('exam')) return Icons.quiz_rounded;
    if (text.contains('language')) return Icons.translate_rounded;
    if (text.contains('course')) return Icons.menu_book_rounded;
    if (text.contains('tutor') ||
        text.contains('teacher') ||
        text.contains('lecturer') ||
        text.contains('instructor')) {
      return Icons.school_rounded;
    }
    if (text.contains('internship') ||
        text.contains('career') ||
        text.contains('mentorship')) {
      return Icons.work_outline_rounded;
    }
    if (text.contains('vocational') || text.contains('skill')) {
      return Icons.build_rounded;
    }
    if (text.contains('website') ||
        text.contains('app') ||
        text.contains('software') ||
        text.contains('digital') ||
        text.contains('technology')) {
      return Icons.devices_rounded;
    }
    if (text.contains('business') ||
        text.contains('account') ||
        text.contains('tax')) {
      return Icons.business_center_rounded;
    }
    if (text.contains('event') || text.contains('catering')) {
      return Icons.event_rounded;
    }
    if (text.contains('delivery') || text.contains('transport')) {
      return Icons.local_shipping_rounded;
    }
    if (text.contains('product') || text.contains('equipment')) {
      return Icons.shopping_bag_rounded;
    }
    if (text.contains('photo') || text.contains('photography')) {
      return Icons.photo_camera_rounded;
    }
    if (text.contains('medical') || text.contains('health')) {
      return Icons.medical_services_rounded;
    }
    if (text.contains('family')) return Icons.family_restroom_rounded;
    if (text.contains('study') ||
        text.contains('school') ||
        text.contains('tutor')) {
      return Icons.school_rounded;
    }
    if (text.contains('farm') ||
        text.contains('crop') ||
        text.contains('tractor')) {
      return Icons.grass_rounded;
    }
    if (text.contains('solar') ||
        text.contains('repair') ||
        text.contains('install')) {
      return Icons.handyman_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Future<void> _showMore(
    BuildContext context,
    List<String> values,
    int visibleLimit,
  ) async {
    final hiddenValues = values.skip(visibleLimit).toList();
    if (hiddenValues.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.isNotEmpty ? label : moreLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                moreSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(sheetContext)
                              .closeButtonTooltip,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: hiddenValues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final value = hiddenValues[index];
                          final selected = value == selectedValue;
                          return Material(
                            color: selected
                                ? colors.primaryContainer
                                : colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                onSelected(value);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? colors.primary
                                            : colors.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        _iconForOption(value),
                                        color: selected
                                            ? colors.onPrimary
                                            : colors.primary,
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            value,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            moreDescriptions[value] ??
                                                'Choose this to start your request.',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.arrow_forward_ios_rounded,
                                      size: selected ? 20 : 14,
                                      color: selected
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = suggestions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final pinnedValues =
        values.where((value) => pinnedChoices.contains(value)).toList();
    final choiceValues =
        values.where((value) => !pinnedChoices.contains(value)).toList();
    // Keep a choice made from the More sheet in the visible chip row. The
    // displaced option remains available from More.
    final selected = selectedValue;
    if (selected != null && choiceValues.contains(selected)) {
      choiceValues
        ..remove(selected)
        ..insert(0, selected);
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget choiceChip(String value) {
      final selected = value == selectedValue;
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Material(
          color: selected
              ? colors.primary
              : colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final chips = LayoutBuilder(
      builder: (context, constraints) {
        final choiceLimit = maxVisibleChoices;
        if (choiceLimit == null) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: values.map(choiceChip).toList()),
          );
        }

        double chipWidth(String value) {
          final painter = TextPainter(
            text: TextSpan(text: value, style: theme.textTheme.bodySmall),
            textDirection: Directionality.of(context),
            maxLines: 1,
          )..layout();
          return painter.width + 22 + 7;
        }

        final morePainter = TextPainter(
          text: TextSpan(text: moreLabel, style: theme.textTheme.bodySmall),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final moreWidth = morePainter.width + 22;
        final pinnedWidth = pinnedValues.fold<double>(
          0,
          (width, value) => width + chipWidth(value),
        );
        final availableWidth = constraints.maxWidth;
        final limit = choiceLimit < choiceValues.length
            ? choiceLimit
            : choiceValues.length;
        if (choiceValues.length <= choiceLimit) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: values.map(choiceChip).toList()),
          );
        }
        var visibleLimit = 0;
        var visibleWidth = 0.0;
        for (var index = 0; index < limit; index++) {
          final nextWidth = chipWidth(choiceValues[index]);
          final hasMoreAfter = index < choiceValues.length - 1;
          final requiredWidth = visibleWidth +
              nextWidth +
              pinnedWidth +
              (hasMoreAfter ? moreWidth : 0);
          // Leave a small safety margin for font shaping and fractional
          // layout rounding so the pinned More chip never overflows the row.
          if (requiredWidth + 12 > availableWidth) break;
          visibleWidth += nextWidth;
          visibleLimit++;
        }

        final hiddenValues = choiceValues.skip(visibleLimit).toList();
        final hasSelectedHiddenValue =
            selectedValue != null && hiddenValues.contains(selectedValue);
        final visibleChips = [
          ...choiceValues.take(visibleLimit).map(choiceChip),
          ...pinnedValues.map(choiceChip),
        ];
        if (hiddenValues.isEmpty) {
          return Row(children: visibleChips);
        }

        final moreChip = Material(
          color: hasSelectedHiddenValue
              ? colors.primary
              : colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _showMore(context, choiceValues, visibleLimit),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Text(
                moreLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: hasSelectedHiddenValue
                      ? colors.onPrimary
                      : colors.onSurface,
                ),
              ),
            ),
          ),
        );

        return Row(
          children: [
            ...visibleChips,
            moreChip,
          ],
        );
      },
    );
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
          chips,
        ],
      ),
    );
  }
}
