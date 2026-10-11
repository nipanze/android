import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/discovery_repository.dart';
import '../../domain/models/discovery_question_template.dart';
import '../../domain/models/user_discovery_plan.dart';
import '../cubit/discovery_cubit.dart';

class DiscoveryCard extends StatelessWidget {
  const DiscoveryCard({
    super.key,
    required this.country,
    this.compact = false,
    this.spacingAfter = false,
    this.cubit,
  });

  final String country;
  final bool compact;
  final bool spacingAfter;
  final DiscoveryCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final sharedCubit = cubit ??
        (DiscoveryCubit(getIt<DiscoveryRepository>())
          ..loadCard(country: country));

    return BlocProvider.value(
      value: sharedCubit,
      child: _DiscoveryCardView(
        compact: compact,
        spacingAfter: spacingAfter,
      ),
    );
  }
}

class _DiscoveryCardView extends StatefulWidget {
  const _DiscoveryCardView({
    required this.compact,
    required this.spacingAfter,
  });

  final bool compact;
  final bool spacingAfter;

  @override
  State<_DiscoveryCardView> createState() => _DiscoveryCardViewState();
}

class _DiscoveryCardViewState extends State<_DiscoveryCardView> {
  final _selectedCategorySlugs = <String>{};
  final _selectedValues = <String>{};
  String? _loadedTemplateId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      builder: (context, state) {
        if (state is DiscoveryLoading) {
          return _withSpacing(
            const SkeletonBox(height: 116, width: double.infinity),
          );
        }
        if (state is! DiscoveryCardLoaded || state.template == null) {
          return const SizedBox.shrink();
        }

        final template = state.template!;
        _syncSavedSelections(template);
        final l10n = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;
        final muted = isDark ? AppColors.text3Dark : AppColors.text3Light;
        final options = template.options
            .where((option) => option.value.toLowerCase() != 'skip')
            .toList();

        return _withSpacing(Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _localizedTitle(l10n, template),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _localizedQuestion(l10n, template),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: muted,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: l10n.discoveryOptionsTooltip,
                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                    onSelected: (value) {
                      final cubit = context.read<DiscoveryCubit>();
                      if (value == 'dismiss') {
                        unawaited(_performCardAction(
                          () => cubit.dismissTemplate(template.id),
                        ));
                      } else if (value == 'mute') {
                        unawaited(_performCardAction(
                          () => cubit.muteTemplate(template.id),
                        ));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'dismiss',
                        child: Text(l10n.discoveryHideQuestion),
                      ),
                      PopupMenuItem(
                        value: 'mute',
                        child: Text(l10n.discoveryFewerQuestions),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    _AnswerButton(
                      option: option,
                      label: _localizedOption(l10n, option),
                      selected: _selectedValues.contains(option.value),
                      onPressed: () => _toggleInterest(template, option),
                    ),
                ],
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => unawaited(_performCardAction(
                        () => context
                            .read<DiscoveryCubit>()
                            .skipTemplate(template.id),
                      )),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(l10n.discoverySkip),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _explore(template),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(_localizedCta(l10n, template)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ));
      },
    );
  }

  Widget _withSpacing(Widget child) {
    if (!widget.spacingAfter) return child;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }

  void _syncSavedSelections(DiscoveryQuestionTemplate template) {
    if (_loadedTemplateId == template.id) return;
    _loadedTemplateId = template.id;
    _selectedCategorySlugs.clear();
    _selectedValues.clear();

    unawaited(() async {
      try {
        final saved =
            await getIt<DiscoveryRepository>().getSavedInterestCategories();
        if (!mounted || _loadedTemplateId != template.id) return;
        setState(() {
          for (final option in template.options) {
            final categorySlug = _categorySlugFor(template, option);
            if (categorySlug != null && saved.contains(categorySlug)) {
              _selectedCategorySlugs.add(categorySlug);
              _selectedValues.add(option.value);
            }
          }
        });
      } catch (error) {
        if (mounted && _loadedTemplateId == template.id) _showError(error);
      }
    }());
  }

  Future<void> _toggleInterest(
    DiscoveryQuestionTemplate template,
    DiscoveryAnswerOption option,
  ) async {
    final categorySlug = _categorySlugFor(template, option);
    if (categorySlug == null) {
      await _performCardAction(
        () => context.read<DiscoveryCubit>().answerTemplate(
          templateId: template.id,
          answer: {'value': option.value, 'label': option.label},
        ),
      );
      return;
    }

    final wasSelected = _selectedValues.contains(option.value);
    setState(() {
      if (wasSelected) {
        _selectedValues.remove(option.value);
        _selectedCategorySlugs.remove(categorySlug);
      } else {
        if (template.answerType != 'multi_select') {
          _selectedValues.clear();
          _selectedCategorySlugs.clear();
        }
        _selectedValues.add(option.value);
        _selectedCategorySlugs.add(categorySlug);
      }
    });

    final repository = getIt<DiscoveryRepository>();
    try {
      if (wasSelected) {
        await repository.removeInterestCategories({categorySlug});
      } else {
        await repository.saveInterestCategories({categorySlug});
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasSelected) {
          _selectedValues.add(option.value);
          _selectedCategorySlugs.add(categorySlug);
        } else {
          _selectedValues.remove(option.value);
          _selectedCategorySlugs.remove(categorySlug);
        }
      });
      _showError(error);
    }
  }

  Future<void> _explore(DiscoveryQuestionTemplate template) async {
    final discoveryCubit = context.read<DiscoveryCubit>();
    final selectedOptions = template.options
        .where((option) => _selectedValues.contains(option.value))
        .toList();
    try {
      if (selectedOptions.isNotEmpty) {
        await getIt<DiscoveryRepository>().saveInterestCategories(
          _selectedCategorySlugs,
        );
        if (_selectedCategorySlugs.isEmpty) {
          await discoveryCubit.answerTemplate(
            templateId: template.id,
            answer: {
              'values': selectedOptions.map((option) => option.value).toList(),
              'labels': selectedOptions.map((option) => option.label).toList(),
              'category_slugs': _selectedCategorySlugs.toList(),
            },
          );
        }
      }
    } catch (error) {
      if (mounted) _showError(error);
      return;
    }

    if (!mounted) return;
    final interests = _selectedCategorySlugs.toList()..sort();
    final uri = Uri(
      path: '/marketplace',
      queryParameters: {
        'module': 'needs',
        if (interests.isNotEmpty) 'interests': interests.join(','),
      },
    );
    context.go(uri.toString());
  }

  Future<void> _performCardAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
  }

  String? _categorySlugFor(
    DiscoveryQuestionTemplate template,
    DiscoveryAnswerOption option,
  ) {
    if (option.categorySlug != null && option.categorySlug!.isNotEmpty) {
      return option.categorySlug;
    }
    return switch (option.value) {
      'equipment' => 'machinery_equipment',
      'logistics' => 'transport_logistics',
      'services' => 'professional_services',
      'procurement' => 'specialized_products',
      _ => option.savePlan ? template.needCategorySlug : null,
    };
  }

  String _localizedTitle(
    AppLocalizations l10n,
    DiscoveryQuestionTemplate template,
  ) =>
      switch (template.slug) {
        'business_equipment_basic' => l10n.discoveryBusinessTitle,
        'travel_planning_basic' ||
        'internship_interest_basic' ||
        'financial_interest_basic' =>
          l10n.discoveryQuestionTitle,
        _ => template.title,
      };

  String _localizedQuestion(
    AppLocalizations l10n,
    DiscoveryQuestionTemplate template,
  ) =>
      switch (template.slug) {
        'business_equipment_basic' => l10n.discoveryBusinessQuestion,
        'travel_planning_basic' => l10n.discoveryTravelQuestion,
        'internship_interest_basic' => l10n.discoveryEducationQuestion,
        'financial_interest_basic' => l10n.discoveryFinancialQuestion,
        _ => template.question,
      };

  String _localizedCta(
    AppLocalizations l10n,
    DiscoveryQuestionTemplate template,
  ) =>
      switch (template.slug) {
        'business_equipment_basic' => l10n.discoveryBusinessCta,
        'travel_planning_basic' => l10n.discoveryTravelCta,
        'internship_interest_basic' => l10n.discoveryEducationCta,
        'financial_interest_basic' => l10n.discoveryFinancialCta,
        _ => template.ctaLabel ?? l10n.discoveryExploreOpportunities,
      };

  String _localizedOption(
    AppLocalizations l10n,
    DiscoveryAnswerOption option,
  ) =>
      switch (option.value) {
        'equipment' => l10n.discoveryEquipment,
        'logistics' => l10n.discoveryLogistics,
        'services' => l10n.discoveryServices,
        'procurement' => l10n.discoveryProcurement,
        'yes' => l10n.discoveryYes,
        'later' => l10n.discoveryLater,
        'not_now' => l10n.discoveryNotNow,
        'no' => l10n.discoveryNo,
        'loans' => l10n.discoveryLoans,
        'forex' => l10n.discoveryForex,
        'both' => l10n.discoveryBoth,
        _ => option.label,
      };
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final DiscoveryAnswerOption option;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.accent;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.accent : null,
        foregroundColor: foreground,
        side: BorderSide(
          color: selected
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.38),
        ),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class _PlanDetailsSheet extends StatefulWidget {
  const _PlanDetailsSheet({
    required this.template,
    required this.option,
  });

  final DiscoveryQuestionTemplate template;
  final DiscoveryAnswerOption option;

  @override
  State<_PlanDetailsSheet> createState() => _PlanDetailsSheetState();
}

