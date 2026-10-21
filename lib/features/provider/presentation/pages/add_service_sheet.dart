// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_company_profile.dart';
import '../../domain/entities/provider_service_role.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import '../widgets/company_details_step.dart';
import '../widgets/provider_type_sheet.dart';

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

String? _providerSafetyNotice(AppLocalizations l10n, String? slug) =>
    switch (slug) {
      'health_medical' => l10n.providerSafetyMedical,
      'business_investment' => l10n.providerSafetyInvestment,
      'traditional_cultural' => l10n.providerSafetyTraditional,
      'beauty_fashion_styling' => l10n.providerSafetyWellness,
      'education_training' => l10n.providerSafetyAcademic,
      'domestic_household' => l10n.providerSafetyDomestic,
      _ => null,
    };

class ProviderCapabilitySelection {
  const ProviderCapabilitySelection({
    required this.slugs,
    this.metadataBySlug = const {},
    this.openWorkProfile = false,
    this.categorySlug,
    this.workRoles = const [],
    this.workMetadataByRole = const {},
    this.companyPath = false,
    this.roleEvidenceDrafts = const [],
    this.identitySwitchCompleted = false,
  });

  final List<String> slugs;
  final Map<String, Map<String, dynamic>> metadataBySlug;
  final bool openWorkProfile;
  final String? categorySlug;
  final List<String> workRoles;
  final Map<String, Map<String, dynamic>> workMetadataByRole;
  final bool companyPath;
  final List<PendingRoleEvidenceDraft> roleEvidenceDrafts;
  final bool identitySwitchCompleted;
}

class PendingRoleEvidenceDraft {
  const PendingRoleEvidenceDraft({
    required this.roleSlug,
    required this.roleCapabilitySlug,
    required this.qualificationSlug,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String roleSlug;
  final String roleCapabilitySlug;
  final String qualificationSlug;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
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
    this.initialPersonalName,
    required this.needsRepository,
    required this.providerRepository,
    this.capabilityProfilesEnabled = true,
    this.workProfilesEnabled = true,
    this.initialJobsMode = false,
    this.initialProofRoleSlug,
    this.initialCompanyCertification = false,
  });

  final Set<String> existingSlugs;
  final List<ProviderCapability> existingCapabilities;
  final Map<String, dynamic>? existingAudienceMetadata;
  final Map<String, dynamic>? existingFinancialMetadata;
  final String? preselectedCategorySlug;
  final String? initialPersonalName;
  final NeedsRepository needsRepository;
  final IProviderRepository providerRepository;
  final bool capabilityProfilesEnabled;
  final bool workProfilesEnabled;
  final bool initialJobsMode;
  final String? initialProofRoleSlug;
  final bool initialCompanyCertification;

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
    String? initialProofRoleSlug,
    bool initialCompanyCertification = false,
    String? preselectedCategorySlug,
    String? initialPersonalName,
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
              initialPersonalName: initialPersonalName,
              needsRepository: needsRepository,
              providerRepository: providerRepository,
              capabilityProfilesEnabled: capabilityProfilesEnabled,
              workProfilesEnabled: workProfilesEnabled,
              initialJobsMode: initialJobsMode,
              initialProofRoleSlug: initialProofRoleSlug,
              initialCompanyCertification: initialCompanyCertification,
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
  // Steps: 0 category list, 1 category capabilities, 2-3 Individual role details,
  // 4 provider type, 5 Company details and proof.
  int _step = 0;
  NeedCategory? _selectedCategory;
  List<NeedCategory> _categories = [];
  List<NeedCapability> _categoryCapabilities = [];
  List<ProviderServiceRole> _categoryRoles = [];
  final Set<String> _selected = {};

  // Work profile selection state
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
  final List<PendingRoleEvidenceDraft> _roleEvidenceDrafts = [];

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
  ProviderCategoryType? _providerType;
  bool _providerTypeRequired = false;
  bool _categoryWorkProfilesEnabled = false;
  bool _savingProviderType = false;
  String? _providerTypeError;
  ProviderCompanyProfile? _companyProfile;
  List<Map<String, dynamic>> _companyVerificationSubmissions = const [];
  bool _loadingCompanyDetails = false;
  bool _savingCompanyDetails = false;
  bool _allowCompanyExit = false;
  ProviderCategoryType? _savedProviderType;
  Map<String, dynamic> _identityPresentation = {};
  int _pendingIdentityOffers = 0;
  int _activeIdentityCapabilities = 0;
  Map<String, int> _identityActiveCounts = const {};
  bool _representativeAuthorized = false;
  bool _initialProofDestinationOpened = false;
  String _personalDisplayName = '';
  String _companyDisplayName = '';

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
    final slugs = <String>[];
    if (_providerType != ProviderCategoryType.individual) {
      slugs.addAll(_selected);
    }
    final metadataBySlug = <String, Map<String, dynamic>>{};

