// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
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
  });

  final List<String> slugs;
  final Map<String, Map<String, dynamic>> metadataBySlug;
  final bool openWorkProfile;
  final String? categorySlug;
}

/// Bottom sheet for adding provider capabilities.
/// Returns selected slugs and metadata, or null if dismissed.
class AddServiceSheet extends StatefulWidget {
  const AddServiceSheet({
    super.key,
    required this.existingSlugs,
    this.existingAudienceMetadata,
    this.existingFinancialMetadata,
    this.preselectedCategorySlug,
    required this.needsRepository,
    required this.providerRepository,
    this.capabilityProfilesEnabled = false,
  });

  final Set<String> existingSlugs;
  final Map<String, dynamic>? existingAudienceMetadata;
  final Map<String, dynamic>? existingFinancialMetadata;
  final String? preselectedCategorySlug;
  final NeedsRepository needsRepository;
  final IProviderRepository providerRepository;
  final bool capabilityProfilesEnabled;

  static Future<ProviderCapabilitySelection?> show(
    BuildContext context, {
    required Set<String> existingSlugs,
    Map<String, dynamic>? existingAudienceMetadata,
    Map<String, dynamic>? existingFinancialMetadata,
    required NeedsRepository needsRepository,
    required IProviderRepository providerRepository,
    bool capabilityProfilesEnabled = false,
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
              existingAudienceMetadata: existingAudienceMetadata,
              existingFinancialMetadata: existingFinancialMetadata,
              preselectedCategorySlug: preselectedCategorySlug,
              needsRepository: needsRepository,
              providerRepository: providerRepository,
              capabilityProfilesEnabled: capabilityProfilesEnabled,
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
  int _step = 0; // 0 = category, 1 = capability
  NeedCategory? _selectedCategory;
  List<NeedCategory> _categories = [];
  List<NeedCapability> _categoryCapabilities = [];
  List<NeedCapability> _marketingCapabilities = [];
  List<ProviderServiceRole> _categoryRoles = [];
  final Set<String> _selected = {};
  final Map<String, _CapabilityDraft> _drafts = {};
  final Set<String> _audiencePlatforms = {};
  final _audienceCountController = TextEditingController();
  final _audienceLocationController = TextEditingController();
  final _audienceInterestController = TextEditingController();
  // Financial services metadata
  final _institutionController = TextEditingController();
  final _roleController = TextEditingController();
  bool _showProfessionalTag = true;
  bool _allowInstitutionMatching = false;
  bool _showMarketing = false;
  bool _loading = true;
  bool _iWantJobs = false;

  @override
  void initState() {
    super.initState();
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

    // Include financial metadata for each selected financial capability
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

    if (widget.capabilityProfilesEnabled) {
      for (final entry in _drafts.entries) {
        if (!_selected.contains(entry.key)) continue;
        metadataBySlug[entry.key] = {
          ...?metadataBySlug[entry.key],
          ...entry.value.toMetadata(),
        };
      }
    }

    return ProviderCapabilitySelection(
      slugs: slugs,
      metadataBySlug: metadataBySlug,
      openWorkProfile: _iWantJobs,
      categorySlug: _selectedCategory?.slug,
    );
  }

  bool get _canSubmit =>
      _selected.isNotEmpty &&
      (!_selected.contains(_audienceCapabilitySlug) ||
          _audiencePlatforms.isNotEmpty);

  bool get _showDetailsStep =>
      widget.capabilityProfilesEnabled && _selected.isNotEmpty;

  Future<void> _loadCategories() async {
    final cats = await widget.needsRepository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });

    // If preselected, skip to step 1
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
      _showMarketing = false;
      _loading = true;
    });
    final caps =
        await widget.needsRepository.getCapabilities(categorySlug: cat.slug);
    final roles = widget.capabilityProfilesEnabled
        ? await widget.providerRepository.getServiceRoles(
            categorySlug: cat.slug,
          )
        : const <ProviderServiceRole>[];
    if (!mounted) return;

    List<NeedCapability> filteredCaps;
    if (cat.slug == 'professional_services') {
      filteredCaps = caps
          .where((capability) =>
              !_marketingCapabilitySlugs.contains(capability.slug))
          .toList();
      if (!filteredCaps.any((c) => c.slug == _marketingServicesSlug)) {
        filteredCaps.add(
          const NeedCapability(
            slug: _marketingServicesSlug,
            categorySlug: 'professional_services',
            name: 'Marketing & Promotion',
          ),
        );
      }
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

  Future<void> _openMarketing() async {
    setState(() {
      _showMarketing = true;
      _loading = true;
    });
    final caps = await widget.needsRepository.getCapabilities(
      categorySlug: 'professional_services',
    );
    if (!mounted) return;
    setState(() {
      _marketingCapabilities = caps
          .where((capability) =>
              _marketingCapabilitySlugs.contains(capability.slug))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _loading = false;
    });
  }

  void _goBack() {
    setState(() {
      if (_step == 2) {
        _step = 1;
      } else if (_showMarketing) {
        _showMarketing = false;
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
      initialChildSize: 0.75,
      minChildSize: 0.4,
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
                                ? 'Service details'
                                : _showMarketing
                                    ? l10n.marketingAndPromotion
                                    : (_selectedCategory
                                            ?.localizedName(localeCode) ??
                                        l10n.chooseCapabilities),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_step > 0 && _canSubmit)
                      TextButton(
                        onPressed: () {
                          if (_step == 1 && _showDetailsStep) {
                            setState(() => _step = 2);
                            return;
                          }
                          Navigator.of(context).pop(_selection());
                        },
                        child: Text(
                          _step == 1 && _showDetailsStep
                              ? 'Next'
                              : l10n.addSelected,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _step == 0
                        ? _CategoryList(
                            categories: _categories,
                            scrollController: scrollController,
                            onSelect: _selectCategory,
                          )
                        : _step == 2
                            ? _CapabilityDetailsList(
                                capabilities: _categoryCapabilities
                                    .where(
                                        (cap) => _selected.contains(cap.slug))
                                    .toList(),
                                roles: _categoryRoles,
                                drafts: _drafts,
                                scrollController: scrollController,
                                onChanged: () => setState(() {}),
                              )
                            : _showMarketing
                                ? _MarketingCapabilityList(
                                    capabilities: _marketingCapabilities,
                                    existingSlugs: widget.existingSlugs,
                                    selected: _selected,
                                    audiencePlatforms: _audiencePlatforms,
                                    audienceCountController:
                                        _audienceCountController,
                                    audienceLocationController:
                                        _audienceLocationController,
                                    audienceInterestController:
                                        _audienceInterestController,
                                    scrollController: scrollController,
                                    onToggle: (slug) => setState(() {
                                      if (_selected.contains(slug)) {
                                        _selected.remove(slug);
                                        _drafts.remove(slug);
                                      } else {
                                        _selected.add(slug);
                                        _drafts.putIfAbsent(
                                          slug,
                                          () => _CapabilityDraft(),
                                        );
                                      }
                                    }),
                                    onPlatformToggle: (platform) =>
                                        setState(() {
                                      if (_audiencePlatforms
                                          .contains(platform)) {
                                        _audiencePlatforms.remove(platform);
                                      } else {
                                        _audiencePlatforms.add(platform);
                                      }
                                    }),
                                  )
                                : _selectedCategory?.slug ==
                                        _financialCategorySlug
                                    ? _FinancialCapabilityList(
                                        capabilities: _categoryCapabilities,
                                        existingSlugs: widget.existingSlugs,
                                        selected: _selected,
                                        institutionController:
                                            _institutionController,
                                        roleController: _roleController,
                                        showProfessionalTag:
                                            _showProfessionalTag,
                                        allowInstitutionMatching:
                                            _allowInstitutionMatching,
                                        scrollController: scrollController,
                                        onToggle: (slug) {
                                          setState(() {
                                            if (_selected.contains(slug)) {
                                              _selected.remove(slug);
                                              _drafts.remove(slug);
                                            } else {
                                              _selected.add(slug);
                                              _drafts.putIfAbsent(
                                                slug,
                                                () => _CapabilityDraft(),
                                              );
                                            }
                                          });
                                        },
                                        onProfessionalTagChanged: (v) =>
                                            setState(
                                                () => _showProfessionalTag = v),
                                        onInstitutionMatchingChanged: (v) =>
                                            setState(() =>
                                                _allowInstitutionMatching = v),
                                        iWantJobs: _iWantJobs,
                                        onIWantJobsChanged: (v) =>
                                            setState(() => _iWantJobs = v),
                                      )
                                    : _CapabilityList(
                                        capabilities: _categoryCapabilities,
                                        existingSlugs: widget.existingSlugs,
                                        selected: _selected,
                                        scrollController: scrollController,
                                        onMarketingTap: _openMarketing,
                                        iWantJobs: _iWantJobs,
                                        onIWantJobsChanged: (v) =>
                                            setState(() => _iWantJobs = v),
                                        onToggle: (slug) {
                                          setState(() {
                                            if (_selected.contains(slug)) {
                                              _selected.remove(slug);
                                              _drafts.remove(slug);
                                            } else {
                                              _selected.add(slug);
                                              _drafts.putIfAbsent(
                                                slug,
                                                () => _CapabilityDraft(),
                                              );
                                            }
                                          });
                                        },
                                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CapabilityDraft {
  bool service = true;
  bool work = false;
  String? roleId;
  final Set<String> kindIds = {};
  final Set<String> qualificationIds = {};
  String? yearsExperience;
  String? availability;
  final Set<String> languages = {'en'};
  bool willingToTravel = false;
  String? expectedPayAmount;
  String? expectedPayPeriod;

  Map<String, dynamic> toMetadata() {
    final roles = <Map<String, dynamic>>[
      if (work && roleId != null)
        {
          'role_id': roleId,
          'kind_ids': kindIds.toList(),
          'qualification_ids': qualificationIds.toList(),
        },
    ];
    return {
      'engagements': [
        if (service) 'service',
        if (work) 'work',
      ],
      if (roles.isNotEmpty) 'roles': roles,
      if (yearsExperience != null) 'years_experience': yearsExperience,
      if (availability != null) 'availability': availability,
      'languages': languages.toList(),
      'willing_to_travel': willingToTravel,
      if (expectedPayAmount != null && expectedPayAmount!.isNotEmpty)
        'expected_pay': {
          'amount': int.tryParse(expectedPayAmount!),
          'period': expectedPayPeriod ?? 'day',
          'currency': 'UGX',
        },
    };
  }
}

class _CapabilityDetailsList extends StatelessWidget {
  const _CapabilityDetailsList({
    required this.capabilities,
    required this.roles,
    required this.drafts,
    required this.scrollController,
    required this.onChanged,
  });

  final List<NeedCapability> capabilities;
  final List<ProviderServiceRole> roles;
  final Map<String, _CapabilityDraft> drafts;
  final ScrollController scrollController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).dividerColor;
    final localeCode = Localizations.localeOf(context).languageCode;

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: capabilities.length,
      separatorBuilder: (_, __) => Divider(height: 28, color: border),
      itemBuilder: (context, index) {
        final cap = capabilities[index];
        final draft = drafts.putIfAbsent(cap.slug, () => _CapabilityDraft());
        return _CapabilityDetailEditor(
          capability: cap,
          roles: roles
              .where((role) =>
                  role.capabilitySlug == null ||
                  role.capabilitySlug == cap.slug ||
                  role.categorySlug == cap.categorySlug)
              .toList(),
          draft: draft,
          localeCode: localeCode,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _CapabilityDetailEditor extends StatelessWidget {
  const _CapabilityDetailEditor({
    required this.capability,
    required this.roles,
    required this.draft,
    required this.localeCode,
    required this.onChanged,
  });

  final NeedCapability capability;
  final List<ProviderServiceRole> roles;
  final _CapabilityDraft draft;
  final String localeCode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedRole = roles
        .where((role) => role.slug == draft.roleId)
        .cast<ProviderServiceRole?>()
        .firstOrNull;
    final text2 =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          capability.localizedName(localeCode),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            FilterChip(
              label: const Text('Provide service'),
              selected: draft.service,
              onSelected: (value) {
                draft.service = value;
                if (!draft.service && !draft.work) draft.work = true;
                onChanged();
              },
            ),
            FilterChip(
              label: const Text('Available for jobs'),
              selected: draft.work,
              onSelected: (value) {
                draft.work = value;
                if (!draft.service && !draft.work) draft.service = true;
                onChanged();
              },
            ),
          ],
        ),
        if (draft.work && roles.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: draft.roleId,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
            ),
            items: [
              for (final role in roles)
                DropdownMenuItem(value: role.slug, child: Text(role.name)),
            ],
            onChanged: (value) {
              draft.roleId = value;
              draft.kindIds.clear();
              draft.qualificationIds.clear();
              onChanged();
            },
          ),
        ],
        if (draft.work && selectedRole != null) ...[
          if (selectedRole.kindQuestion != null &&
              selectedRole.kinds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              selectedRole.kindQuestion!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final kind in selectedRole.kinds)
                  FilterChip(
                    label: Text(kind.name),
                    selected: draft.kindIds.contains(kind.slug),
                    onSelected: (_) {
                      if (draft.kindIds.contains(kind.slug)) {
                        draft.kindIds.remove(kind.slug);
                      } else {
                        draft.kindIds.add(kind.slug);
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
          if (selectedRole.qualifications.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Qualifications',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final qualification in selectedRole.qualifications)
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(qualification.name),
                        if (qualification.isEvidence) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.upload_file_rounded, size: 14),
                        ],
                      ],
                    ),
                    selected:
                        draft.qualificationIds.contains(qualification.slug),
                    onSelected: (_) {
                      if (draft.qualificationIds.contains(qualification.slug)) {
                        draft.qualificationIds.remove(qualification.slug);
                      } else {
                        draft.qualificationIds.add(qualification.slug);
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: draft.yearsExperience,
                decoration: const InputDecoration(labelText: 'Experience'),
                items: const [
                  DropdownMenuItem(value: '<1', child: Text('<1 year')),
                  DropdownMenuItem(value: '1-2', child: Text('1-2 years')),
                  DropdownMenuItem(value: '3-5', child: Text('3-5 years')),
                  DropdownMenuItem(value: '6-10', child: Text('6-10 years')),
                  DropdownMenuItem(value: '10+', child: Text('10+ years')),
                ],
                onChanged: (value) {
                  draft.yearsExperience = value;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: draft.availability,
                decoration: const InputDecoration(labelText: 'Availability'),
                items: const [
                  DropdownMenuItem(
                      value: 'full_time', child: Text('Full-time')),
                  DropdownMenuItem(
                      value: 'part_time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'weekends', child: Text('Weekends')),
                ],
                onChanged: (value) {
                  draft.availability = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Languages', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: const [
            ('en', 'English'),
            ('lg', 'Luganda'),
            ('sw', 'Kiswahili'),
            ('fr', 'French'),
            ('rw', 'Kinyarwanda'),
            ('ar', 'Arabic'),
          ].map((item) {
            final selected = draft.languages.contains(item.$1);
            return FilterChip(
              label: Text(item.$2),
              selected: selected,
              onSelected: (_) {
                if (selected) {
                  draft.languages.remove(item.$1);
                } else {
                  draft.languages.add(item.$1);
                }
                onChanged();
              },
            );
          }).toList(),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Willing to travel'),
          value: draft.willingToTravel,
          onChanged: (value) {
            draft.willingToTravel = value;
            onChanged();
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: draft.expectedPayAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Expected pay',
                  prefixText: 'UGX ',
                ),
                onChanged: (value) {
                  draft.expectedPayAmount = value.trim();
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: draft.expectedPayPeriod ?? 'day',
                decoration: const InputDecoration(labelText: 'Per'),
                items: const [
                  DropdownMenuItem(value: 'hour', child: Text('hour')),
                  DropdownMenuItem(value: 'day', child: Text('day')),
                  DropdownMenuItem(value: 'week', child: Text('week')),
                  DropdownMenuItem(value: 'month', child: Text('month')),
                  DropdownMenuItem(value: 'project', child: Text('project')),
                ],
                onChanged: (value) {
                  draft.expectedPayPeriod = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Evidence can be uploaded after saving from your service card.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: text2),
        ),
      ],
    );
  }
}

class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.categories,
    required this.scrollController,
    required this.onSelect,
  });

  final List<NeedCategory> categories;
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                        ),
                      ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => widget.onSelect(cat),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CapabilityList extends StatelessWidget {
  const _CapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.scrollController,
    required this.onMarketingTap,
    required this.onToggle,
    required this.iWantJobs,
    required this.onIWantJobsChanged,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final ScrollController scrollController;
  final VoidCallback onMarketingTap;
  final void Function(String) onToggle;
  final bool iWantJobs;
  final ValueChanged<bool> onIWantJobsChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final localeCode = Localizations.localeOf(context).languageCode;

    final l10n = AppLocalizations.of(context)!;

    return ListView(
      controller: scrollController,
      children: [
        for (final cap in capabilities) ...[
          if (cap.slug == _marketingServicesSlug)
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: Text(
                AppLocalizations.of(context)!.marketingAndPromotion,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onMarketingTap,
            )
          else
            Builder(
              builder: (context) {
                final alreadyOwned = existingSlugs.contains(cap.slug);
                final isSelected = selected.contains(cap.slug);

                return ListTile(
                  enabled: !alreadyOwned,
                  leading: alreadyOwned
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggle(cap.slug),
                          activeColor: AppColors.accent,
                        ),
                  title: Text(
                    cap.localizedName(localeCode),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: alreadyOwned ? text2 : null,
                    ),
                  ),
                  onTap: alreadyOwned ? null : () => onToggle(cap.slug),
                );
              },
            ),
          Divider(height: 1, color: border),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.iWantJobs,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.iWantJobsSubtitle,
              style: TextStyle(fontSize: 12, color: text2),
            ),
            value: iWantJobs,
            onChanged: onIWantJobsChanged,
          ),
        ),
      ],
    );
  }
}

