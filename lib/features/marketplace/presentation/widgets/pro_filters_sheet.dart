// lib/features/marketplace/presentation/widgets/pro_filters_sheet.dart
//
// The "Advanced Filters" bottom sheet — opened via the Pro filter icon button
// in the marketplace header.  All filter state lives in MarketplaceCubit so
// that re-opens show the previously-selected values.
//
// Gating note: the CALLER (marketplace_page.dart) is responsible for checking
// subscription plan before opening this sheet.  Non-Pro users are shown an
// upgrade modal instead and never reach this widget.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/marketplace_cubit.dart';

// ── Value domain ─────────────────────────────────────────────────────────────

class _EmploymentOption {
  const _EmploymentOption(this.value, this.label);
  final String value;
  final String label;
}

const _kEmploymentOptions = [
  _EmploymentOption('government_employee', 'Government employee'),
  _EmploymentOption('employed', 'Employed (private)'),
  _EmploymentOption('self_employed', 'Self-employed'),
  _EmploymentOption('small_business_owner', 'Small business owner'),
  _EmploymentOption('business_owner', 'Business owner'),
  _EmploymentOption('student', 'Student'),
  _EmploymentOption('other', 'Other'),
];

class _IncomeBracketOption {
  const _IncomeBracketOption(this.value, this.label);
  final String value;
  final String label;
}

const _kIncomeBracketOptions = [
  _IncomeBracketOption('under_2m', 'Under 2M UGX / month'),
  _IncomeBracketOption('2m_5m', '2M – 5M UGX / month'),
  _IncomeBracketOption('5m_10m', '5M – 10M UGX / month'),
  _IncomeBracketOption('over_10m', 'Over 10M UGX / month'),
];

// ── Public entry-point ────────────────────────────────────────────────────────

/// Show the Pro Advanced Filters bottom sheet.
/// [cubit] must be the MarketplaceCubit already provided to the page tree.
Future<void> showProFiltersSheet(
  BuildContext context, {
  required MarketplaceCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _ProFiltersSheet(),
    ),
  );
}

// ── Sheet implementation ──────────────────────────────────────────────────────

class _ProFiltersSheet extends StatefulWidget {
  const _ProFiltersSheet();

  @override
  State<_ProFiltersSheet> createState() => _ProFiltersSheetState();
}

class _ProFiltersSheetState extends State<_ProFiltersSheet> {
  late Set<String> _selectedEmployment;
  late Set<String> _selectedIncome;
  late bool _suggestedTermsOnly;
  late bool _verifiedOnly;

  @override
  void initState() {
    super.initState();
    // Seed from current cubit criteria so re-open shows persisted values.
    final criteria = _currentCriteria(context);
    _selectedEmployment = Set.from(criteria.employmentTypes);
    _selectedIncome = Set.from(criteria.incomeBrackets);
    _suggestedTermsOnly = criteria.suggestedTermsOnly;
    _verifiedOnly = criteria.verifiedOnly;
  }

  ProFilterCriteria _currentCriteria(BuildContext ctx) {
    final state = ctx.read<MarketplaceCubit>().state;
    return state is MarketplaceLoaded
        ? state.proFilterCriteria
        : const ProFilterCriteria();
  }

  void _applyAndClose() {
    context.read<MarketplaceCubit>().applyProFilters(
          ProFilterCriteria(
            employmentTypes: _selectedEmployment.toList(),
            incomeBrackets: _selectedIncome.toList(),
            suggestedTermsOnly: _suggestedTermsOnly,
            verifiedOnly: _verifiedOnly,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearAndClose() {
    context.read<MarketplaceCubit>().clearProFilters();
    Navigator.of(context).pop();
  }

  bool get _anyActive =>
      _selectedEmployment.isNotEmpty ||
      _selectedIncome.isNotEmpty ||
      _suggestedTermsOnly ||
      _verifiedOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.purple,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced Filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Pro · Narrow the marketplace feed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.purple.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_anyActive)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedEmployment.clear();
                          _selectedIncome.clear();
                          _suggestedTermsOnly = false;
                          _verifiedOnly = false;
                        }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                              color: AppColors.danger, fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Employment type
                    _SectionHeader(
                      icon: Icons.work_outline_rounded,
                      label: 'Employment type',
                      subtitle: 'Filter by the borrower\'s declared employment',
                      textColor: text2,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kEmploymentOptions.map((opt) {
                        final selected = _selectedEmployment.contains(opt.value);
                        return _FilterChip(
                          label: opt.label,
                          selected: selected,
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedEmployment.remove(opt.value);
                            } else {
                              _selectedEmployment.add(opt.value);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Income bracket
                    _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      label: 'Monthly income range',
                      subtitle:
                          'Coarse brackets — exact income is never shown',
                      textColor: text2,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kIncomeBracketOptions.map((opt) {
                        final selected = _selectedIncome.contains(opt.value);
                        return _FilterChip(
                          label: opt.label,
                          selected: selected,
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedIncome.remove(opt.value);
                            } else {
                              _selectedIncome.add(opt.value);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Boolean toggles
                    _SectionHeader(
                      icon: Icons.shield_outlined,
                      label: 'Listing quality signals',
                      textColor: text2,
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.accent,
                      title: 'Has suggested terms',
                      subtitle:
                          'Only Pro-posted listings that carry a locked interest rate, late fee, and repayment schedule',
                      value: _suggestedTermsOnly,
                      onChanged: (v) => setState(() => _suggestedTermsOnly = v),
                      border: border,
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.verified_outlined,
                      iconColor: AppColors.success,
                      title: 'Verified borrower',
                      subtitle:
                          'Only requests from KYC-approved account holders',
                      value: _verifiedOnly,
                      onChanged: (v) => setState(() => _verifiedOnly = v),
                      border: border,
                    ),
                    const SizedBox(height: 8),
                    // Privacy note
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Employer names and exact income are never shown. '
                              'Income brackets and employment categories are the '
                              'only signals available, by design.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: text2,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Action row ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    if (_anyActive)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _clearAndClose,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Clear',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    if (_anyActive) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _applyAndClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _anyActive ? 'Apply filters' : 'Done',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.textColor,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.purple),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 11.5, color: textColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.purple
                : AppColors.borderDark.withValues(alpha: 0.5),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.purple : null,
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.border,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withValues(alpha: 0.35),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