    if (_selected.contains(_audienceCapabilitySlug)) {
      metadataBySlug[_audienceCapabilitySlug] = {
        ...?metadataBySlug[_audienceCapabilitySlug],
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
          ...?metadataBySlug[slug],
          if (institution.isNotEmpty) 'institution': institution,
          if (role.isNotEmpty) 'role': role,
          'show_professional_tag': _showProfessionalTag,
          'allow_institution_matching': _allowInstitutionMatching,
        };
      }
    }

    final workMetadataByRole = <String, Map<String, dynamic>>{};
    final companyPath = _providerType == ProviderCategoryType.company &&
        widget.initialProofRoleSlug == null;
    final canEditWorkRoles = _categoryWorkProfilesEnabled &&
        (_providerType == ProviderCategoryType.individual ||
            widget.initialProofRoleSlug != null);
    if (canEditWorkRoles) {
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
    } else if (!companyPath) {
      // Keep saved roles intact while the category's role feature is disabled.
      for (final role in _categoryRoles) {
        final capSlug = role.capabilitySlug ?? 'work_${role.slug}';
        if (widget.existingSlugs.contains(capSlug)) slugs.add(capSlug);
      }
      for (final capability in widget.existingCapabilities) {
        if (capability.isWork &&
            capability.categorySlug == _selectedCategory?.slug &&
            !slugs.contains(capability.capabilitySlug)) {
          slugs.add(capability.capabilitySlug);
        }
      }
    }

    return ProviderCapabilitySelection(
      slugs: slugs,
      metadataBySlug: metadataBySlug,
      openWorkProfile: canEditWorkRoles,
      categorySlug: _selectedCategory?.slug,
      workRoles: canEditWorkRoles ? _selectedRoles.toList() : const [],
      workMetadataByRole: workMetadataByRole,
      roleEvidenceDrafts: List.unmodifiable(_roleEvidenceDrafts),
      companyPath: companyPath,
    );
  }

  Future<void> _loadCategories() async {
    final cats = List<NeedCategory>.of(
      await widget.needsRepository.getCategories(),
    );
    if (!mounted) return;
    final mostRecentByCategory = <String, DateTime>{};
    for (final capability in widget.existingCapabilities) {
      final categorySlug = capability.categorySlug ??
          capability.metadata['category_slug']?.toString();
      if (categorySlug == null) continue;
      final updatedAt = capability.updatedAt ?? capability.createdAt;
      final previous = mostRecentByCategory[categorySlug];
      if (previous == null || updatedAt.isAfter(previous)) {
        mostRecentByCategory[categorySlug] = updatedAt;
      }
    }
    if (widget.capabilityProfilesEnabled) {
      try {
        final identities =
            await widget.providerRepository.getMyCategoryIdentityUpdatedAt();
        for (final entry in identities.entries) {
          final previous = mostRecentByCategory[entry.key];
          if (previous == null || entry.value.isAfter(previous)) {
            mostRecentByCategory[entry.key] = entry.value;
          }
        }
      } catch (_) {
        // Keep category browsing available if the identity lookup is offline.
      }
    }
    cats.sort((a, b) {
      final aRecent = mostRecentByCategory[a.slug];
      final bRecent = mostRecentByCategory[b.slug];
      if (aRecent != null && bRecent != null) return bRecent.compareTo(aRecent);
      if (aRecent != null) return -1;
      if (bRecent != null) return 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
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
      _selected.clear();
      _selectedRoles.clear();
      _companyProfile = null;
      _companyVerificationSubmissions = const [];
      _categoryWorkProfilesEnabled = false;
      _selectedCategory = cat;
      _showAudience = false;
      _loading = true;
    });
    final caps =
        await widget.needsRepository.getCapabilities(categorySlug: cat.slug);
    var needsProviderType = false;
    ProviderCategoryType? providerType;
    if (widget.capabilityProfilesEnabled) {
      try {
        needsProviderType =
            await widget.providerRepository.capabilityProfilesEnabled();
        if (needsProviderType) {
          providerType =
              (await widget.providerRepository.getMyCategoryTypes())[cat.slug];
        }
      } catch (_) {
        // Continue to the category sheet if the preference lookup is unavailable.
      }
    }
    Map<String, dynamic> identityInfo = const {};
    if (needsProviderType && providerType != null) {
      try {
        identityInfo =
            await widget.providerRepository.getMyProviderIdentity(cat.slug);
      } catch (_) {
        // Keep the chooser usable if the additive identity RPC is not deployed.
      }
    }
    final savedPresentation = identityInfo['presentation'] is Map
        ? (identityInfo['presentation'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final companyData = identityInfo['company_profile'] is Map
        ? (identityInfo['company_profile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final initialCompanyName = providerType == ProviderCategoryType.company &&
            savedPresentation['display_name']?.toString().trim().isNotEmpty ==
                true
        ? savedPresentation['display_name'].toString()
        : (companyData['company_name']?.toString() ?? '');
    final personalName =
        savedPresentation['display_name']?.toString().trim().isNotEmpty ==
                    true &&
                providerType == ProviderCategoryType.individual
            ? savedPresentation['display_name'].toString()
            : (widget.initialPersonalName ?? '');
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
    final categoryWorkEnabled = widget.workProfilesEnabled &&
        await widget.providerRepository.isCategoryWorkProfileEnabled(cat.slug);
    for (final cap in filteredCaps) {
      if (widget.existingSlugs.contains(cap.slug) &&
          providerType != ProviderCategoryType.individual) {
        _selected.add(cap.slug);
      }
    }
    for (final role in roles) {
      final capSlug = role.capabilitySlug ?? 'work_${role.slug}';
      final existingRole = widget.existingCapabilities
          .where((capability) =>
              capability.isWork && capability.capabilitySlug == capSlug)
          .firstOrNull;
      if (widget.existingSlugs.contains(capSlug) ||
          widget.existingSlugs.contains(role.slug)) {
        _selectedRoles.add(role.slug);
        if (existingRole != null) {
          final metadata = existingRole.metadata;
          _kindsByRole[role.slug] = (metadata['kind_ids'] as List? ?? const [])
              .map((value) => value.toString())
              .toSet();
          _qualificationsByRole[role.slug] =
              (metadata['qualification_ids'] as List? ?? const [])
                  .map((value) => value.toString())
                  .toSet();
          if (metadata['years_experience'] != null) {
            _yearsExperienceByRole[role.slug] =
                metadata['years_experience'].toString();
          }
          if (metadata['availability'] != null) {
            _availabilityByRole[role.slug] =
                metadata['availability'].toString();
          }
          _languagesByRole[role.slug] =
              (metadata['languages'] as List? ?? const ['English'])
                  .map((value) => value.toString())
                  .toSet();
          _willingToTravelByRole[role.slug] =
              metadata['willing_to_travel'] as bool? ?? false;
          final expectedPay = metadata['expected_pay'];
          if (expectedPay is Map) {
            if (expectedPay['amount'] != null) {
              _expectedPayAmountByRole[role.slug] =
                  expectedPay['amount'].toString();
            }
            if (expectedPay['period'] != null) {
              _expectedPayPeriodByRole[role.slug] =
                  expectedPay['period'].toString();
            }
          }
        }
      }
    }

    setState(() {
      _categoryCapabilities = filteredCaps;
      _categoryRoles = roles;
      _providerTypeRequired = needsProviderType;
      _providerType = providerType;
      _savedProviderType = providerType;
      _identityPresentation = {
        'display_mode': savedPresentation['display_mode']?.toString() ??
            (providerType == ProviderCategoryType.individual
                ? 'personal'
                : 'company'),
        'display_name': providerType == ProviderCategoryType.company
            ? initialCompanyName
            : personalName,
        'representative_name':
            savedPresentation['representative_name']?.toString() ??
                (widget.initialPersonalName ?? ''),
        'representative_authorized':
            savedPresentation['representative_authorized'] == true,
      };
      _personalDisplayName = personalName;
      _companyDisplayName = initialCompanyName;
      _representativeAuthorized =
          savedPresentation['representative_authorized'] == true;
      _pendingIdentityOffers =
          int.tryParse(identityInfo['pending_offers']?.toString() ?? '') ?? 0;
      _activeIdentityCapabilities =
          int.tryParse(identityInfo['active_capabilities']?.toString() ?? '') ??
              0;
      _identityActiveCounts = {
        'individual': int.tryParse(
                identityInfo['individual_active_capabilities']?.toString() ??
                    '') ??
            0,
        'company': int.tryParse(
                identityInfo['company_active_capabilities']?.toString() ??
                    '') ??
            0,
      };
      _categoryWorkProfilesEnabled = categoryWorkEnabled;
      _providerTypeError = null;
      _loading = false;
      _step = widget.initialCompanyCertification
          ? 5
          : widget.initialProofRoleSlug != null && _selectedRoles.isNotEmpty
              ? 3
              : needsProviderType
                  ? 4
                  : 1;
      final requestedRoleIndex = widget.initialProofRoleSlug == null
          ? -1
          : _selectedRoles.toList().indexOf(widget.initialProofRoleSlug!);
      if (requestedRoleIndex >= 0) _currentRoleIndex = requestedRoleIndex;
    });
    if (widget.initialCompanyCertification && !_initialProofDestinationOpened) {
      _initialProofDestinationOpened = true;
      await _openCompanyDetails();
    }
  }

  Future<void> _openCatalogResult(Map<String, dynamic> result) async {
    final type = result['result_type']?.toString();
    final slug = result['slug']?.toString() ?? '';
    final categorySlug = result['category_slug']?.toString();
    final category = _categories
        .where(
            (item) => item.slug == (type == 'category' ? slug : categorySlug))
        .firstOrNull;
    if (category == null) return;
    await _selectCategory(category);
    if (!mounted || type == 'category') return;
    setState(() {
      if (type == 'service') {
        _selected.add(slug);
      } else if (type == 'role') {
        _selectedRoles.add(slug.startsWith('work_') ? slug.substring(5) : slug);
      } else if (type == 'kind') {
        final split = slug.split(':');
        if (split.length == 2) {
          _selectedRoles.add(split[0]);
          _kindsByRole.putIfAbsent(split[0], () => {}).add(split[1]);
        }
      }
      if (type == 'service' &&
          _savedProviderType == ProviderCategoryType.individual) {
        _step = 4;
      } else if (!_providerTypeRequired || _savedProviderType != null) {
        _step = 1;
      }
    });
  }

  Future<void> _continueProviderType() async {
    final type = _providerType;
    final slug = _selectedCategory?.slug;
    if (type == null || slug == null || _savingProviderType) return;
    final presentation = <String, dynamic>{
      ..._identityPresentation,
      'representative_authorized': _representativeAuthorized,
    };
    setState(() {
      _savingProviderType = true;
      _providerTypeError = null;
    });
    try {
      if (_savedProviderType != null && _savedProviderType != type) {
        if (type == ProviderCategoryType.company &&
            (presentation['display_name'] as String? ?? '').trim().isEmpty) {
          throw const FormatException('A company name is required.');
        }
        if (presentation['display_mode'] == 'company_with_representative' &&
            (!_representativeAuthorized ||
                (presentation['representative_name'] as String? ?? '')
                    .trim()
                    .isEmpty)) {
          throw const FormatException(
              'Representative authorization is required.');
        }
        setState(() {
          _step = 6;
          _savingProviderType = false;
        });
        return;
      }
      if (_savedProviderType == null) {
        await widget.providerRepository.setCategoryType(slug, type);
      }
      if ((presentation['display_name'] as String? ?? '').trim().isNotEmpty) {
        await widget.providerRepository.saveProviderIdentityPresentation(
          categorySlug: slug,
          type: type,
          presentation: presentation,
        );
      }
      if (mounted) {
        setState(() {
          if (type == ProviderCategoryType.individual) {
            _selected.clear();
          } else {
            for (final cap in _categoryCapabilities) {
              if (widget.existingSlugs.contains(cap.slug)) {
                _selected.add(cap.slug);
              }
            }
          }
          _step = 1;
          _savedProviderType = type;
          _savingProviderType = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      OfflineService().reportRequestFailure(e);
      final offline = parseSupabaseError(e) is NetworkException;
      if (offline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.networkError)),
        );
      } else {
        setState(() => _providerTypeError = userFacingErrorMessage(e));
      }
      setState(() => _savingProviderType = false);
    }
  }

  Future<void> _confirmIdentitySwitch() async {
    final category = _selectedCategory;
    final type = _providerType;
    if (category == null || type == null || _savingProviderType) return;
    setState(() {
      _savingProviderType = true;
      _providerTypeError = null;
    });
    try {
      await widget.providerRepository.switchProviderIdentity(
        categorySlug: category.slug,
        type: type,
        presentation: {
          ..._identityPresentation,
          'representative_authorized': _representativeAuthorized,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(ProviderCapabilitySelection(
        slugs: const [],
        categorySlug: category.slug,
        identitySwitchCompleted: true,
      ));
    } catch (e) {
      if (!mounted) return;
      OfflineService().reportRequestFailure(e);
      setState(() {
        _providerTypeError = userFacingErrorMessage(e);
        _savingProviderType = false;
      });
    }
  }

  Future<void> _openCompanyDetails() async {
    final categorySlug = _selectedCategory?.slug;
    if (categorySlug == null || _loadingCompanyDetails) return;
    setState(() {
      _loadingCompanyDetails = true;
      _providerTypeError = null;
      _step = 5;
    });
    try {
      final submissions = await widget.providerRepository
          .getCompanyVerificationSubmissions(categorySlug);
      ProviderCompanyProfile? profile =
          _companyProfile?.categorySlug == categorySlug
              ? _companyProfile
              : null;
      profile ??=
          await widget.providerRepository.getCompanyProfile(categorySlug);
      if (profile == null) {
        final legacy = widget.existingCapabilities
            .where((capability) => capability.categorySlug == categorySlug)
            .map((capability) => capability.metadata)
            .firstWhere(
              (metadata) =>
                  metadata['organization_name'] != null ||
                  metadata['business_registration'] != null,
              orElse: () => const {},
            );
        if (legacy.isNotEmpty) {
          profile = ProviderCompanyProfile(
            categorySlug: categorySlug,
            companyName: legacy['organization_name']?.toString(),
            registrationNumber: legacy['business_registration']?.toString(),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _companyVerificationSubmissions = submissions;
        _companyProfile = profile;
        _loadingCompanyDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCompanyDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    }
  }

  Future<void> _saveCompanyDetails({
    required Map<String, dynamic> profile,
  }) async {
    final categorySlug = _selectedCategory?.slug;
    if (categorySlug == null || _savingCompanyDetails) return;
    setState(() => _savingCompanyDetails = true);
    try {
      await widget.providerRepository.saveCompanyCategory(
        categorySlug: categorySlug,
        serviceSlugs: _selected.toList(),
        roleCapabilitySlugs: _selectedRoles.map((roleSlug) {
          final role = _categoryRoles.firstWhere(
            (candidate) => candidate.slug == roleSlug,
          );
          return role.capabilitySlug ?? 'work_$roleSlug';
        }).toList(),
        profile: profile,
        evidence: const [],
      );
      final companyName = (profile['company_name'] as String? ?? '').trim();
      if (companyName.isNotEmpty) {
        await widget.providerRepository.saveProviderIdentityPresentation(
          categorySlug: categorySlug,
          type: ProviderCategoryType.company,
          presentation: {
            'display_mode': _identityPresentation['display_mode'] ==
                    'company_with_representative'
                ? 'company_with_representative'
                : 'company',
            'display_name': companyName,
            'representative_name': _identityPresentation['representative_name'],
            'representative_authorized': _representativeAuthorized,
          },
        );
      }
      if (mounted) {
        setState(() => _allowCompanyExit = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop(_selection());
        });
      }
    } finally {
      if (mounted) setState(() => _savingCompanyDetails = false);
    }
  }

  void _openAudience() {
    setState(() => _showAudience = true);
  }

  void _goBack() {
    setState(() {
      if (_step == 3) {
        _step = 2;
      } else if (_step == 5) {
        _step = 1;
      } else if (_step == 7) {
        _step = 6;
        _providerTypeError = null;
      } else if (_step == 6) {
        _step = 4;
        _providerTypeError = null;
      } else if (_step == 2) {
        if (_currentRoleIndex > 0) {
          _currentRoleIndex--;
        } else {
          _step = 1;
        }
      } else if (_showAudience) {
        _showAudience = false;
      } else if (_step == 1 && _providerTypeRequired) {
        _step = 4;
      } else if (_step == 4) {
        _step = 0;
        _selectedCategory = null;
        _providerType = null;
      } else {
        _step = 0;
      }
    });
  }

  bool get _hasUnsavedCompanyDraft {
    if (_providerType != ProviderCategoryType.company) return false;
    if (_step == 5) return true;
    if (_step != 1) return false;
    final existingServices = _categoryCapabilities
        .where((capability) => widget.existingSlugs.contains(capability.slug))
        .map((capability) => capability.slug)
        .toSet();
    final existingRoles = _categoryRoles
        .where((role) => widget.existingSlugs
            .contains(role.capabilitySlug ?? 'work_${role.slug}'))
        .map((role) => role.slug)
        .toSet();
    return !_sameSet(existingServices, _selected) ||
        !_sameSet(existingRoles, _selectedRoles);
  }

  static bool _sameSet(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  Future<void> _confirmCompanyExit() async {
    final l10n = AppLocalizations.of(context)!;
    final continueToDetails = _step == 1;
    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.companyLeaveTitle),
        content: Text(continueToDetails
            ? l10n.companyLeaveSelectionsMessage
            : l10n.companyLeaveDetailsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.companyLeaveKeepEditing),
          ),
          if (continueToDetails)
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(l10n.providerTypeNextCompanyDetails),
            ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.companyLeaveDiscard),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (discard == true) {
      setState(() => _allowCompanyExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (discard == null && continueToDetails) {
      await _openCompanyDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return PopScope<Object?>(
      canPop: !_hasUnsavedCompanyDraft || _allowCompanyExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasUnsavedCompanyDraft) _confirmCompanyExit();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                        IconButton(
                          onPressed: _goBack,
                          constraints:
                              const BoxConstraints(minWidth: 44, minHeight: 44),
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.arrow_back_rounded,
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
                      if (_step == 0)
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
                              onSearch: (query) =>
                                  widget.needsRepository.searchProviderCatalog(
                                query,
                                localeCode: Localizations.localeOf(context)
                                    .languageCode,
                              ),
                              onRequest:
                                  widget.needsRepository.requestCatalogItem,
                              onCatalogResult: _openCatalogResult,
                            )
                          : _step == 4
                              ? _ProviderTypeStep(
                                  selected: _providerType,
                                  saving: _savingProviderType,
                                  error: _providerTypeError,
                                  initialDisplayName:
                                      _identityPresentation['display_name']
                                              ?.toString() ??
                                          (widget.initialPersonalName ?? ''),
                                  initialRepresentativeName:
                                      _identityPresentation[
                                                  'representative_name']
                                              ?.toString() ??
                                          (widget.initialPersonalName ?? ''),
                                  initialDisplayMode:
                                      _identityPresentation['display_mode']
                                              ?.toString() ??
                                          'personal',
                                  representativeAuthorized:
                                      _representativeAuthorized,
                                  isCurrent:
                                      _savedProviderType == _providerType,
                                  requireCompanyName:
                                      _savedProviderType != null &&
                                          _savedProviderType != _providerType &&
                                          _providerType ==
                                              ProviderCategoryType.company,
                                  onPresentationChanged: (value) =>
                                      setState(() {
                                    _identityPresentation = value;
                                    _representativeAuthorized =
                                        value['representative_authorized'] ==
                                            true;
                                  }),
                                  onSelect: (value) => setState(() {
                                    _providerType = value;
                                    _activeIdentityCapabilities =
                                        _identityActiveCounts[value.name] ?? 0;
                                    _providerTypeError = null;
                                    _identityPresentation = {
                                      ..._identityPresentation,
                                      'display_mode': value ==
                                              ProviderCategoryType.individual
                                          ? 'personal'
                                          : (_identityPresentation[
                                                      'display_mode'] ==
                                                  'company_with_representative'
                                              ? 'company_with_representative'
                                              : 'company'),
                                      'display_name': value ==
                                              ProviderCategoryType.individual
                                          ? _personalDisplayName
                                          : _companyDisplayName,
                                    };
                                  }),
                                  onContinue: _continueProviderType,
                                )
                              : _step == 6
                                  ? _IdentitySwitchConfirmStep(
                                      from: _savedProviderType!,
                                      to: _providerType!,
                                      pendingOffers: _pendingIdentityOffers,
                                      onContinue: () =>
                                          setState(() => _step = 7),
                                      onCancel: _goBack,
                                    )
                                  : _step == 7
                                      ? _IdentitySwitchReviewStep(
                                          categoryName: _selectedCategory
                                                  ?.localizedName(localeCode) ??
                                              '',
                                          from: _savedProviderType!,
                                          to: _providerType!,
                                          presentation: _identityPresentation,
                                          pendingOffers: _pendingIdentityOffers,
                                          activeCapabilities:
                                              _activeIdentityCapabilities,
                                          error: _providerTypeError,
                                          saving: _savingProviderType,
                                          onBack: _goBack,
                                          onConfirm: _confirmIdentitySwitch,
                                        )
                                      : _step == 5
                                          ? CompanyDetailsStep(
                                              categorySlug:
                                                  _selectedCategory?.slug ?? '',
                                              serviceCount: _selected.length,
                                              roleCount: _selectedRoles.length,
                                              initialProfile: _companyProfile,
                                              verificationSubmissions:
                                                  _companyVerificationSubmissions,
                                              providerRepository:
                                                  widget.providerRepository,
                                              onDraftChanged: (profile) =>
                                                  setState(() =>
                                                      _companyProfile =
                                                          profile),
                                              onSave: _saveCompanyDetails,
                                            )
                                          : _step == 2
                                              ? _KindStepView(
                                                  categorySlug:
                                                      _selectedCategory?.slug,
                                                  role:
                                                      _categoryRoles.firstWhere(
                                                    (r) =>
                                                        r.slug ==
                                                        _selectedRoles.elementAt(
                                                            _currentRoleIndex),
                                                    orElse: () =>
                                                        _categoryRoles.first,
                                                  ),
                                                  roleIndex: _currentRoleIndex,
                                                  totalRoles:
                                                      _selectedRoles.length,
                                                  selectedKinds:
                                                      _kindsByRole.putIfAbsent(
                                                    _selectedRoles.elementAt(
                                                        _currentRoleIndex),
                                                    () => {},
                                                  ),
                                                  scrollController:
                                                      scrollController,
                                                  onNext: () {
                                                    if (_currentRoleIndex <
                                                        _selectedRoles.length -
                                                            1) {
                                                      setState(() =>
                                                          _currentRoleIndex++);
                                                    } else {
                                                      setState(() => _step = 3);
                                                    }
                                                  },
                                                )
                                              : _step == 3
                                                  ? _QualificationsStepView(
                                                      roles: _categoryRoles
                                                          .where((r) =>
                                                              _selectedRoles
                                                                  .contains(
                                                                      r.slug))
                                                          .toList(),
                                                      qualificationsByRole:
                                                          _qualificationsByRole,
                                                      yearsExperienceByRole:
                                                          _yearsExperienceByRole,
                                                      availabilityByRole:
                                                          _availabilityByRole,
                                                      languagesByRole:
                                                          _languagesByRole,
                                                      willingToTravelByRole:
                                                          _willingToTravelByRole,
                                                      expectedPayAmountByRole:
                                                          _expectedPayAmountByRole,
                                                      expectedPayPeriodByRole:
                                                          _expectedPayPeriodByRole,
                                                      evidenceDrafts:
                                                          _roleEvidenceDrafts,
                                                      scrollController:
                                                          scrollController,
                                                      onSave: () =>
                                                          Navigator.of(context)
                                                              .pop(
                                                                  _selection()),
                                                    )
                                                  : _showAudience
                                                      ? _AudienceEditorView(
                                                          audiencePlatforms:
                                                              _audiencePlatforms,
                                                          audienceCountController:
                                                              _audienceCountController,
                                                          audienceLocationController:
                                                              _audienceLocationController,
                                                          audienceInterestController:
                                                              _audienceInterestController,
                                                          scrollController:
                                                              scrollController,
                                                          onPlatformToggle:
                                                              (platform) =>
                                                                  setState(() {
                                                            if (_audiencePlatforms
                                                                .contains(
                                                                    platform)) {
                                                              _audiencePlatforms
                                                                  .remove(
                                                                      platform);
                                                            } else {
                                                              _audiencePlatforms
                                                                  .add(
                                                                      platform);
                                                            }
                                                          }),
                                                          onDone: () =>
                                                              setState(() =>
                                                                  _showAudience =
                                                                      false),
                                                        )
                                                      : _CategoryCapabilitiesView(
                                                          categorySlug:
                                                              _selectedCategory
                                                                  ?.slug,
                                                          capabilities:
                                                              _categoryCapabilities,
                                                          roles: _categoryRoles,
                                                          existingSlugs: widget
                                                              .existingSlugs,
                                                          selected: _selected,
                                                          selectedRoles:
                                                              _selectedRoles,
                                                          iWantJobs:
                                                              _categoryWorkProfilesEnabled,
                                                          companyType:
                                                              _providerType !=
                                                                  ProviderCategoryType
                                                                      .individual,
                                                          providerType:
                                                              _providerType,
                                                          scrollController:
                                                              scrollController,
                                                          onToggleCapability:
                                                              (slug) {
                                                            setState(() {
                                                              if (_selected
                                                                  .contains(
                                                                      slug)) {
                                                                _selected
                                                                    .remove(
                                                                        slug);
                                                              } else {
                                                                _selected
                                                                    .add(slug);
                                                              }
                                                            });
                                                          },
                                                          onToggleRole: (slug) {
                                                            setState(() {
                                                              if (_selectedRoles
                                                                  .contains(
                                                                      slug)) {
                                                                _selectedRoles
                                                                    .remove(
                                                                        slug);
                                                              } else {
                                                                _selectedRoles
                                                                    .add(slug);
                                                              }
                                                            });
                                                          },
                                                          onChangeProviderType:
                                                              () => setState(
                                                                  () => _step =
                                                                      4),
                                                          onSaveServices:
                                                              _openCompanyDetails,
                                                          onNextKind: () {
                                                            setState(() {
                                                              _step = 2;
                                                              _currentRoleIndex =
                                                                  0;
                                                            });
                                                          },
                                                          onAudienceTap:
                                                              _openAudience,
                                                          audiencePlatforms:
                                                              _audiencePlatforms,
                                                          audienceFollowersCount:
                                                              int.tryParse(
                                                                  _audienceCountController
                                                                      .text
                                                                      .trim()),
                                                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProviderTypeStep extends StatefulWidget {
  const _ProviderTypeStep({
    required this.selected,
    required this.saving,
    required this.error,
    required this.onSelect,
    required this.onContinue,
    required this.initialDisplayName,
    required this.initialRepresentativeName,
    required this.initialDisplayMode,
    required this.representativeAuthorized,
    required this.isCurrent,
    required this.requireCompanyName,
    required this.onPresentationChanged,
  });

  final ProviderCategoryType? selected;
  final bool saving;
  final String? error;
  final ValueChanged<ProviderCategoryType> onSelect;
  final VoidCallback onContinue;
  final String initialDisplayName;
  final String initialRepresentativeName;
  final String initialDisplayMode;
  final bool representativeAuthorized;
  final bool isCurrent;
  final bool requireCompanyName;
  final ValueChanged<Map<String, dynamic>> onPresentationChanged;

  @override
  State<_ProviderTypeStep> createState() => _ProviderTypeStepState();
}

class _ProviderTypeStepState extends State<_ProviderTypeStep> {
  late final TextEditingController _displayName;
  late final TextEditingController _representativeName;
  late String _displayMode;
  late bool _authorized;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.initialDisplayName);
    _representativeName =
        TextEditingController(text: widget.initialRepresentativeName);
    _displayMode = widget.initialDisplayMode;
    _authorized = widget.representativeAuthorized;
  }

  void _notify() => widget.onPresentationChanged({
        'display_mode': widget.selected == ProviderCategoryType.individual
            ? 'personal'
            : _displayMode,
        'display_name': _displayName.text.trim(),
        'representative_name': _representativeName.text.trim(),
        'representative_authorized': _authorized,
      });

  bool get _presentationIsValid {
    if (widget.selected == null) return false;
    if (widget.selected == ProviderCategoryType.company &&
        _displayMode == 'company_with_representative') {
      if (_representativeName.text.trim().isEmpty || !_authorized) return false;
    }
    if (widget.selected == ProviderCategoryType.company &&
        !widget.requireCompanyName &&
        _displayName.text.trim().isEmpty) {
      return true;
    }
    if (_displayName.text.trim().isEmpty &&
        widget.selected == ProviderCategoryType.individual) {
      return true;
    }
    if (_displayName.text.trim().isEmpty) return false;
    return true;
  }

  @override
  void didUpdateWidget(covariant _ProviderTypeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _displayName.text = widget.initialDisplayName;
      _representativeName.text = widget.initialRepresentativeName;
      _displayMode = widget.initialDisplayMode;
      _authorized = widget.representativeAuthorized;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _representativeName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(l10n.providerTypeOffering,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.providerTypeTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.providerTypeSubtitle),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.providerTypeTitle,
          child: Column(children: [
            ProviderTypeCard(
                type: ProviderCategoryType.individual,
                title: l10n.providerTypeIndividual,
                description: l10n.providerTypeIndividualDesc,
                selected: widget.selected == ProviderCategoryType.individual,
                isCurrent: widget.isCurrent &&
                    widget.selected == ProviderCategoryType.individual,
                currentLabel: l10n.providerIdentityCurrent,
                onTap: () => widget.onSelect(ProviderCategoryType.individual)),
            const SizedBox(height: 10),
            ProviderTypeCard(
                type: ProviderCategoryType.company,
                title: l10n.providerTypeCompany,
                description: l10n.providerTypeCompanyDesc,
                selected: widget.selected == ProviderCategoryType.company,
                isCurrent: widget.isCurrent &&
                    widget.selected == ProviderCategoryType.company,
                currentLabel: l10n.providerIdentityCurrent,
                onTap: () => widget.onSelect(ProviderCategoryType.company)),
          ]),
        ),
        if (widget.selected != null) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.providerIdentityDisplayHeading,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _displayName,
            onChanged: (_) {
              setState(() {});
              _notify();
            },
            maxLength: 80,
            decoration: InputDecoration(
              labelText: widget.selected == ProviderCategoryType.company
                  ? l10n.providerIdentityCompanyName
                  : l10n.providerIdentityDisplayName,
              border: const OutlineInputBorder(),
            ),
          ),
          if (widget.selected == ProviderCategoryType.company) ...[
            RadioGroup<String>(
              groupValue: _displayMode,
              onChanged: (value) {
                setState(() => _displayMode = value ?? 'company');
                _notify();
              },
              child: Column(children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'company',
                  title: Text(l10n.providerIdentityCompanyOnly),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'company_with_representative',
                  title: Text(l10n.providerIdentityCompanyRepresentative),
                ),
              ]),
            ),
            if (_displayMode == 'company_with_representative') ...[
              TextFormField(
                controller: _representativeName,
                onChanged: (_) {
                  setState(() {});
                  _notify();
                },
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n.providerIdentityRepresentativeName,
                  border: const OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _authorized,
                title: Text(l10n.providerIdentityAuthority),
                onChanged: (value) {
                  setState(() => _authorized = value ?? false);
                  _notify();
                },
              ),
            ],
          ],
          if (_displayName.text.trim().isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(_displayName.text.trim()),
                subtitle: widget.selected == ProviderCategoryType.company &&
                        _displayMode == 'company_with_representative' &&
                        _representativeName.text.trim().isNotEmpty
                    ? Text(l10n.providerIdentityRepresentedBy(
                        _representativeName.text.trim()))
                    : null,
              ),
            ),
        ],
        const SizedBox(height: 14),
        Text(l10n.providerTypeNotVerification,
            style: Theme.of(context).textTheme.bodySmall),
        if (widget.error != null) ...[
          const SizedBox(height: 12),
          Text(widget.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextButton.icon(
              onPressed: widget.saving ? null : widget.onContinue,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry)),
        ],
      ])),
      SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.selected == null ||
                                !_presentationIsValid ||
                                widget.saving
                            ? null
                            : widget.onContinue,
                        child: widget.saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(l10n.btnContinue))),
                if (widget.selected == null)
                  Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(l10n.providerTypeChooseOne,
                          style: Theme.of(context).textTheme.bodySmall)),
                if (widget.selected != null && !_presentationIsValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l10n.providerIdentityRequiredInfo,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error)),
                  ),
              ]))),
    ]);
  }
}