class _PlanDetailsSheetState extends State<_PlanDetailsSheet> {
  late final TextEditingController _titleController;
  final _destinationController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeframeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expectedDate;
  String _reminder = 'none';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _defaultTitle());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _locationController.dispose();
    _timeframeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final planType = widget.template.planType;
    final showDestination = planType == 'travel';

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make a plan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Plan name'),
            ),
            const SizedBox(height: 10),
            if (showDestination) ...[
              TextField(
                controller: _destinationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g. Dubai, Nairobi, Makkah',
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _locationController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: showDestination
                    ? 'Starting location'
                    : 'Preferred location',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeframeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Approximate timeframe',
                hintText: 'e.g. December, next quarter, soon',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_expectedDate == null
                  ? 'Add expected date'
                  : _formatDate(_expectedDate!)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: planType == 'travel'
                    ? 'Assistance needed'
                    : 'What would be useful?',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _reminder,
              decoration: const InputDecoration(labelText: 'Reminder'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No reminder')),
                DropdownMenuItem(
                  value: 'one_week_before',
                  child: Text('One week before'),
                ),
                DropdownMenuItem(
                  value: 'one_month_before',
                  child: Text('One month before'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _reminder = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _titleController.text.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_draft()),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  DiscoveryPlanDraft _draft() {
    return DiscoveryPlanDraft(
      templateId: widget.template.id,
      category: widget.template.category,
      needCategorySlug: widget.template.needCategorySlug,
      planType: widget.template.planType,
      title: _titleController.text.trim(),
      answers: {
        'selected': widget.option.value,
        'selected_label': widget.option.label,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      },
      destination: _destinationController.text,
      preferredLocation: _locationController.text,
      expectedDate: _expectedDate,
      timeframe: _timeframeController.text,
      reminderPreference: _reminder,
    );
  }

  String _defaultTitle() {
    final type = widget.template.planType;
    return switch (type) {
      'travel' => 'Travel plan',
      'education_career' => 'Career plan',
      'business' => 'Business need',
      'financial' => 'Financial interest',
      _ => 'Saved interest',
    };
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
