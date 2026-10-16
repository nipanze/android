// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_service_role.dart';
import '../../domain/repositories/provider_repository_interface.dart';

const _marketingServicesSlug = 'marketing_services';
const _audienceCapabilitySlug = 'i_have_an_audience';
const _marketingCapabilitySlugs = {
  'social_media_marketing',
  'influencer_marketing',
  'content_creation',
  'product_reviews',
  'event_promotion',
  'affiliate_marketing',
  'advertising_campaigns',
  'brand_promotion',
  'tiktok_promotion',
  'other_marketing_services',
  _audienceCapabilitySlug,
};

const _financialCategorySlug = 'financial_services';
const _financialMetadataSlugs = {
  'bank_loan_agent',
  'money_lender_private_lender',
  'financial_advisory',
  'forex_currency_exchange',
  'loan_services',
  'sacco_microfinance',
  'other_financial_services',
};
const _financialOrderedSlugs = [
  'bank_loan_agent',
  'money_lender_private_lender',
  'financial_advisory',
  'forex_currency_exchange',
  'loan_services',
  'sacco_microfinance',
  'other_financial_services',
];

class ProviderCapabilitySelection {
  const ProviderCapabilitySelection({
    required this.slugs,
    this.metadataBySlug = const {},
    this.openWorkProfile = false,
    this.categorySlug,
    this.workRoles = const [],
    this.workMetadataByRole = const {},
  });

  final List<String> slugs;
  final Map<String, Map<String, dynamic>> metadataBySlug;
  final bool openWorkProfile;
  final String? categorySlug;
  final List<String> workRoles;
  final Map<String, Map<String, dynamic>> workMetadataByRole;
}

/// Bottom sheet for adding provider capabilities and work profiles.
class AddServiceSheet extends StatefulWidget {
  const AddServiceSheet({
    super.key,
    required this.existingSlugs,
    this.existingCapabilities = const [],
    this.existingAudienceMetadata,
    this.existingFinancialMetadata,
    this.preselectedCategorySlug,
    required this.needsRepository,
    required this.providerRepository,
    this.capabilityProfilesEnabled = false,
    this.workProfilesEnabled = false,
    this.initialJobsMode = false,
  });

  final Set<String> existingSlugs;
  final List<ProviderCapability> existingCapabilities;
  final Map<String, dynamic>? existingAudienceMetadata;
  final Map<String, dynamic>? existingFinancialMetadata;
  final String? preselectedCategorySlug;
  final NeedsRepository needsRepository;
  final IProviderRepository providerRepository;
  final bool capabilityProfilesEnabled;
  final bool workProfilesEnabled;
  final bool initialJobsMode;