class _IdentitySwitchConfirmStep extends StatelessWidget {
  const _IdentitySwitchConfirmStep({
    required this.from,
    required this.to,
    required this.pendingOffers,
    required this.onContinue,
    required this.onCancel,
  });

  final ProviderCategoryType from;
  final ProviderCategoryType to;
  final int pendingOffers;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toName = to == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final fromName = from == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final notes = <String>[
      l10n.providerIdentityDataKept,
      l10n.providerIdentityOldServicesInactive(fromName),
      l10n.providerIdentityNewOffers(toName),
      l10n.providerIdentityVerificationReset,
      l10n.providerIdentityHistoryKept,
      if (pendingOffers > 0) l10n.providerIdentityPendingOffers(pendingOffers),
    ];
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l10n.providerIdentitySwitchTitle(toName),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(l10n.providerIdentitySwitchBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 20),
          for (var i = 0; i < notes.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      i == notes.length - 1 && pendingOffers > 0
                          ? Icons.pending_actions_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: i == notes.length - 1 && pendingOffers > 0
                          ? colors.tertiary
                          : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(notes[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                            )),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onContinue,
                    child: Text(l10n.btnContinue))),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onCancel,
                child: Text(l10n.cancel),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _IdentitySwitchReviewStep extends StatelessWidget {
  const _IdentitySwitchReviewStep({
    required this.categoryName,
    required this.from,
    required this.to,
    required this.presentation,
    required this.pendingOffers,
    required this.activeCapabilities,
    required this.error,
    required this.saving,
    required this.onBack,
    required this.onConfirm,
  });

  final String categoryName;
  final ProviderCategoryType from;
  final ProviderCategoryType to;
  final Map<String, dynamic> presentation;
  final int pendingOffers;
  final int activeCapabilities;
  final String? error;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final fromName = from == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final toName = to == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final displayName = (presentation['display_name'] as String? ?? '').trim();
    final rep = (presentation['representative_name'] as String? ?? '').trim();
    final withRep = to == ProviderCategoryType.company &&
        presentation['display_mode'] == 'company_with_representative' &&
        rep.isNotEmpty;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l10n.providerIdentityReviewTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _IdentityReviewRow(
              label: l10n.providerIdentityCategory, value: categoryName),
          _IdentityReviewRow(
              label: l10n.providerIdentityNewIdentity,
              value: '$toName (was $fromName)'),
          _IdentityReviewRow(
            label: l10n.providerIdentityPublicName,
            value: withRep
                ? '$displayName\n${l10n.providerIdentityRepresentedBy(rep)}'
                : displayName,
          ),
          const SizedBox(height: 16),
          Text(l10n.providerIdentityReused,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.primary)),
          ListTile(
              dense: true,
              leading: const Icon(Icons.check),
              title: Text(l10n.providerIdentityDataKept)),
          const SizedBox(height: 8),
          Text(l10n.providerIdentityNeedsAttention,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.primary)),
          ListTile(
              dense: true,
              leading: const Icon(Icons.pending_actions),
              title: Text(l10n.providerIdentityCompanyVerificationStatus)),
          if (pendingOffers > 0)
            ListTile(
                dense: true,
                leading: const Icon(Icons.mark_email_unread_outlined),
                title: Text(l10n.providerIdentityPendingOffers(pendingOffers))),
          if (activeCapabilities == 0)
            ListTile(
                dense: true,
                leading: Icon(Icons.info_outline, color: colors.tertiary),
                title: Text(l10n.providerIdentityNoActiveWarning)),
          const SizedBox(height: 8),
          Text(l10n.providerIdentityOldServicesInactive(fromName)),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: colors.error)),
            TextButton.icon(
                onPressed: saving ? null : onConfirm,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry)),
          ],
        ]),
      ),
      SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : onConfirm,
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.providerIdentityConfirm))),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : onBack,
                  child: Text(l10n.btnBack),
                ),
              ),
            ]),
          )),
    ]);
  }
}