class _FinancialCapabilityList extends StatelessWidget {
  const _FinancialCapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.institutionController,
    required this.roleController,
    required this.showProfessionalTag,
    required this.allowInstitutionMatching,
    required this.scrollController,
    required this.onToggle,
    required this.onProfessionalTagChanged,
    required this.onInstitutionMatchingChanged,
    required this.iWantJobs,
    required this.onIWantJobsChanged,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final TextEditingController institutionController;
  final TextEditingController roleController;
  final bool showProfessionalTag;
  final bool allowInstitutionMatching;
  final ScrollController scrollController;
  final void Function(String) onToggle;
  final void Function(bool) onProfessionalTagChanged;
  final void Function(bool) onInstitutionMatchingChanged;
  final bool iWantJobs;
  final ValueChanged<bool> onIWantJobsChanged;

  bool get _hasFinancialSelected =>
      selected.intersection(_financialMetadataSlugs).isNotEmpty ||
      existingSlugs.intersection(_financialMetadataSlugs).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return ListView(
      controller: scrollController,
      children: [
        for (final cap in capabilities)
          Builder(builder: (context) {
            final alreadyOwned = existingSlugs.contains(cap.slug);
            final isSelected = selected.contains(cap.slug);
            final localeCode = Localizations.localeOf(context).languageCode;
            final name = cap.localizedName(localeCode);
            return Column(
              children: [
                ListTile(
                  enabled: !alreadyOwned,
                  leading: alreadyOwned
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggle(cap.slug),
                          activeColor: AppColors.accent,
                        ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: alreadyOwned ? text2 : null,
                    ),
                  ),
                  onTap: alreadyOwned ? null : () => onToggle(cap.slug),
                ),
                Divider(height: 1, color: border),
              ],
            );
          }),
        // Contextual fields shown when any financial capability is selected
        if (_hasFinancialSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.organisationOptional,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.organisationSubtitle,
                  style: TextStyle(fontSize: 12, color: text2),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: institutionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.organisationLabel,
                    hintText: l10n.organisationHint,
                    prefixIcon:
                        const Icon(Icons.account_balance_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.roleOptional,
                    hintText: l10n.roleHint,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.allowSmartMatchingProvider),
                  subtitle: Text(
                    l10n.allowSmartMatchingProviderSubtitle,
                    style: TextStyle(fontSize: 12, color: text2),
                  ),
                  value: allowInstitutionMatching,
                  onChanged: onInstitutionMatchingChanged,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showProfessionalTagProvider),
                  subtitle: Text(
                    l10n.showProfessionalTagProviderSubtitle,
                    style: TextStyle(fontSize: 12, color: text2),
                  ),
                  value: showProfessionalTag,
                  onChanged: onProfessionalTagChanged,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.iWantJobs,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.iWantJobsSubtitle,
              style: TextStyle(fontSize: 12, color: text2),
            ),
            value: iWantJobs,
            onChanged: onIWantJobsChanged,
          ),
        ),
      ],
    );
  }
}

