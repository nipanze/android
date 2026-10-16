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
    this.capabilityProfilesEnabled = true,
    this.workProfilesEnabled = true,
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
    bool capabilityProfilesEnabled = true,
    bool workProfilesEnabled = true,
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
    if (_iWantJobs) {
      for (final roleSlug in _selectedRoles) {
        workMetadataByRole[roleSlug] = _buildWorkMetadata(roleSlug);
        final role = _categoryRoles.firstWhere(
          (r) => r.slug == roleSlug,
          orElse: () => ProviderServiceRole(
            slug: roleSlug,
            name: roleSlug,
            categorySlug: _selectedCategory?.slug ?? '',
            capabilitySlug: 'work_$roleSlug',
            kindQuestion: '',
          ),
        );
        final capSlug = role.capabilitySlug ?? 'work_${role.slug}';
        if (!slugs.contains(capSlug)) {
          slugs.add(capSlug);
        }
        metadataBySlug[capSlug] = _buildWorkMetadata(roleSlug);
      }
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
    var roles = await widget.providerRepository.getServiceRoles(
      categorySlug: cat.slug,
    );
    if (roles.isEmpty) {
      roles = ProviderServiceRole.defaultsForCategory(cat.slug);
    }
    if (roles.isEmpty) {
      final workCaps = caps.where((c) =>
          c.serviceGroupSlug == 'work_roles' || c.slug.startsWith('work_'));
      if (workCaps.isNotEmpty) {
        roles = workCaps
            .map((c) => ProviderServiceRole(
                  slug: c.slug.replaceFirst('work_', ''),
                  name: c.name,
                  categorySlug: cat.slug,
                  capabilitySlug: c.slug,
                  kindQuestion: 'What is your specialty?',
                ))
            .toList();
      }
    }
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

    // Filter out work roles from the services section ("WHAT I OFFER") so they
    // are only inside the jobs flow ("What role do you do?").
    filteredCaps = filteredCaps
        .where((capability) =>
            capability.serviceGroupSlug != 'work_roles' &&
            !capability.slug.startsWith('work_'))
        .toList();

    // Populate initial selections for this category
    for (final cap in filteredCaps) {
      if (widget.existingSlugs.contains(cap.slug)) {
        _selected.add(cap.slug);
      }
    }
    for (final role in roles) {
      final capSlug = role.capabilitySlug ?? 'work_${role.slug}';
      if (widget.existingSlugs.contains(capSlug) ||
          widget.existingSlugs.contains(role.slug)) {
        _selectedRoles.add(role.slug);
      }
    }
    if (_selectedRoles.isNotEmpty) {
      _iWantJobs = true;
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
                            : (_step == 2 || _step == 3)
                                ? (_selectedRoles.isNotEmpty
                                    ? _categoryRoles
                                        .firstWhere(
                                          (r) =>
                                              r.slug ==
                                              _selectedRoles.elementAtOrNull(
                                                  _currentRoleIndex),
                                          orElse: () => _categoryRoles.first,
                                        )
                                        .name
                                    : (_selectedCategory
                                            ?.localizedName(localeCode) ??
                                        ''))
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
                                categorySlug: _selectedCategory?.slug,
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
                                    categorySlug: _selectedCategory?.slug,
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
    this.categorySlug,
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

  final String? categorySlug;
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
    final bg3 = isDark ? AppColors.bg3Dark : AppColors.bg3Light;
    final localeCode = Localizations.localeOf(context).languageCode;

    // Build ordered group list preserving original capability order.
    final List<(String?, String?, List<NeedCapability>)> orderedGroups = [];
    final seenGroupSlugs = <String>{};
    final noGroup = <NeedCapability>[];
    for (final cap in capabilities) {
      if (cap.serviceGroupSlug == 'work_roles' ||
          cap.slug.startsWith('work_')) {
        continue;
      }
      final g = cap.serviceGroupSlug;
      if (g != null && g.isNotEmpty) {
        if (!seenGroupSlugs.contains(g)) {
          seenGroupSlugs.add(g);
          final groupCaps = capabilities
              .where((c) =>
                  c.serviceGroupSlug == g &&
                  c.serviceGroupSlug != 'work_roles' &&
                  !c.slug.startsWith('work_'))
              .toList();
          orderedGroups.add((g, cap.serviceGroupName, groupCaps));
        }
      } else {
        noGroup.add(cap);
      }
    }
    if (noGroup.isNotEmpty) {
      orderedGroups.add((null, null, noGroup));
    }

    // Count only newly-selected (not already owned).
    final newSelected =
        selected.where((s) => !existingSlugs.contains(s)).length;

    return Stack(
      children: [
        ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            // ── Jobs toggle card ───────────────────────────────────
            if (workProfilesEnabled)
              _JobsToggleCard(
                iWantJobs: iWantJobs,
                categorySlug: categorySlug,
                onChanged: onIWantJobsChanged,
                border: border,
              ),

            // ── "WHAT I OFFER" section header ──────────────────────
            if (iWantJobs) ...[
              _SectionAccordion(
                label: 'What I offer',
                count: selected.length,
                summary: capabilities
                    .where((c) => selected.contains(c.slug))
                    .map((c) => c.localizedName(localeCode))
                    .join(', '),
                expanded: offerServicesExpanded,
                onTap: onToggleOfferExpanded,
                text2: text2,
                border: border,
              ),
              const SizedBox(height: 12),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
                child: Text(
                  'WHAT I OFFER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: text2,
                  ),
                ),
              ),
            ],

            // ── Service capability cards (grouped) ─────────────────
            if (!iWantJobs || offerServicesExpanded)
              for (final (groupSlug, groupName, caps) in orderedGroups) ...[
                if (groupName != null && groupName.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
                    child: Text(
                      groupName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: text2,
                          ),
                    ),
                  ),
                ] else if (groupSlug == null && orderedGroups.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
                    child: Text(
                      'Other',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: text2,
                          ),
                    ),
                  ),
                ],
                for (final cap in caps)
                  _CapabilityCard(
                    cap: cap,
                    localeCode: localeCode,
                    isSelected: selected.contains(cap.slug),
                    alreadyOwned: existingSlugs.contains(cap.slug),
                    isDark: isDark,
                    border: border,
                    bg3: bg3,
                    text2: text2,
                    onTap: () {
                      if (cap.slug == _audienceCapabilitySlug) {
                        if (!selected.contains(cap.slug)) {
                          onToggleCapability(cap.slug);
                        }
                        onAudienceTap?.call();
                      } else {
                        onToggleCapability(cap.slug);
                      }
                    },
                    audiencePlatforms: cap.slug == _audienceCapabilitySlug
                        ? audiencePlatforms
                        : null,
                    audienceFollowersCount: cap.slug == _audienceCapabilitySlug
                        ? audienceFollowersCount
                        : null,
                  ),
              ],

            // ── Jobs: role selection ───────────────────────────────
            if (iWantJobs) ...[
              const SizedBox(height: 16),
              Text(
                'STEP 1 OF 3',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: text2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What role do you do?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick every role that fits you. You can add more later.',
                style: TextStyle(fontSize: 12, color: text2),
              ),
              const SizedBox(height: 12),
              if (roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No specific job roles configured for this category yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: text2),
                    ),
                  ),
                )
              else
                for (final role in roles)
                  _RoleCard(
                    role: role,
                    isSelected: selectedRoles.contains(role.slug),
                    border: border,
                    text2: text2,
                    onTap: () => onToggleRole(role.slug),
                  ),
            ],
          ],
        ),

        // ── Sticky bottom action button ─────────────────────────────
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: iWantJobs
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.proPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.proPurple.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selectedRoles.isNotEmpty ? onNextKind : null,
                  child: Text(
                    selectedRoles.isNotEmpty
                        ? 'Next: choose your kind'
                        : 'Select at least one role',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: newSelected > 0 ? onSaveServices : null,
                  child: Text(
                    newSelected > 0
                        ? 'Save services ($newSelected)'
                        : 'Select at least one service',
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
// Helper widgets for the category capabilities view
// ---------------------------------------------------------------------------

/// Jobs toggle card shown at the top when workProfilesEnabled is true.
class _JobsToggleCard extends StatelessWidget {
  const _JobsToggleCard({
    required this.iWantJobs,
    required this.onChanged,
    required this.border,
    this.categorySlug,
  });

  final bool iWantJobs;
  final ValueChanged<bool> onChanged;
  final Color border;
  final String? categorySlug;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.proPurple;
    final String subtitle = iWantJobs
        ? 'Employers can find and hire you for these roles'
        : switch (categorySlug) {
            'machinery_equipment' =>
              'Operator, mechanic, manager or supervisor roles',
            'transport_logistics' =>
              'Driver, fleet manager, or courier roles',
            'construction_building' =>
              'Foreman, mason, plumber, electrician or trades roles',
            'technology_digital' =>
              'Developer, technician, or IT specialist roles',
            'marketing_promotion' =>
              'Marketer, content creator, or campaign manager roles',
            'professional_services' =>
              'Accountant, lawyer, engineer, or consultant roles',
            'education_training' =>
              'Teacher, tutor, trainer, or instructor roles',
            'events_celebrations' || 'events_production' =>
              'Planner, MC, DJ, caterer, or crew roles',
            'photo_video_talent' || 'photo_video_music_talent' =>
              'Photographer, videographer, or performer roles',
            'beauty_fashion_styling' =>
              'Stylist, barber, makeup artist, or designer roles',
            'energy_utilities' =>
              'Solar, electrical, borehole, or energy technician roles',
            'agriculture_agribusiness' =>
              'Farm manager, agronomist, or livestock officer roles',
            'specialized_products' =>
              'Procurement officer, sourcing, or customs agent roles',
            'travel_international' =>
              'Travel consultant, tour guide, or driver-guide roles',
            _ => 'Looking to be hired? Build a work-seeker profile.',
          };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: iWantJobs
            ? activeColor.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iWantJobs
              ? activeColor.withValues(alpha: 0.4)
              : border.withValues(alpha: 0.6),
          width: iWantJobs ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!iWantJobs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                iWantJobs
                    ? Icons.work_rounded
                    : Icons.work_outline_rounded,
                color: activeColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I want jobs in this category',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: iWantJobs ? activeColor : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: iWantJobs
                            ? activeColor.withValues(alpha: 0.8)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: iWantJobs,
                activeThumbColor: activeColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible accordion header for the "WHAT I OFFER" section (jobs-ON mode).
class _SectionAccordion extends StatelessWidget {
  const _SectionAccordion({
    required this.label,
    required this.count,
    this.summary,
    required this.expanded,
    required this.onTap,
    required this.text2,
    required this.border,
  });

  final String label;
  final int count;
  final String? summary;
  final bool expanded;
  final VoidCallback onTap;
  final Color text2;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: text2,
                    ),
                  ),
                  if (summary != null && summary!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      summary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.green.shade300
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: text2,
            ),
          ],
        ),
      ),
    );
  }
}


