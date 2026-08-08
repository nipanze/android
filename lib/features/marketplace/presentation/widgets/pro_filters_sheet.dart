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
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/country_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/marketplace_cubit.dart';

// ── Value domain ─────────────────────────────────────────────────────────────

class _EmploymentOption {
  const _EmploymentOption(this.value, this.labelKey);
  final String value;
  final String labelKey;
}

const _kEmploymentOptions = [
  _EmploymentOption('government_employee', 'empGovEmployee'),
  _EmploymentOption('employed', 'empEmployedPrivate'),
  _EmploymentOption('self_employed', 'empSelfEmployed'),
  _EmploymentOption('small_business_owner', 'empSmallBusinessOwner'),
  _EmploymentOption('business_owner', 'empBusinessOwner'),
  _EmploymentOption('student', 'empStudent'),
  _EmploymentOption('other', 'empOther'),
];

class _IncomeBracketOption {
  const _IncomeBracketOption(this.value, this.labelKey);
  final String value;
  final String labelKey;
}

const _kIncomeBracketOptions = [
  _IncomeBracketOption('under_2m', 'incomeUnder2m'),
  _IncomeBracketOption('2m_5m', 'income2m5m'),
  _IncomeBracketOption('5m_10m', 'income5m10m'),
  _IncomeBracketOption('over_10m', 'incomeOver10m'),
];

/// Resolves a labelKey to a localized string.
String _resolveLabel(
  AppLocalizations? l10n,
  String key, {
  String currency = 'UGX',
}) {
  switch (key) {
    case 'empGovEmployee':
      return l10n?.empGovEmployee ?? 'Government employee';
    case 'empEmployedPrivate':
      return l10n?.empEmployedPrivate ?? 'Employed (private)';
    case 'empSelfEmployed':
      return l10n?.empSelfEmployed ?? 'Self-employed';
    case 'empSmallBusinessOwner':
      return l10n?.empSmallBusinessOwner ?? 'Small business owner';
    case 'empBusinessOwner':
      return l10n?.empBusinessOwner ?? 'Business owner';
    case 'empStudent':
      return l10n?.empStudent ?? 'Student';
    case 'empOther':
      return l10n?.empOther ?? 'Other';
    case 'incomeUnder2m':
      return (l10n?.incomeUnder2m ?? 'Under 2M UGX / month')
          .replaceAll('UGX', currency);
    case 'income2m5m':
      return (l10n?.income2m5m ?? '2M – 5M UGX / month')
          .replaceAll('UGX', currency);
    case 'income5m10m':
      return (l10n?.income5m10m ?? '5M – 10M UGX / month')
          .replaceAll('UGX', currency);
    case 'incomeOver10m':
      return (l10n?.incomeOver10m ?? 'Over 10M UGX / month')
          .replaceAll('UGX', currency);
    default:
      return key;
  }
}

String? _fnIncomeBracket(int? monthlyIncomeUgx) {
  if (monthlyIncomeUgx == null) return null;
  if (monthlyIncomeUgx < 2000000) return 'under_2m';
  if (monthlyIncomeUgx < 5000000) return '2m_5m';
  if (monthlyIncomeUgx < 10000000) return '5m_10m';
  return 'over_10m';
}

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
  String _currencyCode = EastAfricaCountries.defaultCountry.currency;

  @override
  void initState() {
    super.initState();
    final criteria = _currentCriteria(context);
    _selectedEmployment = Set.from(criteria.employmentTypes);
    _selectedIncome = Set.from(criteria.incomeBrackets);
    _suggestedTermsOnly = criteria.suggestedTermsOnly;
    _verifiedOnly = criteria.verifiedOnly;

    if (criteria == const ProFilterCriteria()) {
      _seedFromProfile();
    }
  }

  Future<void> _seedFromProfile() async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      final data = await client
          .from(TableNames.profiles)
          .select(
              'country, employment_type, monthly_income_ugx, preferred_employment_types, preferred_income_bracket, prefers_suggested_terms, prefers_verified_only')
          .eq('id', uid)
          .maybeSingle();

      if (!mounted) return;

      final preferredEmploymentTypes =
          data?['preferred_employment_types'] == null
              ? null
              : List<String>.from(data!['preferred_employment_types'] as List);
      final preferredIncomeBracket =
          data?['preferred_income_bracket'] as String?;
      final prefersSuggestedTerms =
          data?['prefers_suggested_terms'] as bool? ?? false;
      final prefersVerifiedOnly =
          data?['prefers_verified_only'] as bool? ?? false;
      final currencyCode =
          EastAfricaCountries.findByCode(data?['country'] as String?).currency;

      final employmentTypes = preferredEmploymentTypes ??
          (data?['employment_type'] == null
              ? null
              : [data!['employment_type'] as String]);
      final incomeBracket = preferredIncomeBracket ??
          _fnIncomeBracket(
            (data?['monthly_income_ugx'] as num?)?.toInt(),
          );

      setState(() {
        _currencyCode = currencyCode;
        if (employmentTypes != null ||
            incomeBracket != null ||
            prefersSuggestedTerms ||
            prefersVerifiedOnly) {
          if (employmentTypes != null) {
            _selectedEmployment = employmentTypes.toSet();
          }
          if (incomeBracket != null) {
            _selectedIncome = {incomeBracket};
          }
          _suggestedTermsOnly = prefersSuggestedTerms;
          _verifiedOnly = prefersVerifiedOnly;
        }
      });
    } catch (_) {
      // Silently ignore — user simply keeps an empty selection.
    }
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
    final l10n = AppLocalizations.of(context);
    final currencyCode = _currencyCode;

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
                            l10n?.advancedFilters ?? 'Advanced Filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n?.advancedFiltersBadge ??
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
                        child: Text(
                          l10n?.filterReset ?? 'Reset',
                          style: const TextStyle(
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
                      label: l10n?.filterEmploymentType ?? 'Employment type',
                      subtitle: l10n?.filterEmploymentSubtitle ??
                          "Filter by the borrower's declared employment",
                      textColor: text2,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kEmploymentOptions.map((opt) {
                        final selected =
                            _selectedEmployment.contains(opt.value);
                        return _FilterChip(
                          label: _resolveLabel(
                            l10n,
                            opt.labelKey,
                            currency: currencyCode,
                          ),
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
                      label: l10n?.filterIncomeRange ?? 'Monthly income range',
                      subtitle: l10n?.filterIncomeSubtitle ??
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
                          label: _resolveLabel(
                            l10n,
                            opt.labelKey,
                            currency: currencyCode,
                          ),
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
                      label: l10n?.filterQualitySignals ??
                          'Listing quality signals',
                      textColor: text2,
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.accent,
                      title: l10n?.filterHasSuggestedTerms ??
                          'Has suggested terms',
                      subtitle: l10n?.filterHasSuggestedTermsSubtitle ??
                          'Only Pro-posted listings that carry a locked interest rate, late fee, and repayment schedule',
                      value: _suggestedTermsOnly,
                      onChanged: (v) => setState(() => _suggestedTermsOnly = v),
                      border: border,
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.verified_outlined,
                      iconColor: AppColors.success,
                      title:
                          l10n?.filterVerifiedBorrower ?? 'Verified borrower',
                      subtitle: l10n?.filterVerifiedBorrowerSubtitle ??
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
                              l10n?.filterPrivacyNote ??
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
                          child: Text(
                            l10n?.filterClear ?? 'Clear',
                            style: const TextStyle(fontSize: 13),
                          ),
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
                          _anyActive
                              ? (l10n?.filterApply ?? 'Apply filters')
                              : (l10n?.filterDone ?? 'Done'),
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