class _IdentityReviewRow extends StatelessWidget {
  const _IdentityReviewRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
        ]),
      );
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
    required this.onSearch,
    required this.onRequest,
    required this.onCatalogResult,
  });

  final List<NeedCategory> categories;
  final List<ProviderCapability> existingCapabilities;
  final ScrollController scrollController;
  final void Function(NeedCategory) onSelect;
  final Future<List<Map<String, dynamic>>> Function(String) onSearch;
  final Future<void> Function(String) onRequest;
  final Future<void> Function(Map<String, dynamic>) onCatalogResult;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Future<List<Map<String, dynamic>>>? _results;
  bool _requesting = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
              hintText: l10n.searchCatalog,
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
            onChanged: (val) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                if (!mounted) return;
                setState(() {
                  _searchQuery = val;
                  _results =
                      val.trim().isEmpty ? null : widget.onSearch(val.trim());
                });
              });
            },
          ),
        ),
        Expanded(
          child: _searchQuery.trim().isNotEmpty
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _results,
                  builder: (context, snapshot) {
                    final results = snapshot.data ?? const [];
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.catalogNoMatch),
                            TextButton(
                              onPressed: _requesting
                                  ? null
                                  : () async {
                                      setState(() => _requesting = true);
                                      try {
                                        await widget.onRequest(_searchQuery);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  l10n.catalogRequestSubmitted),
                                            ),
                                          );
                                        }
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  userFacingErrorMessage(
                                                      error)),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _requesting = false);
                                        }
                                      }
                                    },
                              child: Text(l10n.requestService),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: border),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final type = result['result_type']?.toString() ?? '';
                        final title = type.isEmpty
                            ? ''
                            : '${type[0].toUpperCase()}${type.substring(1)}';
                        return ListTile(
                          title: Text(result['localized_label']?.toString() ??
                              result['label']?.toString() ??
                              ''),
                          subtitle: Text(
                              '$title · ${result['localized_parent_category'] ?? result['parent_category'] ?? ''}'),
                          onTap: () => widget.onCatalogResult(result),
                        );
                      },
                    );
                  },
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: border),
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
                        child: Text(cat.icon,
                            style: const TextStyle(fontSize: 20)),
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
// Category capability selection for provider services and work roles.
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
    required this.companyType,
    required this.providerType,
    required this.scrollController,
    required this.onToggleCapability,
    required this.onToggleRole,
    required this.onChangeProviderType,
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
  final bool companyType;
  final ProviderCategoryType? providerType;
  final ScrollController scrollController;
  final ValueChanged<String> onToggleCapability;
  final ValueChanged<String> onToggleRole;
  final VoidCallback onChangeProviderType;
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
    final l10n = AppLocalizations.of(context)!;

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

    final individualType = providerType == ProviderCategoryType.individual;
    final companyMode = providerType == ProviderCategoryType.company;
    final showRoles = iWantJobs && individualType;
    final hasServices = companyType && selected.isNotEmpty;
    final hasRoles = showRoles && selectedRoles.isNotEmpty;

    return Stack(
      children: [
        ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            if (_providerSafetyNotice(l10n, categorySlug)
                case final String notice)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Provider type is category scoped and can be changed from C/D.
            if (providerType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                      '${l10n.providerTypeOfferingAs}  ${companyType ? l10n.providerTypeCompany : l10n.providerTypeIndividual}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  TextButton(
                      onPressed: onChangeProviderType,
                      child: Text(l10n.providerTypeChange)),
                ]),
              ),

            // ── Service capability rows (grouped, flat list style) ──
            if (companyType)
              Row(children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ]),
            if (companyType) const SizedBox(height: 12),
            if (companyType)
              Text(
                l10n.providerTypeStepOneOfTwo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.accent,
                ),
              ),
            if (companyType) const SizedBox(height: 8),
            if (companyType)
              Text(
                l10n.providerTypeWhatWeOffer,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            if (companyType) const SizedBox(height: 4),
            if (companyType)
              Text(l10n.providerTypeCompanyServicesHint,
                  style: TextStyle(fontSize: 12, color: text2)),
            if (companyType) const SizedBox(height: 10),

            if (companyType)
              for (final (groupSlug, groupName, caps) in orderedGroups) ...[
                if (groupName != null && groupName.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 14, 2, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(groupName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    letterSpacing: 0.2,
                                  )),
                        ),
                        Text(
                          l10n.providerTypeGroupCount(
                            caps
                                .where((cap) => selected.contains(cap.slug))
                                .length,
                            caps.length,
                          ),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: text2,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ] else if (groupSlug == null && orderedGroups.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 14, 2, 4),
                    child: Text(
                      l10n.providerTypeOtherGroup,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                ],
                if (companyMode)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var index = 0; index < caps.length; index++)
                          _CapabilityRow(
                            cap: caps[index],
                            localeCode: localeCode,
                            isSelected: selected.contains(caps[index].slug),
                            alreadyOwned: false,
                            border: border,
                            text2: text2,
                            companyStyle: true,
                            showDivider: index < caps.length - 1,
                            onTap: () {
                              final slug = caps[index].slug;
                              if (slug == _audienceCapabilitySlug) {
                                if (!selected.contains(slug)) {
                                  onToggleCapability(slug);
                                }
                                onAudienceTap?.call();
                              } else {
                                onToggleCapability(slug);
                              }
                            },
                            audiencePlatforms:
                                caps[index].slug == _audienceCapabilitySlug
                                    ? audiencePlatforms
                                    : null,
                            audienceFollowersCount:
                                caps[index].slug == _audienceCapabilitySlug
                                    ? audienceFollowersCount
                                    : null,
                          ),
                      ],
                    ),
                  )
                else
                  for (final cap in caps)
                    _CapabilityRow(
                      cap: cap,
                      localeCode: localeCode,
                      isSelected: selected.contains(cap.slug),
                      alreadyOwned: existingSlugs.contains(cap.slug),
                      border: border,
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
                      audienceFollowersCount:
                          cap.slug == _audienceCapabilitySlug
                              ? audienceFollowersCount
                              : null,
                    ),
              ],

            // ── Jobs: role selection ───────────────────────────────
            if (showRoles) ...[
              const SizedBox(height: 16),
              if (individualType)
                Text(
                  l10n.providerTypeStepOneOfThree,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: text2,
                  ),
                ),
              if (companyMode) const Divider(height: 24),
              if (companyMode)
                Text(l10n.providerTypeCompanyRolesHint,
                    style: TextStyle(fontSize: 12, color: text2)),
              const SizedBox(height: 8),
              Text(
                l10n.providerTypeWhatRoles,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                companyMode
                    ? l10n.providerTypeCompanyRolesSubtitle
                    : l10n.providerTypePickRoles,
                style: TextStyle(fontSize: 12, color: text2),
              ),
              const SizedBox(height: 12),
              if (roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      l10n.providerTypeNoRolesConfigured,
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
          bottom: 8,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                individualType
                    ? l10n.rolesCount(showRoles ? selectedRoles.length : 0)
                    : companyMode
                        ? l10n.servicesCount(selected.length)
                        : l10n.servicesCount(selected.length),
                style: TextStyle(fontSize: 11, color: text2)),
            const SizedBox(height: 8),
            if (individualType)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.proPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.proPurple.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: hasRoles ? onNextKind : null,
                child: Text(
                  hasRoles
                      ? l10n.providerTypeNextKind
                      : l10n.selectAtLeastOneRole,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              )
            else if (companyMode)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: hasServices || hasRoles ? onSaveServices : null,
                child: Text(l10n.providerTypeNextCompanyDetails,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: hasServices ? onSaveServices : null,
                child: Text(
                  hasServices
                      ? l10n.btnContinue
                      : l10n.providerTypeSelectService,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets for the category capabilities view
// ---------------------------------------------------------------------------

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.cap,
    required this.localeCode,
    required this.isSelected,
    required this.alreadyOwned,
    required this.border,
    required this.text2,
    required this.onTap,
    this.companyStyle = false,
    this.showDivider = true,
    this.audiencePlatforms,
    this.audienceFollowersCount,
  });

  final NeedCapability cap;
  final String localeCode;
  final bool isSelected;
  final bool alreadyOwned;
  final Color border;
  final Color text2;
  final VoidCallback onTap;
  final bool companyStyle;
  final bool showDivider;
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

    final theme = Theme.of(context);
    final selectedBackground = theme.colorScheme.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.09,
    );
    final checkColor = isSelected ? theme.colorScheme.primary : border;

    return Column(
      children: [
        Material(
          color: companyStyle && isSelected
              ? selectedBackground
              : Colors.transparent,
          child: InkWell(
            onTap: alreadyOwned ? null : onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: companyStyle ? 8 : 2,
                vertical: companyStyle ? 9 : 12,
              ),
              child: Row(
                children: [
                  // Square checkbox
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
                          color: isSelected ? accentColor : checkColor,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cap.localizedName(localeCode),
                          style: TextStyle(
                            fontWeight: isSelected && companyStyle
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: companyStyle ? 12 : 14,
                            color: alreadyOwned ? text2 : null,
                          ),
                        ),
                        if (companyStyle &&
                            cap.verificationPolicy == 'required_proof') ...[
                          const SizedBox(height: 3),
                          Text(
                            AppLocalizations.of(context)!
                                .providerPolicyNeedsProofTag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: border.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}

/// A card item for a work / job role (matches Image D).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : (isDark ? AppColors.bg3Dark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
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
            const SizedBox(width: 12),
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
    );
  }
}

/// Selectable chip for kind/machine/trade selection (matches Image E).
/// Purple border and light purple fill when selected, outlined when not.
class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = AppColors.proPurple;
    final unselectedBg = isDark ? AppColors.bg3Dark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? purple.withValues(alpha: 0.1) : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? purple : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: purple),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selected ? purple : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
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
      'events_celebrations' ||
      'events_production' =>
        'The question changes with the role. An Event Planner is asked "What events?" and an MC/DJ is asked "Which role?"',
      'photo_video_talent' ||
      'photo_video_music_talent' =>
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
                  _KindChip(
                    label: kind.name,
                    selected: widget.selectedKinds.contains(kind.slug),
                    onTap: () {
                      setState(() {
                        if (widget.selectedKinds.contains(kind.slug)) {
                          widget.selectedKinds.remove(kind.slug);
                        } else {
                          widget.selectedKinds.add(kind.slug);
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
    required this.evidenceDrafts,
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
  final List<PendingRoleEvidenceDraft> evidenceDrafts;
  final ScrollController scrollController;
  final VoidCallback onSave;

  @override
  State<_QualificationsStepView> createState() =>
      _QualificationsStepViewState();
}

class _QualificationsStepViewState extends State<_QualificationsStepView> {
  final _amountController = TextEditingController();

  final _experienceOptions = ['Under 1', '1-2', '2-5', '0-10', '10+'];
  final _availabilityOptions = [
    'Full-time',
    'Part-time',
    'Contract / project',
    'Weekends only'
  ];
  final _languageOptions = [
    'English',
    'Swahili',
    'Luganda',
    'French',
    'Arabic'
  ];
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

  String _proofKey(String roleSlug, String qualificationSlug) =>
      '$roleSlug::$qualificationSlug';

  Future<void> _pickQualificationEvidence() async {
    final evidenceQualifications =
        <(ProviderServiceRole, ProviderRoleQualification)>[];
    for (final role in widget.roles) {
      final checked =
          widget.qualificationsByRole[role.slug] ?? const <String>{};
      for (final qualification in role.qualifications) {
        if (qualification.isEvidence && checked.contains(qualification.slug)) {
          evidenceQualifications.add((role, qualification));
        }
      }
    }
    if (evidenceQualifications.isEmpty) {
      for (final role in widget.roles) {
        for (final qualification in role.qualifications) {
          if (qualification.isEvidence) {
            evidenceQualifications.add((role, qualification));
          }
        }
      }
    }
    if (evidenceQualifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'There are no proof-enabled qualifications for these roles.')),
      );
      return;
    }

    final selectedProof = evidenceQualifications.length == 1
        ? evidenceQualifications.single
        : await showDialog<(ProviderServiceRole, ProviderRoleQualification)>(
            context: context,
            builder: (dialogContext) => SimpleDialog(
              title: const Text('What does this file prove?'),
              children: [
                for (final item in evidenceQualifications)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, item),
                    child: Text('${item.$1.name} · ${item.$2.name}'),
                  ),
              ],
            ),
          );
    if (selectedProof == null || !mounted) return;
    final (role, qualification) = selectedProof;

    try {
      const evidenceFiles = XTypeGroup(
        label: 'Licence or certificate',
        extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [evidenceFiles]);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw const FormatException('Choose a file no larger than 5 MB.');
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        _ => '',
      };
      if (mimeType.isEmpty) {
        throw const FormatException('Choose a JPG, PNG, or PDF file.');
      }
      final key = _proofKey(role.slug, qualification.slug);
      final index = widget.evidenceDrafts.indexWhere(
        (draft) => _proofKey(draft.roleSlug, draft.qualificationSlug) == key,
      );
      final draft = PendingRoleEvidenceDraft(
        roleSlug: role.slug,
        roleCapabilitySlug: role.capabilitySlug ?? 'work_${role.slug}',
        qualificationSlug: qualification.slug,
        fileName: file.name,
        mimeType: mimeType,
        bytes: bytes,
      );
      setState(() {
        if (index == -1) {
          widget.evidenceDrafts.add(draft);
        } else {
          widget.evidenceDrafts[index] = draft;
        }
        widget.qualificationsByRole
            .putIfAbsent(role.slug, () => {})
            .add(qualification.slug);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(error.toString().replaceFirst('FormatException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text2 =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
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

            // Qualifications checkboxes per role (flat list with dividers matching Image F)
            for (final role in widget.roles) ...[
              if (widget.roles.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    role.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
              for (final qual in role.qualifications)
                Builder(builder: (ctx) {
                  final roleQuals = widget.qualificationsByRole
                      .putIfAbsent(role.slug, () => {});
                  final isChecked = roleQuals.contains(qual.slug);

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final border =
                      isDark ? AppColors.borderDark : AppColors.borderLight;
                  const activeColor = AppColors.proPurple;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              roleQuals.remove(qual.slug);
                              widget.evidenceDrafts.removeWhere((draft) =>
                                  draft.roleSlug == role.slug &&
                                  draft.qualificationSlug == qual.slug);
                            } else {
                              roleQuals.add(qual.slug);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 12),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isChecked
                                      ? activeColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isChecked ? activeColor : border,
                                    width: 1.5,
                                  ),
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check_rounded,
                                        size: 13, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  qual.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: border.withValues(alpha: 0.6)),
                    ],
                  );
                }),
              const SizedBox(height: 16),
            ],

            // Dashed upload card for qualification documents, matching Screen F.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickQualificationEvidence,
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  painter: _DashedRoundedBorderPainter(
                    color: AppColors.proPurple.withValues(alpha: 0.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.proPurple.withValues(alpha: 0.035),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_upload_outlined,
                            color: AppColors.proPurple, size: 23),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.evidenceDrafts.isEmpty
                                    ? 'Upload licence or certificates'
                                    : 'Add or replace proof (${widget.evidenceDrafts.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'JPG, PNG or PDF, up to 5 MB. Reviewed by Nipanze. Approved proofs earn a badge.',
                                style: TextStyle(fontSize: 10, color: text2),
                              ),
                              for (final draft in widget.evidenceDrafts)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${draft.fileName} · ${draft.qualificationSlug.replaceAll('_', ' ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.proPurple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  Builder(builder: (ctx) {
                    final selected =
                        widget.yearsExperienceByRole[primaryRoleSlug] == exp;
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    const purple = AppColors.proPurple;
                    final border =
                        isDark ? AppColors.borderDark : AppColors.borderLight;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.yearsExperienceByRole[primaryRoleSlug] =
                              selected ? '' : exp;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? purple.withValues(alpha: 0.1)
                              : (isDark ? AppColors.bg3Dark : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? purple : border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          exp,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? purple
                                : Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
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
                    selected:
                        (widget.languagesByRole[primaryRoleSlug] ?? {'English'})
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
                    initialValue:
                        widget.expectedPayPeriodByRole[primaryRoleSlug] ??
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

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          rect.deflate(0.75), const Radius.circular(10)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 5).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 3.5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
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
