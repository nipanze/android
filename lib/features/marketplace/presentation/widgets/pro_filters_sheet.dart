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
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../domain/models/marketplace_item.dart';
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
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
  late bool _institutionMatchOnly;
  MarketplaceModule? _moduleFilter;
  late Set<String> _amountBands;
  late final TextEditingController _locationController;
  late Set<String> _favoriteCurrencies;
  List<String> _favoriteCurrencyOptions = const [];
  bool _favoriteCurrenciesLoading = true;
  late String _needType;
  late String _urgency;
  late bool _hasClearBudget;
  late bool _amongFirst;
  late bool _matchesMyCategories;
  List<String> _locations = EastAfricaCountries.uganda.regions;
  List<String> _myNeedCategorySlugs = const [];
  List<String> _myRoleCapabilitySlugs = const [];
  String _currencyCode = EastAfricaCountries.defaultCountry.currency;

  /// True when the current user is a Pro bank/credit agent with a registered institution.
  /// Only such agents may use the Institution Matches toggle.
  bool _isAgentEligible = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final criteria = _currentCriteria(context);
    _selectedEmployment = Set.from(criteria.employmentTypes);
    _selectedIncome = Set.from(criteria.incomeBrackets);
    _suggestedTermsOnly = criteria.suggestedTermsOnly;
    _verifiedOnly = criteria.verifiedOnly;
    _institutionMatchOnly = criteria.institutionMatchOnly;
    _moduleFilter = criteria.moduleFilter;
    _amountBands = Set.from(criteria.amountBands);
    _locationController = TextEditingController(text: criteria.location);
    _favoriteCurrencies = Set.from(criteria.favoriteCurrencies);
    _needType = const {
      'machinery_equipment',
      'transport_logistics',
      'professional_services',
      'specialized_products',
    }.contains(criteria.needType)
        ? criteria.needType
        : '';
    _urgency =
        const {'Urgent', 'This week', 'Flexible'}.contains(criteria.urgency)
            ? criteria.urgency
            : '';
    _hasClearBudget = criteria.hasClearBudget;
    _amongFirst = criteria.amongFirst;
    _matchesMyCategories = criteria.matchesMyCategories;
    _myNeedCategorySlugs = criteria.myNeedCategorySlugs;
    _myRoleCapabilitySlugs = criteria.myRoleCapabilitySlugs;

    try {
      final pState = context.read<ProfileCubit>().state;
      if (pState is ProfileCubitLoaded) {
        final p = pState.profile;
        final isBankAgent = p.isBankAgent;
        final institutionType = p.institutionType;
        final preferredBank = p.preferredBank;
        _isAgentEligible = isBankAgent ||
            (institutionType != null && institutionType.trim().isNotEmpty) ||
            (preferredBank != null && preferredBank.trim().isNotEmpty);
      }
    } catch (_) {}

    _seedFromProfile();
    _loadMyProviderMatches();
    _loadFavoriteCurrencies();
  }

  Future<void> _loadFavoriteCurrencies() async {
    try {
      final rows = await Supabase.instance.client
          .from(TableNames.currencies)
          .select('code')
          .eq('forex_trading_enabled', true)
          .order('code');
      if (!mounted) return;
      final codes = (rows as List)
          .map((row) => row['code'].toString())
          .where((code) => code.isNotEmpty)
          .toList();
      setState(() {
        _favoriteCurrencyOptions = codes;
        _favoriteCurrenciesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _favoriteCurrenciesLoading = false);
    }
  }

  Future<void> _loadMyProviderMatches() async {
    try {
      final client = Supabase.instance.client;
      final profiles = await client
          .from('job_profiles')
          .select('category_slug, job_profile_roles!inner(role_slug)')
          .eq('is_active', true)
          .eq('job_profile_roles.is_active', true);
      final categorySlugs = <String>{};
      final roleSlugs = <String>{};
      for (final row in profiles as List) {
        final map = Map<String, dynamic>.from(row as Map);
        if (map['category_slug'] != null) {
          categorySlugs.add(map['category_slug'].toString());
        }
        final roles = map['job_profile_roles'];
        if (roles is List) {
          for (final role in roles) {
            if (role is Map && role['role_slug'] != null) {
              roleSlugs.add(role['role_slug'].toString());
            }
          }
        }
      }
      final capabilities = <String>{};
      if (roleSlugs.isNotEmpty) {
        final roleRows = await client
            .from('capability_roles')
            .select('capability_slug')
            .inFilter('slug', roleSlugs.toList())
            .eq('is_active', true);
        for (final row in roleRows as List) {
          final capabilitySlug = row['capability_slug']?.toString();
          if (capabilitySlug != null && capabilitySlug.isNotEmpty) {
            capabilities.add(capabilitySlug);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _myNeedCategorySlugs = categorySlugs.toList();
        _myRoleCapabilitySlugs = capabilities.toList();
      });
    } catch (_) {
      // Keep matching disabled if the account's private role data is unavailable.
    }
  }

  Future<void> _chooseMoreLocation() async {
    final selectedLocation = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .55,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Any location'),
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
              ..._locations.skip(5).map((location) => ListTile(
                    title: Text(location),
                    onTap: () => Navigator.of(sheetContext).pop(location),
                  )),
            ],
          ),
        ),
      ),
    );
    if (selectedLocation == null || !mounted) return;
    setState(() => _locationController.text = selectedLocation);
  }

  Future<void> _seedFromProfile() async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      final data = await client
          .from(TableNames.profiles)
          .select(
              'country, employment_type, monthly_income, preferred_employment_types, '
              'preferred_income_bracket, prefers_suggested_terms, prefers_verified_only, '
              'is_bank_agent, institution_type, preferred_bank')
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

      // Agent is eligible for Institution Matches when they have specified
      // their bank/institution (preferred_bank or institution_type) or are a bank agent.
      final isBankAgent = data?['is_bank_agent'] as bool? ?? false;
      final institutionType = data?['institution_type'] as String?;
      final preferredBank = data?['preferred_bank'] as String?;
      final eligible = isBankAgent ||
          (institutionType != null && institutionType.trim().isNotEmpty) ||
          (preferredBank != null && preferredBank.trim().isNotEmpty);

      final employmentTypes = preferredEmploymentTypes ??
          (data?['employment_type'] == null
              ? null
              : [data!['employment_type'] as String]);
      final incomeBracket = preferredIncomeBracket ??
          _fnIncomeBracket(
            (data?['monthly_income'] as num?)?.toInt(),
          );

      setState(() {
        _currencyCode = currencyCode;
        _locations = EastAfricaCountries.findByCode(
          data?['country'] as String?,
        ).regions;
        _isAgentEligible = eligible;
        // If the filter was already active but the agent is now ineligible,
        // reset it to avoid a phantom filter.
        if (!eligible) _institutionMatchOnly = false;
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
            moduleFilter: _moduleFilter,
            employmentTypes: _selectedEmployment.toList(),
            incomeBrackets: _selectedIncome.toList(),
            suggestedTermsOnly: _suggestedTermsOnly,
            verifiedOnly: _verifiedOnly,
            institutionMatchOnly: _institutionMatchOnly,
            amountBands: _amountBands.toList(),
            location: _locationController.text.trim(),
            favoriteCurrencies: _favoriteCurrencies.toList(),
            needType: _needType,
            urgency: _urgency,
            hasClearBudget: _hasClearBudget,
            amongFirst: _amongFirst,
            matchesMyCategories: _matchesMyCategories,
            myNeedCategorySlugs: _myNeedCategorySlugs,
            myRoleCapabilitySlugs: _myRoleCapabilitySlugs,
          ),
        );
    Navigator.of(context).pop();
  }

  void _selectModule(MarketplaceModule? module) {
    setState(() {
      _moduleFilter = module;
      if (module != null) {
        _amountBands.clear();
        _locationController.clear();
        _verifiedOnly = false;
      }
      if (module != MarketplaceModule.loan) {
        _selectedEmployment.clear();
        _selectedIncome.clear();
        _suggestedTermsOnly = false;
        _institutionMatchOnly = false;
      }
      if (module != MarketplaceModule.forex) {
        _favoriteCurrencies.clear();
      }
      if (module != MarketplaceModule.needs) {
        _needType = '';
        _urgency = '';
        _hasClearBudget = false;
        _amongFirst = false;
        _matchesMyCategories = false;
      }
    });
  }

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
                        color: AppColors.proPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.proPurple,
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
                              color:
                                  AppColors.proPurple.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _moduleFilter = null;
                          _amountBands.clear();
                          _locationController.clear();
                          _favoriteCurrencies.clear();
                          _needType = '';
                          _urgency = '';
                          _hasClearBudget = false;
                          _amongFirst = false;
                          _matchesMyCategories = false;
                          _selectedEmployment.clear();
                          _selectedIncome.clear();
                          _suggestedTermsOnly = false;
                          _verifiedOnly = false;
                          _institutionMatchOnly = false;
                        });
                        context.read<MarketplaceCubit>().clearProFilters();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    _ModuleTypeSwitch(
                      selected: _moduleFilter,
                      onSelected: _selectModule,
                    ),
                    const SizedBox(height: 16),
                    if (_moduleFilter == null) ...[
                      _SectionHeader(
                        icon: Icons.tune_rounded,
                        label: 'Amount range',
                        subtitle: 'Brackets only. Exact amounts stay private',
                        textColor: text2,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: const [
                          ('Under 100K', 'under_100k'),
                          ('100K–500K', '100k_500k'),
                          ('500K–1M', '500k_1m'),
                          ('Over 1M', 'over_1m'),
                        ]
                            .map((entry) => _FilterChip(
                                  label: entry.$1,
                                  selected: _amountBands.contains(entry.$2),
                                  onTap: () => setState(() =>
                                      _amountBands.contains(entry.$2)
                                          ? _amountBands.remove(entry.$2)
                                          : _amountBands.add(entry.$2)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        subtitle: 'Where the request is from',
                        textColor: text2,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ..._locations.take(5).map((region) => _FilterChip(
                                label: region,
                                selected: _locationController.text == region,
                                onTap: () => setState(() {
                                  _locationController.text =
                                      _locationController.text == region
                                          ? ''
                                          : region;
                                }),
                              )),
                          if (_locations.length > 5)
                            _FilterChip(
                              label: _locationController.text.isNotEmpty &&
                                      !_locations.take(5).contains(
                                            _locationController.text,
                                          )
                                  ? 'More · ${_locationController.text}'
                                  : 'More',
                              selected: _locationController.text.isNotEmpty &&
                                  !_locations.take(5).contains(
                                        _locationController.text,
                                      ),
                              onTap: _chooseMoreLocation,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.shield_outlined,
                        label: 'Quality signals',
                        textColor: text2,
                      ),
                      const SizedBox(height: 6),
                      _ToggleTile(
                        icon: Icons.verified_outlined,
                        iconColor: AppColors.success,
                        title: 'Verified requester',
                        subtitle: 'Only KYC approved requesters',
                        value: _verifiedOnly,
                        onChanged: (v) => setState(() => _verifiedOnly = v),
                        border: border,
                      ),
                    ],
                    if (_moduleFilter == MarketplaceModule.forex) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.star_outline_rounded,
                        label: 'Favourite currencies',
                        subtitle: 'Other currencies are turned off',
                        textColor: text2,
                      ),
                      const SizedBox(height: 10),
                      if (_favoriteCurrenciesLoading)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_favoriteCurrencyOptions.isEmpty)
                        Text(
                          'No Forex currencies are currently enabled.',
                          style: TextStyle(color: text2, fontSize: 12),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _favoriteCurrencyOptions
                              .map((currency) => _FilterChip(
                                    label: currency,
                                    selected:
                                        _favoriteCurrencies.contains(currency),
                                    onTap: () => setState(() {
                                      if (_favoriteCurrencies
                                          .contains(currency)) {
                                        _favoriteCurrencies.remove(currency);
                                      } else {
                                        _favoriteCurrencies.add(currency);
                                      }
                                    }),
                                  ))
                              .toList(),
                        ),
                    ],
                    if (_moduleFilter == MarketplaceModule.needs) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                          icon: Icons.inventory_2_outlined,
                          label: 'Needs',
                          textColor: text2),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _needType,
                        decoration:
                            const InputDecoration(labelText: 'Need type'),
                        items: const [
                          ('Any type', ''),
                          ('Equipment', 'machinery_equipment'),
                          ('Logistics', 'transport_logistics'),
                          ('Services', 'professional_services'),
                          ('Procurement', 'specialized_products'),
                        ]
                            .map((entry) => DropdownMenuItem(
                                value: entry.$2, child: Text(entry.$1)))
                            .toList(),
                        onChanged: (v) => setState(() => _needType = v ?? ''),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _urgency.isEmpty ? 'Any urgency' : _urgency,
                        decoration: const InputDecoration(labelText: 'Urgency'),
                        items: const [
                          'Any urgency',
                          'Urgent',
                          'This week',
                          'Flexible',
                        ]
                            .map((v) =>
                                DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _urgency = v == 'Any urgency' ? '' : v ?? ''),
                      ),
                      const SizedBox(height: 8),
                      _ToggleTile(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.accent,
                          title: 'Has a clear budget',
                          subtitle: 'Only Needs with a stated budget',
                          value: _hasClearBudget,
                          onChanged: (v) => setState(() => _hasClearBudget = v),
                          border: border),
                      _ToggleTile(
                          icon: Icons.bolt_outlined,
                          iconColor: AppColors.warning,
                          title: 'Be among the first',
                          subtitle: 'Only Needs with no responses yet',
                          value: _amongFirst,
                          onChanged: (v) => setState(() => _amongFirst = v),
                          border: border),
                      _ToggleTile(
                          icon: Icons.category_outlined,
                          iconColor: AppColors.proPurple,
                          title: 'Matches my categories and roles',
                          subtitle:
                              'Use the categories selected in your profile',
                          value: _matchesMyCategories,
                          onChanged: (v) =>
                              setState(() => _matchesMyCategories = v),
                          border: border),
                    ],
                    if (_moduleFilter == MarketplaceModule.loan) ...[
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
                        label:
                            l10n?.filterIncomeRange ?? 'Monthly income range',
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
                      // Boolean toggles — Listing quality signals
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
                        onChanged: (v) =>
                            setState(() => _suggestedTermsOnly = v),
                        border: border,
                      ),
                    ],
                    if (_moduleFilter == MarketplaceModule.loan) ...[
                      const SizedBox(height: 24),
                      // Smart matching section (bank/credit agents only)
                      _SectionHeader(
                        icon: Icons.account_balance_rounded,
                        label: l10n?.filterSmartMatchingSection ??
                            'Smart matching',
                        textColor: text2,
                      ),
                      const SizedBox(height: 10),
                      _ToggleTile(
                        icon: Icons.account_balance_outlined,
                        iconColor: _isAgentEligible
                            ? AppColors.warning
                            : text2.withValues(alpha: 0.45),
                        title: l10n?.filterInstitutionMatches ??
                            'Institution matches',
                        subtitle: _isAgentEligible
                            ? (l10n?.filterInstitutionMatchesSubtitle ??
                                'Only opted-in loan requests matching your institution.')
                            : (l10n?.filterInstitutionMatchesIneligible ??
                                'Set your institution in Profile → Bank & Professional to enable this filter.'),
                        value: _institutionMatchOnly,
                        onChanged: _isAgentEligible
                            ? (v) => setState(() => _institutionMatchOnly = v)
                            : null,
                        border: border,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Privacy note
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.proPurple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.proPurple.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.proPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filters only narrow what you see. Requester names, '
                              'exact amounts and exact income are never shown.',
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _moduleFilter == MarketplaceModule.forex &&
                            _favoriteCurrenciesLoading
                        ? null
                        : _applyAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.proPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Show results · $_activeFilterCount filters',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int get _activeFilterCount {
    final shared = [
      _amountBands.isNotEmpty,
      _locationController.text.trim().isNotEmpty,
      _verifiedOnly,
    ].where((active) => active).length;
    final moduleSpecific = switch (_moduleFilter) {
      MarketplaceModule.loan => [
          _selectedEmployment.isNotEmpty,
          _selectedIncome.isNotEmpty,
          _suggestedTermsOnly,
          _institutionMatchOnly,
        ].where((active) => active).length,
      MarketplaceModule.forex => _favoriteCurrencies.isNotEmpty ? 1 : 0,
      MarketplaceModule.needs => [
          _needType.isNotEmpty,
          _urgency.isNotEmpty,
          _hasClearBudget,
          _amongFirst,
          _matchesMyCategories,
        ].where((active) => active).length,
      null => 0,
    };
    return shared + moduleSpecific + (_moduleFilter == null ? 0 : 1);
  }
}