/// A tappable selection card for a single capability / service item.
class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.cap,
    required this.localeCode,
    required this.isSelected,
    required this.alreadyOwned,
    required this.isDark,
    required this.border,
    required this.bg3,
    required this.text2,
    required this.onTap,
    this.audiencePlatforms,
    this.audienceFollowersCount,
  });

  final NeedCapability cap;
  final String localeCode;
  final bool isSelected;
  final bool alreadyOwned;
  final bool isDark;
  final Color border;
  final Color bg3;
  final Color text2;
  final VoidCallback onTap;
  final Set<String>? audiencePlatforms;
  final int? audienceFollowersCount;

  @override
  Widget build(BuildContext context) {
    final bool isAudience = cap.slug == _audienceCapabilitySlug;
    const accentColor = AppColors.accent;

    String? subtitle;
    if (isAudience &&
        audiencePlatforms != null &&
        audiencePlatforms!.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final platformLabels = {
        'whatsapp': l10n.audiencePlatformWhatsApp,
        'tiktok': l10n.audiencePlatformTikTok,
        'instagram': l10n.audiencePlatformInstagram,
        'youtube': l10n.audiencePlatformYouTube,
        'facebook': l10n.audiencePlatformFacebook,
        'other': l10n.audiencePlatformOther,
      };
      const ordered = [
        'whatsapp',
        'tiktok',
        'instagram',
        'youtube',
        'facebook',
        'other',
      ];
      final selectedNames = ordered
          .where(audiencePlatforms!.contains)
          .map((p) => platformLabels[p] ?? p)
          .toList();
      subtitle = selectedNames.join(', ');
    }

    return GestureDetector(
      onTap: alreadyOwned ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: alreadyOwned
              ? bg3.withValues(alpha: 0.6)
              : isSelected
                  ? accentColor.withValues(alpha: 0.07)
                  : isDark
                      ? AppColors.bg3Dark.withValues(alpha: 0.4)
                      : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: alreadyOwned
                ? border.withValues(alpha: 0.4)
                : isSelected
                    ? accentColor.withValues(alpha: 0.65)
                    : border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (alreadyOwned)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20)
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? accentColor : border,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                      : null,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cap.localizedName(localeCode),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: alreadyOwned ? text2 : null,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: text2),
                      ),
                    ],
                  ],
                ),
              ),
              if (isAudience && !alreadyOwned)
                Icon(Icons.chevron_right_rounded, color: text2, size: 18),
              if (alreadyOwned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Added',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable selection card for a work / job role.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.border,
    required this.text2,
    required this.onTap,
  });

  final ProviderServiceRole role;
  final bool isSelected;
  final Color border;
  final Color text2;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.proPurple;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.07)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.65)
                : border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? activeColor : border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if ((role.description ?? role.kindQuestion) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        role.description ?? role.kindQuestion!,
                        style: TextStyle(fontSize: 12, color: text2),
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
    this.categorySlug,
  });

  final ProviderServiceRole role;
  final int roleIndex;
  final int totalRoles;
  final Set<String> selectedKinds;
  final ScrollController scrollController;
  final VoidCallback onNext;
  final String? categorySlug;

  @override
  State<_KindStepView> createState() => _KindStepViewState();
}