class _MarketingCapabilityList extends StatelessWidget {
  const _MarketingCapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.audiencePlatforms,
    required this.audienceCountController,
    required this.audienceLocationController,
    required this.audienceInterestController,
    required this.scrollController,
    required this.onToggle,
    required this.onPlatformToggle,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final Set<String> audiencePlatforms;
  final TextEditingController audienceCountController;
  final TextEditingController audienceLocationController;
  final TextEditingController audienceInterestController;
  final ScrollController scrollController;
  final void Function(String) onToggle;
  final void Function(String) onPlatformToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final audienceSelected = selected.contains(_audienceCapabilitySlug) ||
        existingSlugs.contains(_audienceCapabilitySlug);
    final platforms = <(String, String)>[
      ('tiktok', l10n.audiencePlatformTikTok),
      ('instagram', l10n.audiencePlatformInstagram),
      ('youtube', l10n.audiencePlatformYouTube),
      ('facebook', l10n.audiencePlatformFacebook),
      ('whatsapp', l10n.audiencePlatformWhatsApp),
      ('other', l10n.audiencePlatformOther),
    ];

    return ListView(
      controller: scrollController,
      children: [
        for (final capability in capabilities)
          Builder(builder: (context) {
            final alreadyOwned = existingSlugs.contains(capability.slug);
            final isSelected = selected.contains(capability.slug);
            final localeCode = Localizations.localeOf(context).languageCode;
            final name = capability.localizedName(localeCode);
            return Column(
              children: [
                ListTile(
                  enabled: !alreadyOwned,
                  leading: alreadyOwned
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggle(capability.slug),
                          activeColor: AppColors.accent,
                        ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: alreadyOwned ? text2 : null,
                    ),
                  ),
                  onTap: alreadyOwned ? null : () => onToggle(capability.slug),
                ),
                Divider(height: 1, color: border),
              ],
            );
          }),
        if (audienceSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: [
                    for (final (slug, label) in platforms)
                      FilterChip(
                        label: Text(label),
                        selected: audiencePlatforms.contains(slug),
                        onSelected: (_) => onPlatformToggle(slug),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
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
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceLocationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.audienceMainLocation,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceInterestController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.audienceMainInterest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