class _ModuleTypeSwitch extends StatelessWidget {
  const _ModuleTypeSwitch({required this.selected, required this.onSelected});

  final MarketplaceModule? selected;
  final ValueChanged<MarketplaceModule?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const options = <(String, MarketplaceModule?)>[
      ('All', null),
      ('Loans', MarketplaceModule.loan),
      ('Forex', MarketplaceModule.forex),
      ('Needs', MarketplaceModule.needs),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option.$2;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Material(
                color: isSelected ? colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => onSelected(option.$2),
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        option.$1,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? colors.primary : null,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
        Icon(icon, size: 15, color: AppColors.proPurple),
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
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicWidth(
            child: SizedBox(
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.proPurple.withValues(alpha: 0.18)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected
                          ? AppColors.proPurple
                          : colors.outlineVariant,
                      width: selected ? 1.3 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.proPurple : null,
                    ),
                  ),
                ),
              ),
            ),
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
  final ValueChanged<bool>? onChanged; // nullable → disabled state
  final Color border;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledText = theme.colorScheme.onSurface.withValues(alpha: 0.35);
    return Opacity(
      opacity: _enabled ? 1.0 : 0.55,
      child: Container(
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _enabled ? null : disabledText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _enabled ? null : disabledText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.proPurple,
              activeTrackColor: AppColors.proPurple.withValues(alpha: 0.35),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