class _KindStepViewState extends State<_KindStepView> {
  String _getInstruction(ProviderServiceRole role) {
    final q = (role.kindQuestion ?? '').toLowerCase();
    final slug = role.slug.toLowerCase();
    if (slug == 'machine_operator' || q.contains('machine')) {
      return 'Pick all that apply. Employers search by machine.';
    }
    if (slug == 'skilled_tradesperson' || q.contains('trade')) {
      return 'Pick all that apply. Employers search by trade.';
    }
    if (slug == 'site_manager' || q.contains('site')) {
      return 'Pick all that apply. Employers search by site type.';
    }
    if (slug == 'driver' || q.contains('vehicle') || q.contains('drive')) {
      return 'Pick all that apply. Employers search by vehicle type.';
    }
    if (slug == 'developer' || q.contains('build') || q.contains('software')) {
      return 'Pick all that apply. Employers search by tech stack.';
    }
    if (slug == 'marketer_specialist' || q.contains('channel')) {
      return 'Pick all that apply. Employers search by marketing channel.';
    }
    return 'Pick all that apply. Employers search by specialty.';
  }

  String _getCalloutNote(String? categorySlug) {
    return switch (categorySlug) {
      'construction_building' =>
        'The question changes with the role. A Tradesperson is asked "Which trade?" and a Site Manager is asked "What type of sites?"',
      'machinery_equipment' =>
        'The question changes with the role. A Mechanic is asked "What do you service?" and a Fleet Manager is asked "What fleet?"',
      'technology_digital' =>
        'The question changes with the role. A Developer is asked "What do you build?" and an IT Technician is asked "What do you do?"',
      'transport_logistics' =>
        'The question changes with the role. A Driver is asked "What do you drive?" and a Fleet Manager is asked "What fleet?"',
      'energy_utilities' =>
        'The question changes with the role. A Solar Tech is asked "What do you install?" and a Water Tech is asked "What do you do?"',
      'marketing_promotion' =>
        'The question changes with the role. A Marketer is asked "Which channel?" and a Content Creator is asked "What do you produce?"',
      'professional_services' =>
        'The question changes with the role. An Engineer is asked "Which discipline?" and an Accountant is asked "What area?"',
      'events_celebrations' || 'events_production' =>
        'The question changes with the role. An Event Planner is asked "What events?" and an MC/DJ is asked "Which role?"',
      'photo_video_talent' || 'photo_video_music_talent' =>
        'The question changes with the role. A Photographer is asked "What do you shoot?" and an Audio Producer is asked "What do you do?"',
      'beauty_fashion_styling' =>
        'The question changes with the role. A Stylist is asked "Specialty?" and a Manager is asked "What scope?"',
      'agriculture_agribusiness' =>
        'The question changes with the role. An Agronomist is asked "What focus?" and a Livestock Officer is asked "What animals?"',
      'specialized_products' =>
        'The question changes with the role. A Procurement Officer is asked "What do you buy?" and a Sourcing Agent is asked "Where do you source?"',
      'travel_international' =>
        'The question changes with the role. A Tour Guide is asked "What tours?" and a Driver-Guide is asked "What vehicle?"',
      _ =>
        'The question changes with the role to help employers find your exact specialty.',
    };
  }

