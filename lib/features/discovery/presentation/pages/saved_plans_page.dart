import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/discovery_repository.dart';
import '../../domain/models/user_discovery_plan.dart';
import '../cubit/discovery_cubit.dart';

class SavedPlansPage extends StatelessWidget {
  const SavedPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoveryCubit(getIt<DiscoveryRepository>())..loadPlans(),
      child: const _SavedPlansView(),
    );
  }
}

class _SavedPlansView extends StatelessWidget {
  const _SavedPlansView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans & interests')),
      body: SafeArea(
        child: BlocConsumer<DiscoveryCubit, DiscoveryState>(
          listener: (context, state) {
            if (state is DiscoveryError) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is DiscoveryLoading || state is DiscoveryInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DiscoveryError) {
              return ErrorState(
                message: state.message,
                onRetry: () => context.read<DiscoveryCubit>().loadPlans(),
              );
            }
            final plans =
                state is DiscoveryPlansLoaded ? state.plans : const [];
            if (plans.isEmpty) {
              return const EmptyState(
                icon: Icons.event_note_outlined,
                title: 'No saved plans yet',
                subtitle:
                    'Private plans and interests you save from discovery questions will appear here.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DiscoveryCubit>().loadPlans(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _PlanTile(plan: plans[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final UserDiscoveryPlan plan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.text3Dark : AppColors.text3Light;
    final icon = switch (plan.planType) {
      'travel' => Icons.flight_takeoff_outlined,
      'education_career' => Icons.school_outlined,
      'business' => Icons.business_center_outlined,
      'financial' => Icons.account_balance_wallet_outlined,
      _ => Icons.interests_outlined,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Plan actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditSheet(context);
                    } else if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              plan.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(label: _planTypeLabel(plan.planType)),
                if (plan.reminderPreference != 'none')
                  const _MetaChip(label: 'Reminder set'),
                _MetaChip(
                  label:
                      'Updated ${DateFormat.MMMd().format(plan.updatedAt.toLocal())}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_PlanEditResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _EditPlanSheet(plan: plan),
    );
    if (result == null || !context.mounted) return;
    await context.read<DiscoveryCubit>().updatePlan(
          plan.id,
          title: result.title,
          destination: result.destination,
          preferredLocation: result.preferredLocation,
          expectedDate: result.expectedDate,
          timeframe: result.timeframe,
          reminderPreference: result.reminderPreference,
        );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete plan?'),
        content: const Text(
            'This removes the private saved plan from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DiscoveryCubit>().deletePlan(plan.id);
    }
  }

  String _planTypeLabel(String value) => switch (value) {
        'travel' => 'Travel',
        'education_career' => 'Education & career',
        'business' => 'Business',
        'financial' => 'Financial',
        _ => 'General',
      };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditPlanSheet extends StatefulWidget {
  const _EditPlanSheet({required this.plan});

  final UserDiscoveryPlan plan;

  @override
  State<_EditPlanSheet> createState() => _EditPlanSheetState();
}

class _EditPlanSheetState extends State<_EditPlanSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _locationController;
  late final TextEditingController _timeframeController;
  DateTime? _expectedDate;
  late String _reminder;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan.title);
    _destinationController =
        TextEditingController(text: widget.plan.destination ?? '');
    _locationController =
        TextEditingController(text: widget.plan.preferredLocation ?? '');
    _timeframeController =
        TextEditingController(text: widget.plan.timeframe ?? '');
    _expectedDate = widget.plan.expectedDate;
    _reminder = widget.plan.reminderPreference;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _locationController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit plan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Plan name'),
            ),
            const SizedBox(height: 10),
            if (widget.plan.planType == 'travel') ...[
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _locationController,
              decoration:
                  const InputDecoration(labelText: 'Preferred location'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeframeController,
              decoration:
                  const InputDecoration(labelText: 'Approximate timeframe'),
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
                        : () => Navigator.of(context).pop(_result()),
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
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  _PlanEditResult _result() => _PlanEditResult(
        title: _titleController.text.trim(),
        destination: _destinationController.text,
        preferredLocation: _locationController.text,
        expectedDate: _expectedDate,
        timeframe: _timeframeController.text,
        reminderPreference: _reminder,
      );

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PlanEditResult {
  const _PlanEditResult({
    required this.title,
    this.destination,
    this.preferredLocation,
    this.expectedDate,
    this.timeframe,
    this.reminderPreference = 'none',
  });

  final String title;
  final String? destination;
  final String? preferredLocation;
  final DateTime? expectedDate;
  final String? timeframe;
  final String reminderPreference;
}