  static Future<ProviderCapabilitySelection?> show(
    BuildContext context, {
    required Set<String> existingSlugs,
    List<ProviderCapability> existingCapabilities = const [],
    Map<String, dynamic>? existingAudienceMetadata,
    Map<String, dynamic>? existingFinancialMetadata,
    required NeedsRepository needsRepository,
    required IProviderRepository providerRepository,
    bool capabilityProfilesEnabled = false,
    bool workProfilesEnabled = false,
    bool initialJobsMode = false,
    String? preselectedCategorySlug,
  }) {
    return showModalBottomSheet<ProviderCapabilitySelection>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AddServiceSheet(
              existingSlugs: existingSlugs,
              existingCapabilities: existingCapabilities,
              existingAudienceMetadata: existingAudienceMetadata,
              existingFinancialMetadata: existingFinancialMetadata,
              preselectedCategorySlug: preselectedCategorySlug,
              needsRepository: needsRepository,
              providerRepository: providerRepository,
              capabilityProfilesEnabled: capabilityProfilesEnabled,
              workProfilesEnabled: workProfilesEnabled,
              initialJobsMode: initialJobsMode,
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  // Steps: 0 = choose category (Sheet B), 1 = category view (Sheet C/D), 2 = kinds (Sheet E), 3 = qualifications & proof (Sheet F)
  int _step = 0;
  NeedCategory? _selectedCategory;
  List<NeedCategory> _categories = [];
  List<NeedCapability> _categoryCapabilities = [];
  List<ProviderServiceRole> _categoryRoles = [];
  final Set<String> _selected = {};

  // Work profile selection state
  bool _iWantJobs = false;
  bool _offerServicesExpanded = false;
  final Set<String> _selectedRoles = {};
  int _currentRoleIndex = 0;
  final Map<String, Set<String>> _kindsByRole = {};
  final Map<String, Set<String>> _qualificationsByRole = {};
  final Map<String, String> _yearsExperienceByRole = {};
  final Map<String, String> _availabilityByRole = {};
  final Map<String, Set<String>> _languagesByRole = {};
  final Map<String, bool> _willingToTravelByRole = {};
  final Map<String, String> _expectedPayAmountByRole = {};
  final Map<String, String> _expectedPayPeriodByRole = {};
  final Map<String, Set<String>> _uploadedProofByRole = {};

  // Audience metadata
  final Set<String> _audiencePlatforms = {};
  final _audienceCountController = TextEditingController();
  final _audienceLocationController = TextEditingController();
  final _audienceInterestController = TextEditingController();

  // Financial services metadata
  final _institutionController = TextEditingController();
  final _roleController = TextEditingController();
  bool _showProfessionalTag = true;
  bool _allowInstitutionMatching = false;
  bool _showAudience = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _iWantJobs = widget.initialJobsMode;
    final audience = widget.existingAudienceMetadata;
    if (widget.existingSlugs.contains(_audienceCapabilitySlug)) {
      _selected.add(_audienceCapabilitySlug);
      _audiencePlatforms.addAll(
        (audience?['audience_platforms'] as List? ?? const [])
            .map((platform) => platform.toString()),
      );
      _audienceCountController.text =
          audience?['audience_followers_count']?.toString() ?? '';
      _audienceLocationController.text =
          audience?['audience_main_location']?.toString() ?? '';
      _audienceInterestController.text =
          audience?['audience_main_interest']?.toString() ?? '';
    }

    final financial = widget.existingFinancialMetadata;
    if (financial != null) {
      _institutionController.text = financial['institution']?.toString() ?? '';
      _roleController.text = financial['role']?.toString() ?? '';
      _showProfessionalTag =
          financial['show_professional_tag'] as bool? ?? true;
      _allowInstitutionMatching =
          financial['allow_institution_matching'] as bool? ?? false;
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _audienceCountController.dispose();
    _audienceLocationController.dispose();
    _audienceInterestController.dispose();
    _institutionController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildWorkMetadata(String roleSlug) {
    return {
      'role_id': roleSlug,
      'kind_ids': (_kindsByRole[roleSlug] ?? {}).toList(),
      'qualification_ids': (_qualificationsByRole[roleSlug] ?? {}).toList(),
      if (_yearsExperienceByRole[roleSlug] != null)
        'years_experience': _yearsExperienceByRole[roleSlug],
      if (_availabilityByRole[roleSlug] != null)
        'availability': _availabilityByRole[roleSlug],
      'languages': (_languagesByRole[roleSlug] ?? {'English'}).toList(),
      'willing_to_travel': _willingToTravelByRole[roleSlug] ?? false,
      if (_expectedPayAmountByRole[roleSlug] != null &&
          _expectedPayAmountByRole[roleSlug]!.isNotEmpty)
        'expected_pay': {
          'amount': int.tryParse(_expectedPayAmountByRole[roleSlug]!),
          'period': _expectedPayPeriodByRole[roleSlug] ?? 'month',
          'currency': 'UGX',
        },
    };
  }

  ProviderCapabilitySelection _selection() {
    final slugs = _selected.toList();
    final metadataBySlug = <String, Map<String, dynamic>>{};

    if (_selected.contains(_audienceCapabilitySlug)) {
      metadataBySlug[_audienceCapabilitySlug] = {
        'audience_platforms': _audiencePlatforms.toList(),
        'audience_followers_count': int.tryParse(
          _audienceCountController.text.trim(),
        ),
        'audience_main_location': _audienceLocationController.text.trim(),
        'audience_main_interest': _audienceInterestController.text.trim(),
      };
    }

    final financialSelected = _selected.intersection(_financialMetadataSlugs);
    if (financialSelected.isNotEmpty) {
      final institution = _institutionController.text.trim();
      final role = _roleController.text.trim();
      for (final slug in financialSelected) {
        metadataBySlug[slug] = {
          if (institution.isNotEmpty) 'institution': institution,
          if (role.isNotEmpty) 'role': role,
          'show_professional_tag': _showProfessionalTag,
          'allow_institution_matching': _allowInstitutionMatching,
        };
      }
    }

    final workMetadataByRole = <String, Map<String, dynamic>>{};
    for (final role in _selectedRoles) {
      workMetadataByRole[role] = _buildWorkMetadata(role);
    }

    return ProviderCapabilitySelection(
      slugs: slugs,
      metadataBySlug: metadataBySlug,
      openWorkProfile: _iWantJobs,
      categorySlug: _selectedCategory?.slug,
      workRoles: _selectedRoles.toList(),
      workMetadataByRole: workMetadataByRole,
    );
  }

  Future<void> _loadCategories() async {
    final cats = await widget.needsRepository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });

    if (widget.preselectedCategorySlug != null) {
      final cat = cats.firstWhere(
        (c) => c.slug == widget.preselectedCategorySlug,
        orElse: () => cats.first,
      );
      await _selectCategory(cat);
    }
  }

  Future<void> _selectCategory(NeedCategory cat) async {
    setState(() {
      _selectedCategory = cat;
      _showAudience = false;
      _loading = true;
    });
    final caps =
        await widget.needsRepository.getCapabilities(categorySlug: cat.slug);
    final roles = await widget.providerRepository.getServiceRoles(
      categorySlug: cat.slug,
    );
    if (!mounted) return;

    List<NeedCapability> filteredCaps;
    if (cat.slug == 'professional_services') {
      filteredCaps = caps
          .where((capability) =>
              capability.slug != _marketingServicesSlug &&
              !_marketingCapabilitySlugs.contains(capability.slug))
          .toList();
    } else if (cat.slug == 'marketing_promotion') {
      filteredCaps = caps
          .where((capability) => capability.slug != _marketingServicesSlug)
          .toList();
    } else if (cat.slug == _financialCategorySlug) {
      filteredCaps = caps.toList()
        ..sort((a, b) {
          final idxA = _financialOrderedSlugs.indexOf(a.slug);
          final idxB = _financialOrderedSlugs.indexOf(b.slug);
          if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
          if (idxA != -1) return -1;
          if (idxB != -1) return 1;
          return a.name.compareTo(b.name);
        });
    } else {
      filteredCaps = caps;
    }

    setState(() {
      _categoryCapabilities = filteredCaps;
      _categoryRoles = roles;
      _loading = false;
      _step = 1;
    });
  }

  void _openAudience() {
    setState(() => _showAudience = true);
  }

  void _goBack() {
    setState(() {
      if (_step == 3) {
        _step = 2;
      } else if (_step == 2) {
        if (_currentRoleIndex > 0) {
          _currentRoleIndex--;
        } else {
          _step = 1;
        }
      } else if (_showAudience) {
        _showAudience = false;
      } else {
        _step = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    if (_step > 0)
                      GestureDetector(
                        onTap: _goBack,
                        child: Icon(Icons.arrow_back_rounded,
                            color: text2, size: 22),
                      ),
                    if (_step > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _step == 0
                            ? l10n.chooseCategory
                            : _step == 2
                                ? 'STEP 2 OF 3: Choose Kind'
                                : _step == 3
                                    ? 'STEP 3 OF 3: Qualifications & Proof'
                                    : _showAudience
                                        ? l10n.iHaveAnAudience
                                        : (_selectedCategory
                                                ?.localizedName(localeCode) ??
                                            l10n.chooseCapabilities),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: text2,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Area
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _step == 0
                        ? _CategoryList(
                            categories: _categories,
                            existingCapabilities: widget.existingCapabilities,
                            scrollController: scrollController,
                            onSelect: _selectCategory,
                          )
                        : _step == 2
                            ? _KindStepView(
                                role: _categoryRoles.firstWhere(
                                  (r) =>
                                      r.slug ==
                                      _selectedRoles
                                          .elementAt(_currentRoleIndex),
                                  orElse: () => _categoryRoles.first,
                                ),
                                roleIndex: _currentRoleIndex,
                                totalRoles: _selectedRoles.length,
                                selectedKinds: _kindsByRole.putIfAbsent(
                                  _selectedRoles.elementAt(_currentRoleIndex),
                                  () => {},
                                ),
                                scrollController: scrollController,
                                onNext: () {
                                  if (_currentRoleIndex <
                                      _selectedRoles.length - 1) {
                                    setState(() => _currentRoleIndex++);
                                  } else {
                                    setState(() => _step = 3);
                                  }
                                },
                              )
                        : _step == 3
                            ? _QualificationsStepView(
                                roles: _categoryRoles
                                    .where((r) =>
                                        _selectedRoles.contains(r.slug))
                                    .toList(),
                                qualificationsByRole: _qualificationsByRole,
                                yearsExperienceByRole:
                                    _yearsExperienceByRole,
                                availabilityByRole: _availabilityByRole,
                                languagesByRole: _languagesByRole,
                                willingToTravelByRole:
                                    _willingToTravelByRole,
                                expectedPayAmountByRole:
                                    _expectedPayAmountByRole,
                                expectedPayPeriodByRole:
                                    _expectedPayPeriodByRole,
                                uploadedProofByRole: _uploadedProofByRole,
                                scrollController: scrollController,
                                onSave: () =>
                                    Navigator.of(context).pop(_selection()),
                              )
                            : _showAudience
                                ? _AudienceEditorView(
                                    audiencePlatforms: _audiencePlatforms,
                                    audienceCountController:
                                        _audienceCountController,
                                    audienceLocationController:
                                        _audienceLocationController,
                                    audienceInterestController:
                                        _audienceInterestController,
                                    scrollController: scrollController,
                                    onPlatformToggle: (platform) =>
                                        setState(() {
                                      if (_audiencePlatforms
                                          .contains(platform)) {
                                        _audiencePlatforms.remove(platform);
                                      } else {
                                        _audiencePlatforms.add(platform);
                                      }
                                    }),
                                    onDone: () =>
                                        setState(() => _showAudience = false),
                                  )
                                : _CategoryCapabilitiesView(
                                    capabilities: _categoryCapabilities,
                                    roles: _categoryRoles,
                                    existingSlugs: widget.existingSlugs,
                                    selected: _selected,
                                    selectedRoles: _selectedRoles,
                                    iWantJobs: _iWantJobs,
                                    workProfilesEnabled:
                                        widget.workProfilesEnabled,
                                    offerServicesExpanded:
                                        _offerServicesExpanded,
                                    scrollController: scrollController,
                                    onToggleCapability: (slug) {
                                      setState(() {
                                        if (_selected.contains(slug)) {
                                          _selected.remove(slug);
                                        } else {
                                          _selected.add(slug);
                                        }
                                      });
                                    },
                                    onToggleRole: (slug) {
                                      setState(() {
                                        if (_selectedRoles.contains(slug)) {
                                          _selectedRoles.remove(slug);
                                        } else {
                                          _selectedRoles.add(slug);
                                        }
                                      });
                                    },
                                    onIWantJobsChanged: (val) {
                                      setState(() {
                                        _iWantJobs = val;
                                      });
                                    },
                                    onToggleOfferExpanded: () {
                                      setState(() {
                                        _offerServicesExpanded =
                                            !_offerServicesExpanded;
                                      });
                                    },
                                    onSaveServices: () =>
                                        Navigator.of(context).pop(_selection()),
                                    onNextKind: () {
                                      setState(() {
                                        _step = 2;
                                        _currentRoleIndex = 0;
                                      });
                                    },
                                    onAudienceTap: _openAudience,
                                    audiencePlatforms: _audiencePlatforms,
                                    audienceFollowersCount: int.tryParse(
                                        _audienceCountController.text.trim()),
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet B: Choose Category List with green count badge
// ---------------------------------------------------------------------------
class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.categories,
    required this.existingCapabilities,
    required this.scrollController,
    required this.onSelect,
  });

  final List<NeedCategory> categories;
  final List<ProviderCapability> existingCapabilities;
  final ScrollController scrollController;
  final void Function(NeedCategory) onSelect;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bg3 = isDark ? AppColors.bg3Dark : AppColors.bg3Light;
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    final filtered = widget.categories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = cat.localizedName(localeCode).toLowerCase();
      final desc = (cat.localizedDescription(localeCode) ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchCategories,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: bg3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: border),
            itemBuilder: (_, i) {
              final cat = filtered[i];
              final description = cat.localizedDescription(localeCode);
              final count = widget.existingCapabilities
                  .where((c) =>
                      c.categorySlug == cat.slug ||
                      c.metadata['category_slug'] == cat.slug)
                  .length;

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(cat.localizedName(localeCode),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: description == null || description.isEmpty
                    ? null
                    : Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.text2Dark
                              : AppColors.text2Light,
                        ),
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () => widget.onSelect(cat),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet C (jobs OFF) and Sheet D (jobs ON) view
// ---------------------------------------------------------------------------
class _CategoryCapabilitiesView extends StatelessWidget {
  const _CategoryCapabilitiesView({
    required this.capabilities,
    required this.roles,
    required this.existingSlugs,
    required this.selected,
    required this.selectedRoles,
    required this.iWantJobs,
    required this.workProfilesEnabled,
    required this.offerServicesExpanded,
    required this.scrollController,
    required this.onToggleCapability,
    required this.onToggleRole,
    required this.onIWantJobsChanged,
    required this.onToggleOfferExpanded,
    required this.onSaveServices,
    required this.onNextKind,
    this.onAudienceTap,
    this.audiencePlatforms = const {},
    this.audienceFollowersCount,
  });

  final List<NeedCapability> capabilities;
  final List<ProviderServiceRole> roles;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final Set<String> selectedRoles;
  final bool iWantJobs;
  final bool workProfilesEnabled;
  final bool offerServicesExpanded;
  final ScrollController scrollController;
  final ValueChanged<String> onToggleCapability;
  final ValueChanged<String> onToggleRole;
  final ValueChanged<bool> onIWantJobsChanged;
  final VoidCallback onToggleOfferExpanded;
  final VoidCallback onSaveServices;
  final VoidCallback onNextKind;
  final VoidCallback? onAudienceTap;
  final Set<String> audiencePlatforms;
  final int? audienceFollowersCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Stack(
      children: [
        ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            // Switch card: "I want jobs in this category"
            if (workProfilesEnabled)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: iWantJobs ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple
                        .withValues(alpha: iWantJobs ? 0.35 : 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        color: Colors.purple, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I want jobs in this category',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            'Looking to be hired as an operator, driver, or technician?',
                            style:
                                TextStyle(fontSize: 11, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: iWantJobs,
                      activeThumbColor: Colors.purple,
                      onChanged: onIWantJobsChanged,
                    ),
                  ],
                ),
              ),

            // If jobs ON: WHAT I OFFER collapses to an accordion
            if (iWantJobs) ...[
              InkWell(
                onTap: onToggleOfferExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: border.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'WHAT I OFFER',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selected.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        offerServicesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: text2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Services list (shown if jobs OFF OR if accordion expanded)
            if (!iWantJobs || offerServicesExpanded) ...[
              if (!iWantJobs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'WHAT I OFFER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: text2,
                    ),
                  ),
                ),
              for (var index = 0; index < capabilities.length; index++) ...[
                if (capabilities[index].serviceGroupSlug != null &&
                    (index == 0 ||
                        capabilities[index - 1].serviceGroupSlug !=
                            capabilities[index].serviceGroupSlug))
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(4, index == 0 ? 4 : 12, 4, 4),
                    child: Text(
                      capabilities[index].serviceGroupName ?? '',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: text2,
                          ),
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final cap = capabilities[index];
                    final alreadyOwned = existingSlugs.contains(cap.slug);
                    final isSelected = selected.contains(cap.slug);

                    if (cap.slug == _audienceCapabilitySlug) {
                      final l10n = AppLocalizations.of(context)!;
                      final platformLabels = {
                        'whatsapp': l10n.audiencePlatformWhatsApp,
                        'tiktok': l10n.audiencePlatformTikTok,
                        'instagram': l10n.audiencePlatformInstagram,
                        'youtube': l10n.audiencePlatformYouTube,
                        'facebook': l10n.audiencePlatformFacebook,
                        'other': l10n.audiencePlatformOther,
                      };
                      final ordered = [
                        'whatsapp',
                        'tiktok',
                        'instagram',
                        'youtube',
                        'facebook',
                        'other',
                      ];
                      final selectedNames = ordered
                          .where(audiencePlatforms.contains)
                          .map((p) => platformLabels[p] ?? p)
                          .toList();
                      final subtitle = selectedNames.join(', ');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        enabled: !alreadyOwned,
                        leading: alreadyOwned
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 20)
                            : Checkbox(
                                value: isSelected,
                                onChanged: (_) {
                                  onToggleCapability(cap.slug);
                                  if (!isSelected && onAudienceTap != null) {
                                    onAudienceTap!();
                                  }
                                },
                                activeColor: AppColors.accent,
                              ),
                        title: Text(
                          cap.localizedName(localeCode),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: alreadyOwned ? text2 : null,
                          ),
                        ),
                        subtitle: subtitle.isNotEmpty
                            ? Text(
                                subtitle,
                                style: TextStyle(fontSize: 12, color: text2),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          if (alreadyOwned) return;
                          if (!isSelected) {
                            onToggleCapability(cap.slug);
                          }
                          if (onAudienceTap != null) {
                            onAudienceTap!();
                          }
                        },
                      );
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      enabled: !alreadyOwned,
                      leading: alreadyOwned
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 20)
                          : Checkbox(
                              value: isSelected,
                              onChanged: (_) => onToggleCapability(cap.slug),
                              activeColor: AppColors.accent,
                            ),
                      title: Text(
                        cap.localizedName(localeCode),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: alreadyOwned ? text2 : null,
                        ),
                      ),
                      onTap: alreadyOwned
                          ? null
                          : () => onToggleCapability(cap.slug),
                    );
                  },
                ),
                Divider(height: 1, color: border.withValues(alpha: 0.5)),
              ],
            ],

