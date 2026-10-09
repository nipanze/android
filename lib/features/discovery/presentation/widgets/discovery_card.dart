import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
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
  });

  final String country;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoveryCubit(getIt<DiscoveryRepository>())
        ..loadCard(country: country),
      child: _DiscoveryCardView(compact: compact),
    );
  }
}

class _DiscoveryCardView extends StatelessWidget {
  const _DiscoveryCardView({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      builder: (context, state) {
        if (state is DiscoveryLoading) {
          return const SkeletonBox(height: 116, width: double.infinity);
        }
        if (state is! DiscoveryCardLoaded || state.template == null) {
          return const SizedBox.shrink();
        }

        final template = state.template!;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;
        final muted = isDark ? AppColors.text3Dark : AppColors.text3Light;

        return Container(
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
                          template.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          template.question,
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
                    tooltip: 'Discovery options',
                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                    onSelected: (value) {
                      final cubit = context.read<DiscoveryCubit>();
                      if (value == 'dismiss') {
                        unawaited(cubit.dismissTemplate(template.id));
                      } else if (value == 'mute') {
                        unawaited(cubit.muteTemplate(template.id));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'dismiss',
                        child: Text('Hide this question'),
                      ),
                      PopupMenuItem(
                        value: 'mute',
                        child: Text('Show fewer like this'),
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
                  for (final option in template.options)
                    _AnswerButton(
                      option: option,
                      onPressed: () => _handleAnswer(
                        context,
                        template,
                        option,
                      ),
                    ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          unawaited(context.read<DiscoveryCubit>().skipTemplate(
                                template.id,
                              )),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Skip'),
                    ),
                    const Spacer(),
                    if (template.deepLink != null)
                      TextButton.icon(
                        onPressed: () => context.go(template.deepLink!),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(template.ctaLabel ?? 'Discover'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAnswer(
    BuildContext context,
    DiscoveryQuestionTemplate template,
    DiscoveryAnswerOption option,
  ) async {
    final answer = {'value': option.value, 'label': option.label};
    if (!option.savePlan) {
      await context.read<DiscoveryCubit>().answerTemplate(
            templateId: template.id,
            answer: answer,
          );
      return;
    }

    final draft = await showModalBottomSheet<DiscoveryPlanDraft>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PlanDetailsSheet(
        template: template,
        option: option,
      ),
    );
    if (draft == null || !context.mounted) return;

    await context.read<DiscoveryCubit>().createPlan(draft);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Plan saved privately.')),
      );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.onPressed,
  });

  final DiscoveryAnswerOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(option.label),
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