  String _getSelectionCountLabel(ProviderServiceRole role, int count) {
    final q = (role.kindQuestion ?? '').toLowerCase();
    final slug = role.slug.toLowerCase();
    if (slug == 'machine_operator' || q.contains('machine')) {
      return '$count machine${count == 1 ? '' : 's'} selected';
    }
    if (slug == 'skilled_tradesperson' || q.contains('trade')) {
      return '$count trade${count == 1 ? '' : 's'} selected';
    }
    if (slug == 'site_manager' || q.contains('site')) {
      return '$count site type${count == 1 ? '' : 's'} selected';
    }
    if (slug == 'driver' || q.contains('vehicle') || q.contains('drive')) {
      return '$count vehicle type${count == 1 ? '' : 's'} selected';
    }
    return '$count selected';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return Stack(
      children: [
        ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            Row(
              children: [
                Text(
                  'STEP 2 OF 3',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: text2,
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
              _getInstruction(widget.role),
              style: TextStyle(fontSize: 12, color: text2),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in widget.role.kinds)
                  FilterChip(
                    label: Text(kind.name),
                    selected: widget.selectedKinds.contains(kind.slug),
                    selectedColor: AppColors.proPurple.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.proPurple,
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
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg3Dark : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: border.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                _getCalloutNote(widget.categorySlug),
                style: TextStyle(fontSize: 11, color: text2, height: 1.3),
              ),
            ),
            Center(
              child: Text(
                _getSelectionCountLabel(
                    widget.role, widget.selectedKinds.length),
                style: TextStyle(
                  fontSize: 12,
                  color: text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.proPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.selectedKinds.isNotEmpty ? widget.onNext : null,
            child: Text(
              widget.roleIndex < widget.totalRoles - 1
                  ? 'Next role'
                  : 'Next: add qualifications',
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

  final _experienceOptions = ['Under 1', '1-2', '3-5', '6-10', '10+'];
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
            Text(
              'STEP 3 OF 3',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: text2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tick what you have',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'More ticks and proofs mean better job matches.',
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
                    activeColor: AppColors.proPurple,
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
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.amber.shade700
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Uploaded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade800,
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
            InkWell(
              onTap: () {
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
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.proPurple.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                  color: AppColors.proPurple.withValues(alpha: 0.04),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_upload_outlined,
                        color: AppColors.proPurple, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload licence or certificates',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reviewed by Nipanze. Approved proofs earn a badge.',
                            style: TextStyle(fontSize: 11, color: text2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    selectedColor: AppColors.proPurple.withValues(alpha: 0.2),
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
                    selectedColor: AppColors.proPurple.withValues(alpha: 0.2),
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
                    selectedColor: AppColors.proPurple.withValues(alpha: 0.2),
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
              activeThumbColor: AppColors.proPurple,
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
              backgroundColor: AppColors.proPurple,
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