            // If jobs ON: STEP 1 OF 3 "What role do you do?"
            if (iWantJobs) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'STEP 1 OF 3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'What role do you do?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No specific job roles configured for this category yet.',
                      style: TextStyle(fontSize: 13, color: text2),
                    ),
                  ),
                )
              else
                for (final role in roles)
                  Builder(
                    builder: (context) {
                      final isSelected = selectedRoles.contains(role.slug);
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? Colors.purple.withValues(alpha: 0.08)
                            : Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.purple
                                : border.withValues(alpha: 0.7),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => onToggleRole(role.slug),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => onToggleRole(role.slug),
                                  activeColor: Colors.purple,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (role.kindQuestion != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          role.kindQuestion!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: text2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ],
        ),

        // Sticky bottom button
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: iWantJobs
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selectedRoles.isNotEmpty ? onNextKind : null,
                  child: const Text(
                    'Next: choose your kind',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selected.isNotEmpty ? onSaveServices : null,
                  child: Text(
                    selected.isNotEmpty
                        ? 'Save services (${selected.length})'
                        : 'Save services',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet E: Kind Step (Step 2 of 3)
// ---------------------------------------------------------------------------
class _KindStepView extends StatefulWidget {
  const _KindStepView({
    required this.role,
    required this.roleIndex,
    required this.totalRoles,
    required this.selectedKinds,
    required this.scrollController,
    required this.onNext,
  });

  final ProviderServiceRole role;
  final int roleIndex;
  final int totalRoles;
  final Set<String> selectedKinds;
  final ScrollController scrollController;
  final VoidCallback onNext;

  @override
  State<_KindStepView> createState() => _KindStepViewState();
}

class _KindStepViewState extends State<_KindStepView> {
  @override
  Widget build(BuildContext context) {
    final text2 = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Stack(
      children: [
        ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'STEP 2 OF 3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple,
                    ),
                  ),
                ),
                if (widget.totalRoles > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Role ${widget.roleIndex + 1} of ${widget.totalRoles}: ${widget.role.name}',
                    style: TextStyle(fontSize: 12, color: text2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.role.kindQuestion ?? 'Which kind do you do?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.selectedKinds.length} selected',
              style: TextStyle(fontSize: 12, color: text2),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in widget.role.kinds)
                  FilterChip(
                    label: Text(kind.name),
                    selected: widget.selectedKinds.contains(kind.slug),
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
                    checkmarkColor: Colors.purple,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          widget.selectedKinds.add(kind.slug);
                        } else {
                          widget.selectedKinds.remove(kind.slug);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.onNext,
            child: Text(
              widget.roleIndex < widget.totalRoles - 1
                  ? 'Next role'
                  : 'Next: qualifications & proof',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet F: Qualifications & Proof (Step 3 of 3)
// ---------------------------------------------------------------------------
class _QualificationsStepView extends StatefulWidget {
  const _QualificationsStepView({
    required this.roles,
    required this.qualificationsByRole,
    required this.yearsExperienceByRole,
    required this.availabilityByRole,
    required this.languagesByRole,
    required this.willingToTravelByRole,
    required this.expectedPayAmountByRole,
    required this.expectedPayPeriodByRole,
    required this.uploadedProofByRole,
    required this.scrollController,
    required this.onSave,
  });

  final List<ProviderServiceRole> roles;
  final Map<String, Set<String>> qualificationsByRole;
  final Map<String, String> yearsExperienceByRole;
  final Map<String, String> availabilityByRole;
  final Map<String, Set<String>> languagesByRole;
  final Map<String, bool> willingToTravelByRole;
  final Map<String, String> expectedPayAmountByRole;
  final Map<String, String> expectedPayPeriodByRole;
  final Map<String, Set<String>> uploadedProofByRole;
  final ScrollController scrollController;
  final VoidCallback onSave;

  @override
  State<_QualificationsStepView> createState() =>
      _QualificationsStepViewState();
}

class _QualificationsStepViewState extends State<_QualificationsStepView> {
  final _amountController = TextEditingController();

  final _experienceOptions = ['<1', '1-2', '3-5', '6-10', '10+'];
  final _availabilityOptions = [
    'Full-time',
    'Part-time',
    'Contract / project',
    'Weekends only'
  ];
  final _languageOptions = ['English', 'Swahili', 'Luganda', 'French', 'Arabic'];
  final _payPeriods = ['hour', 'day', 'week', 'month', 'project'];

  @override
  void initState() {
    super.initState();
    final firstRoleSlug = widget.roles.firstOrNull?.slug ?? '';
    _amountController.text =
        widget.expectedPayAmountByRole[firstRoleSlug] ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text2 = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final primaryRoleSlug = widget.roles.firstOrNull?.slug ?? '';

    return Stack(
      children: [
        ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'STEP 3 OF 3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Qualifications & proof',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tick qualifications you claim. Upload proof to request verified status.',
              style: TextStyle(fontSize: 12, color: text2),
            ),
            const SizedBox(height: 16),

            // Qualifications checkboxes per role
            for (final role in widget.roles) ...[
              if (widget.roles.length > 1) ...[
                Text(
                  role.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
              ],
              for (final qual in role.qualifications)
                Builder(builder: (ctx) {
                  final roleQuals = widget.qualificationsByRole
                      .putIfAbsent(role.slug, () => {});
                  final roleUploads = widget.uploadedProofByRole
                      .putIfAbsent(role.slug, () => {});
                  final isChecked = roleQuals.contains(qual.slug);
                  final isUploaded = roleUploads.contains(qual.slug);

                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: isChecked,
                    activeColor: Colors.purple,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          roleQuals.add(qual.slug);
                        } else {
                          roleQuals.remove(qual.slug);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            qual.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (isUploaded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Uploaded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
            ],

            // Dashed upload card for licences / proof
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
                color: Colors.purple.withValues(alpha: 0.04),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_rounded,
                      color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload certificates or licence',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'PDF, JPG, or PNG (up to 5 MB)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      // Mark primary qualifications uploaded as confirmation
                      final roleUploads = widget.uploadedProofByRole
                          .putIfAbsent(primaryRoleSlug, () => {});
                      final roleQuals = widget.qualificationsByRole
                          .putIfAbsent(primaryRoleSlug, () => {});
                      setState(() {
                        roleUploads.addAll(roleQuals);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document attached for verification'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Add Proof'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Years of experience
            const Text(
              'Years of experience',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final exp in _experienceOptions)
                  ChoiceChip(
                    label: Text(exp),
                    selected:
                        widget.yearsExperienceByRole[primaryRoleSlug] == exp,
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
                    onSelected: (val) {
                      setState(() {
                        widget.yearsExperienceByRole[primaryRoleSlug] =
                            val ? exp : '';
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability
            const Text(
              'Availability',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final avail in _availabilityOptions)
                  ChoiceChip(
                    label: Text(avail),
                    selected:
                        widget.availabilityByRole[primaryRoleSlug] == avail,
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
                    onSelected: (val) {
                      setState(() {
                        widget.availabilityByRole[primaryRoleSlug] =
                            val ? avail : '';
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Languages spoken
            const Text(
              'Languages spoken',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final lang in _languageOptions)
                  FilterChip(
                    label: Text(lang),
                    selected: (widget.languagesByRole[primaryRoleSlug] ??
                            {'English'})
                        .contains(lang),
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
                    onSelected: (val) {
                      final langs = widget.languagesByRole
                          .putIfAbsent(primaryRoleSlug, () => {'English'});
                      setState(() {
                        if (val) {
                          langs.add(lang);
                        } else {
                          langs.remove(lang);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Willing to travel
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Willing to travel / relocate',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: widget.willingToTravelByRole[primaryRoleSlug] ?? false,
              activeThumbColor: Colors.purple,
              onChanged: (val) {
                setState(() {
                  widget.willingToTravelByRole[primaryRoleSlug] = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Expected pay
            const Text(
              'Expected pay',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Amount (UGX)',
                      prefixText: 'UGX ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      widget.expectedPayAmountByRole[primaryRoleSlug] = val;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.expectedPayPeriodByRole[primaryRoleSlug] ??
                        'month',
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in _payPeriods)
                        DropdownMenuItem(value: p, child: Text('/ $p')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        widget.expectedPayPeriodByRole[primaryRoleSlug] =
                            val ?? 'month';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // Sticky Save button
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.onSave,
            child: const Text(
              'Save work profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Audience Editor View
// ---------------------------------------------------------------------------
class _AudienceEditorView extends StatelessWidget {
  const _AudienceEditorView({
    required this.audiencePlatforms,
    required this.audienceCountController,
    required this.audienceLocationController,
    required this.audienceInterestController,
    required this.scrollController,
    required this.onPlatformToggle,
    required this.onDone,
  });

  final Set<String> audiencePlatforms;
  final TextEditingController audienceCountController;
  final TextEditingController audienceLocationController;
  final TextEditingController audienceInterestController;
  final ScrollController scrollController;
  final void Function(String) onPlatformToggle;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final platforms = <(String, String)>[
      ('whatsapp', l10n.audiencePlatformWhatsApp),
      ('tiktok', l10n.audiencePlatformTikTok),
      ('instagram', l10n.audiencePlatformInstagram),
      ('youtube', l10n.audiencePlatformYouTube),
      ('facebook', l10n.audiencePlatformFacebook),
      ('other', l10n.audiencePlatformOther),
    ];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.whereIsYourAudience,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.selectAudiencePlatforms,
          style: TextStyle(fontSize: 12, color: text2),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final (slug, label) in platforms)
              FilterChip(
                label: Text(label),
                selected: audiencePlatforms.contains(slug),
                onSelected: (_) => onPlatformToggle(slug),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.tellBusinessesAboutYourAudience,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: audienceCountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.audienceFollowersMembersCount,
            prefixIcon: const Icon(Icons.people_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: audienceLocationController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.audienceMainLocation,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: audienceInterestController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.audienceMainInterest,
            prefixIcon: const Icon(Icons.interests_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.done,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
