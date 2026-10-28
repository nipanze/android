// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_company_profile.dart';
import '../../domain/entities/provider_service_role.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import '../cubit/capabilities_cubit.dart';
import '../widgets/company_details_step.dart';

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
    this.categorySlug,
    this.workRoles = const [],
    this.workMetadataByRole = const {},
    this.companyPath = false,
    this.roleEvidenceDrafts = const [],
    this.identitySwitchCompleted = false,
  });

  final List<String> slugs;
  final Map<String, Map<String, dynamic>> metadataBySlug;
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
    this.defaultCurrency = 'UGX',
    this.initialPersonalName,
    this.initialDistrict,
    this.initialPersonalAvatarUrl,
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
  final String defaultCurrency;
  final String? initialPersonalName;
  final String? initialDistrict;
  final String? initialPersonalAvatarUrl;
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
    String defaultCurrency = 'UGX',
    String? initialPersonalName,
    String? initialDistrict,
    String? initialPersonalAvatarUrl,
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
              defaultCurrency: defaultCurrency,
              initialPersonalName: initialPersonalName,
              initialDistrict: initialDistrict,
              initialPersonalAvatarUrl: initialPersonalAvatarUrl,
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
  final Set<String> _removingRoleSlugs = {};
  final Map<String, List<Map<String, dynamic>>> _roleClaimStateOverrides = {};
  int _currentRoleIndex = 0;
  final Map<String, Set<String>> _kindsByRole = {};
  final Map<String, Set<String>> _qualificationsByRole = {};
  final Map<String, String> _yearsExperienceByRole = {};
  final Map<String, String> _availabilityByRole = {};
  final Map<String, Set<String>> _languagesByRole = {};
  bool _sharedPreferencesPrefilled = false;
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
  String _representativeProfileName = '';
  String? _personalAvatarUrl;
  String _companyDisplayName = '';
  String _companyPreviewName = '';

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
      'is_role_active': true,
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
          'currency': widget.defaultCurrency,
        },
    };
  }

  void _hydrateRoleDraft(String roleSlug, Map<String, dynamic> metadata) {
    _kindsByRole[roleSlug] = (metadata['kind_ids'] as List? ?? const [])
        .map((value) => value.toString())
        .toSet();
    _qualificationsByRole[roleSlug] =
        (metadata['qualification_ids'] as List? ?? const [])
            .map((value) => value.toString())
            .toSet();
    if (metadata['years_experience'] != null) {
      _yearsExperienceByRole[roleSlug] =
          metadata['years_experience'].toString();
    }
    if (metadata['availability'] != null) {
      _availabilityByRole[roleSlug] = metadata['availability'].toString();
    }
    final languages = metadata['languages'] as List?;
    if (languages != null && languages.isNotEmpty) {
      _languagesByRole[roleSlug] =
          languages.map((value) => value.toString()).toSet();
    }
    _willingToTravelByRole[roleSlug] =
        metadata['willing_to_travel'] as bool? ?? false;
    final expectedPay = metadata['expected_pay'];
    if (expectedPay is Map) {
      if (expectedPay['amount'] != null) {
        _expectedPayAmountByRole[roleSlug] = expectedPay['amount'].toString();
      }
      if (expectedPay['period'] != null) {
        _expectedPayPeriodByRole[roleSlug] = expectedPay['period'].toString();
      }
    }
  }

  void _prefillWorkPreferencesFromAnotherCategory(
    String categorySlug,
    List<ProviderServiceRole> roles,
  ) {
    final source = widget.existingCapabilities.where((capability) {
      if (!capability.isWork ||
          capability.categorySlug == null ||
          capability.categorySlug == categorySlug ||
          capability.metadata['is_role_active'] == false) {
        return false;
      }
      final availability = capability.metadata['availability']?.toString();
      final languages = capability.metadata['languages'] as List?;
      return (availability != null && availability.isNotEmpty) ||
          (languages != null && languages.isNotEmpty);
    }).firstOrNull;
    if (source == null) return;

    final availability = source.metadata['availability']?.toString();
    final languages = (source.metadata['languages'] as List? ?? const [])
        .map((value) => value.toString())
        .where((language) => language.isNotEmpty)
        .toSet();
    for (final role in roles) {
      if (!_availabilityByRole.containsKey(role.slug) &&
          availability != null &&
          availability.isNotEmpty) {
        _availabilityByRole[role.slug] = availability;
        _sharedPreferencesPrefilled = true;
      }
      if (!_languagesByRole.containsKey(role.slug) && languages.isNotEmpty) {
        _languagesByRole[role.slug] = {...languages};
        _sharedPreferencesPrefilled = true;
      }
    }
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
      categorySlug: _selectedCategory?.slug,
      workRoles: canEditWorkRoles ? _selectedRoles.toList() : const [],
      workMetadataByRole: workMetadataByRole,
      roleEvidenceDrafts: List.unmodifiable(_roleEvidenceDrafts.where(
        (draft) => _selectedRoles.contains(draft.roleSlug),
      )),
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
    final initialCompanyName = providerType == ProviderCategoryType.company
        ? ((companyData['company_name']?.toString().trim().isNotEmpty == true)
            ? companyData['company_name'].toString()
            : (savedPresentation['display_name']?.toString() ?? ''))
        : '';
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
      final isActiveRole = existingRole?.metadata['is_role_active'] != false;
      if ((widget.existingSlugs.contains(capSlug) ||
              widget.existingSlugs.contains(role.slug)) &&
          isActiveRole) {
        _selectedRoles.add(role.slug);
        if (existingRole != null) {
          _hydrateRoleDraft(role.slug, existingRole.metadata);
        }
      }
    }
    _prefillWorkPreferencesFromAnotherCategory(cat.slug, roles);

    setState(() {
      _categoryCapabilities = filteredCaps;
      _categoryRoles = roles;
      _providerTypeRequired = needsProviderType;
      _providerType = providerType;
      _savedProviderType = providerType;
      _identityPresentation = {
        'display_mode': providerType == ProviderCategoryType.individual
            ? 'personal'
            : (savedPresentation['display_mode']?.toString() ?? 'company'),
        'display_name': providerType == ProviderCategoryType.company
            ? initialCompanyName
            : personalName,
        'representative_name': widget.initialPersonalName?.trim() ?? '',
        'representative_authorized':
            savedPresentation['representative_authorized'] == true,
      };
      _personalDisplayName = personalName;
      _representativeProfileName = widget.initialPersonalName?.trim() ?? '';
      _personalAvatarUrl = widget.initialPersonalAvatarUrl;
      _companyDisplayName = initialCompanyName;
      _companyPreviewName =
          companyData['company_name']?.toString().trim().isNotEmpty == true
              ? companyData['company_name'].toString()
              : initialCompanyName;
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
    if (_savedProviderType != null &&
        _savedProviderType != type &&
        presentation['display_mode'] == 'company_with_representative' &&
        (!_representativeAuthorized ||
            (presentation['representative_name'] as String? ?? '')
                .trim()
                .isEmpty)) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _providerTypeError = l10n.providerIdentityRequiredInfo);
      return;
    }
    setState(() {
      _savingProviderType = true;
      _providerTypeError = null;
    });
    try {
      if (_savedProviderType != null && _savedProviderType != type) {
        setState(() {
          _step = 6;
          _savingProviderType = false;
        });
        return;
      }
      // Company identity, name and selections are committed together when its
      // details are saved. Individual identity setup keeps its early save.
      if (type == ProviderCategoryType.individual &&
          _savedProviderType == null) {
        await widget.providerRepository.setCategoryType(slug, type);
      }
      if (type == ProviderCategoryType.individual &&
          (presentation['display_name'] as String? ?? '').trim().isNotEmpty) {
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
        // Company profiles submit service capabilities only. Existing personal
        // work roles remain untouched and are deliberately excluded here.
        roleCapabilitySlugs: const [],
        profile: {
          ...profile,
          'company_name':
              (_identityPresentation['display_name']?.toString() ?? '').trim(),
        },
        evidence: const [],
        presentation: {
          ..._identityPresentation,
          'display_mode': _representativeAuthorized &&
                  _representativeProfileName.trim().isNotEmpty
              ? 'company_with_representative'
              : 'company',
          'display_name':
              (_identityPresentation['display_name']?.toString() ?? '').trim(),
          'representative_name': _representativeProfileName.trim(),
          'representative_authorized': _representativeAuthorized &&
              _representativeProfileName.trim().isNotEmpty,
        },
      );
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

  Future<void> _changeRepresentativeProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    await context.push<void>('/profile');
    if (!mounted) return;
    await profileCubit.refresh();
    if (!mounted) return;
    final state = profileCubit.state;
    if (state is! ProfileCubitLoaded) return;
    final name = state.profile.fullName?.trim() ?? '';
    final avatarUrl = state.profile.avatarUrl;
    final representativeEnabled = _representativeAuthorized && name.isNotEmpty;
    setState(() {
      _representativeProfileName = name;
      _personalAvatarUrl = avatarUrl;
      _representativeAuthorized = representativeEnabled;
      _identityPresentation = {
        ..._identityPresentation,
        'representative_name': name,
        'representative_authorized': representativeEnabled,
        'display_mode':
            representativeEnabled ? 'company_with_representative' : 'company',
      };
    });
  }

  void _openAudience() {
    setState(() => _showAudience = true);
  }

  ProviderCapability? _savedRoleCapability(String slug) {
    final role = _categoryRoles.where((item) => item.slug == slug).firstOrNull;
    final capabilitySlug = role?.capabilitySlug ?? 'work_$slug';
    return widget.existingCapabilities
        .where((capability) => capability.capabilitySlug == capabilitySlug)
        .firstOrNull;
  }

  List<Map<String, dynamic>> _roleClaims(String slug) =>
      (_roleClaimStateOverrides[slug] ??
              _savedRoleCapability(slug)?.roleQualificationClaims ??
              const [])
          .where((claim) => (claim['role_slug']?.toString() ?? slug) == slug)
          .toList();

  List<Map<String, String>> _activeProofStates(String slug) => _roleClaims(slug)
      .where((claim) =>
          claim['has_evidence'] == true &&
          (claim['status'] == 'pending_review' ||
              claim['status'] == 'verified'))
      .map((claim) => <String, String>{
            'role_slug': claim['role_slug']?.toString() ?? slug,
            'qualification_slug': claim['qualification_slug']?.toString() ?? '',
            'status': claim['status']?.toString() ?? '',
          })
      .toList()
    ..sort((a, b) => a['qualification_slug']!.compareTo(
          b['qualification_slug']!,
        ));

  Map<String, int> get _rolePendingProofCounts => {
        for (final role in _categoryRoles)
          role.slug: _roleClaims(role.slug)
              .where((claim) =>
                  claim['has_evidence'] == true &&
                  claim['status'] == 'pending_review')
              .length,
      };

  Map<String, int> get _roleApprovedProofCounts => {
        for (final role in _categoryRoles)
          role.slug: _roleClaims(role.slug)
              .where((claim) =>
                  claim['has_evidence'] == true &&
                  claim['status'] == 'verified')
              .length,
      };

  Future<bool> _confirmRoleRemoval(ProviderServiceRole role) async {
    final claims = _activeProofStates(role.slug);
    if (claims.isEmpty) return true;
    final pendingCount =
        claims.where((claim) => claim['status'] == 'pending_review').length;
    final approvedCount = claims.length - pendingCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.bg2Dark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final text = Theme.of(sheetContext).colorScheme.onSurface;
        final text2 = text.withValues(alpha: 0.72);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Remove ${role.name}?',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _removalNote(
                  Icons.schedule_rounded,
                  'Its specialties and qualifications are hidden from employers.',
                  text2,
                ),
                if (pendingCount > 0)
                  _removalNote(
                    Icons.schedule_rounded,
                    '$pendingCount proof${pendingCount == 1 ? '' : 's'} under review ${pendingCount == 1 ? 'is' : 'are'} withdrawn.',
                    Colors.amber.shade800,
                  ),
                if (approvedCount > 0)
                  _removalNote(
                    Icons.verified_outlined,
                    '$approvedCount approved Nipanze badge${approvedCount == 1 ? '' : 's'} ${approvedCount == 1 ? 'stops' : 'stop'} showing.',
                    Colors.amber.shade800,
                  ),
                _removalNote(
                  Icons.check_rounded,
                  'Your answers are kept. Tick the role again to restore them.',
                  AppColors.success,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.proPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Keep role'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Remove role'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Widget _removalNote(IconData icon, String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Future<void> _toggleRoleSelection(String slug) async {
    if (_removingRoleSlugs.contains(slug)) return;
    final role = _categoryRoles.where((item) => item.slug == slug).firstOrNull;
    if (role == null) return;
    final savedCapability = _savedRoleCapability(slug);
    if (!_selectedRoles.contains(slug)) {
      if (savedCapability?.metadata['is_role_active'] == false) {
        setState(() => _removingRoleSlugs.add(slug));
        try {
          final result = await widget.providerRepository.setWorkRoleActive(
            providerCapabilityId: savedCapability!.id,
            roleSlug: slug,
            active: true,
          );
          if (result['changed'] != true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not restore this role.')),
              );
            }
            return;
          }
          final claims = (result['claim_states'] as List? ?? const [])
              .whereType<Map>()
              .map((claim) => claim.cast<String, dynamic>())
              .toList();
          _hydrateRoleDraft(slug, savedCapability.metadata);
          _roleClaimStateOverrides[slug] = claims;
          if (mounted) {
            await context.read<CapabilitiesCubit>().loadWithOpportunities();
          }
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(userFacingErrorMessage(error))),
            );
          }
          return;
        } finally {
          if (mounted) setState(() => _removingRoleSlugs.remove(slug));
        }
      }
      if (mounted) setState(() => _selectedRoles.add(slug));
      return;
    }
    final proofStates = _activeProofStates(slug);
    if (proofStates.isNotEmpty && !await _confirmRoleRemoval(role)) return;
    if (savedCapability != null) {
      setState(() => _removingRoleSlugs.add(slug));
      try {
        final result = await widget.providerRepository.setWorkRoleActive(
          providerCapabilityId: savedCapability.id,
          roleSlug: slug,
          active: false,
          expectedClaimStates: proofStates,
        );
        if (!mounted) return;
        if (result['changed'] != true) {
          final rows = (result['claim_states'] as List? ?? const [])
              .whereType<Map>()
              .map((claim) => claim.cast<String, dynamic>())
              .toList();
          setState(() => _roleClaimStateOverrides[slug] = rows);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Proof status changed. Review the updated status before removing this role.')),
          );
          return;
        }
        final claims = (result['claim_states'] as List? ?? const [])
            .whereType<Map>()
            .map((claim) => claim.cast<String, dynamic>())
            .toList();
        _roleClaimStateOverrides[slug] = claims;
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFacingErrorMessage(error))),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _removingRoleSlugs.remove(slug));
      }
    }

    if (!mounted) return;
    setState(() {
      _removingRoleSlugs.remove(slug);
      _selectedRoles.remove(slug);
      if (_selectedRoles.isEmpty) {
        _currentRoleIndex = 0;
      } else if (_currentRoleIndex >= _selectedRoles.length) {
        _currentRoleIndex = _selectedRoles.length - 1;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role removed. Tick it again to restore your answers.'),
      ),
    );
    if (savedCapability != null) {
      unawaited(context.read<CapabilitiesCubit>().loadWithOpportunities());
    }
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
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: text2, size: 20),
                        ),
                      if (_step > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _step == 0
                              ? l10n.chooseCategory
                              : (_step == 2 || _step == 3)
                                  ? (_selectedCategory
                                          ?.localizedName(localeCode) ??
                                      l10n.chooseCapabilities)
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
                if (_step != 6) const Divider(height: 1),

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
                              ? ProviderTypeStep(
                                  selected: _providerType,
                                  saving: _savingProviderType,
                                  error: _providerTypeError,
                                  initialDisplayName:
                                      _identityPresentation['display_name']
                                              ?.toString() ??
                                          (widget.initialPersonalName ?? ''),
                                  initialAvatarUrl: _personalAvatarUrl,
                                  companyPreviewName: _companyPreviewName,
                                  categoryName: _selectedCategory
                                          ?.localizedName(localeCode) ??
                                      '',
                                  currentType: _savedProviderType,
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
                                          : (_representativeAuthorized &&
                                                  _representativeProfileName
                                                      .trim()
                                                      .isNotEmpty
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
                                  ? IdentitySwitchConfirmStep(
                                      categoryName: _selectedCategory
                                              ?.localizedName(localeCode) ??
                                          '',
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
                                          inactiveCapabilities: widget
                                              .existingCapabilities
                                              .where((capability) =>
                                                  capability.categorySlug ==
                                                      _selectedCategory?.slug &&
                                                  !capability.isActive &&
                                                  (capability.identityType ==
                                                          null ||
                                                      capability.identityType ==
                                                          _providerType!.name))
                                              .toList(),
                                          error: _providerTypeError,
                                          saving: _savingProviderType,
                                          onBack: _goBack,
                                          onConfirm: _confirmIdentitySwitch,
                                        )
                                      : _step == 5
                                          ? CompanyDetailsStep(
                                              categorySlug:
                                                  _selectedCategory?.slug ?? '',
                                              categoryName: _selectedCategory
                                                      ?.localizedName(
                                                          localeCode) ??
                                                  '',
                                              serviceCount: _selected.length,
                                              serviceNames:
                                                  _categoryCapabilities
                                                      .where((capability) =>
                                                          _selected.contains(
                                                              capability.slug))
                                                      .map((capability) =>
                                                          capability
                                                              .localizedName(
                                                                  localeCode))
                                                      .toList(),
                                              roleCount: _selectedRoles.length,
                                              initialProfile: _companyProfile,
                                              companyName:
                                                  _identityPresentation[
                                                              'display_name']
                                                          ?.toString() ??
                                                      '',
                                              locationHint:
                                                  widget.initialDistrict,
                                              representativeName:
                                                  _representativeProfileName,
                                              representativeAvatarUrl:
                                                  _personalAvatarUrl,
                                              representativeAuthorized:
                                                  _representativeAuthorized,
                                              onPresentationChanged:
                                                  (presentation) =>
                                                      setState(() {
                                                _identityPresentation = {
                                                  ..._identityPresentation,
                                                  ...presentation,
                                                  'representative_name':
                                                      _representativeProfileName,
                                                };
                                                _representativeAuthorized =
                                                    presentation[
                                                            'representative_authorized'] ==
                                                        true;
                                                final name =
                                                    presentation['display_name']
                                                        ?.toString();
                                                if (name != null) {
                                                  _companyDisplayName = name;
                                                  _companyPreviewName = name;
                                                }
                                              }),
                                              onChangeProfile:
                                                  _changeRepresentativeProfile,
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
                                              ? _KindsStepView(
                                                  roles: _categoryRoles
                                                      .where((role) =>
                                                          _selectedRoles
                                                              .contains(
                                                                  role.slug))
                                                      .toList(),
                                                  selectedKindsByRole:
                                                      _kindsByRole,
                                                  scrollController:
                                                      scrollController,
                                                  onNext: () =>
                                                      setState(() => _step = 3),
                                                )
                                              : _step == 3
                                                  ? _QualificationsStepView(
                                                      roles: _categoryRoles
                                                          .where((r) =>
                                                              _selectedRoles
                                                                  .contains(
                                                                      r.slug))
                                                          .toList(),
                                                      existingCapabilities: widget
                                                          .existingCapabilities,
                                                      providerRepository: widget
                                                          .providerRepository,
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
                                                      defaultCurrency: widget
                                                          .defaultCurrency,
                                                      evidenceDrafts:
                                                          _roleEvidenceDrafts,
                                                      showSharedPreferencesHint:
                                                          _sharedPreferencesPrefilled,
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
                                                          pendingProofCounts:
                                                              _rolePendingProofCounts,
                                                          approvedProofCounts:
                                                              _roleApprovedProofCounts,
                                                          removingRoleSlugs:
                                                              _removingRoleSlugs,
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
                                                          onToggleRole:
                                                              _toggleRoleSelection,
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

class ProviderTypeStep extends StatelessWidget {
  const ProviderTypeStep({
    super.key,
    required this.selected,
    required this.saving,
    required this.error,
    required this.onSelect,
    required this.onContinue,
    required this.initialDisplayName,
    this.initialAvatarUrl,
    required this.companyPreviewName,
    required this.categoryName,
    required this.currentType,
  });

  final ProviderCategoryType? selected;
  final bool saving;
  final String? error;
  final ValueChanged<ProviderCategoryType> onSelect;
  final VoidCallback onContinue;
  final String initialDisplayName;
  final String? initialAvatarUrl;
  final String companyPreviewName;
  final String categoryName;
  final ProviderCategoryType? currentType;

  Widget _optionCard(
    BuildContext context, {
    required ProviderCategoryType type,
    required String title,
    required String description,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = selected == type;
    final isCurrent = currentType == type;
    final isCompany = type == ProviderCategoryType.company;
    final savedName = isCompany
        ? (companyPreviewName.trim().isNotEmpty
            ? companyPreviewName.trim()
            : initialDisplayName.trim())
        : initialDisplayName.trim();
    final hasSavedCompany = savedName.isNotEmpty;
    final previewName = isCompany && !hasSavedCompany
        ? 'Your company name'
        : (savedName.isEmpty ? 'Your name' : savedName);
    final hint = !isCompany
        ? 'Name and photo come from your Profile'
        : hasSavedCompany
            ? 'Edit in step 2'
            : 'You add it in step 2';
    final icon = isCompany ? Icons.business_outlined : Icons.person_outline;
    final neutralBorder = theme.brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final borderColor = isSelected ? colors.primary : neutralBorder;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: isCurrent ? '$title, ${l10n.providerIdentityCurrent}' : title,
      hint: description,
      button: true,
      onTap: () => onSelect(type),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(type),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surface,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    l10n.providerIdentityCurrent,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? colors.primary : colors.outline,
                      size: 22,
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  Text(
                    'PREVIEW',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: neutralBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: !isCompany &&
                                  initialAvatarUrl?.trim().isNotEmpty == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    initialAvatarUrl!.trim(),
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      icon,
                                      color: colors.primary,
                                      size: 21,
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) =>
                                            loadingProgress == null
                                                ? child
                                                : Icon(
                                                    icon,
                                                    color: colors.primary,
                                                    size: 21,
                                                  ),
                                  ),
                                )
                              : Icon(icon, color: colors.primary, size: 21),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                previewName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isCompany && !hasSavedCompany
                                      ? colors.onSurfaceVariant
                                      : colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (categoryName.isNotEmpty)
                                Text(
                                  categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    hint,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentTypeName = currentType == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final selectedTypeName = selected == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.providerTypeOffering.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.providerTypeTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(l10n.providerTypeSubtitle),
              const SizedBox(height: 18),
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.providerTypeTitle,
                child: Column(
                  children: [
                    _optionCard(
                      context,
                      type: ProviderCategoryType.individual,
                      title: l10n.providerTypeIndividual,
                      description: l10n.providerTypeIndividualDesc,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 10),
                    _optionCard(
                      context,
                      type: ProviderCategoryType.company,
                      title: l10n.providerTypeCompany,
                      description: l10n.providerTypeCompanyDesc,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              if (currentType != null &&
                  selected != null &&
                  currentType != selected) ...[
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.06),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.22),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You currently offer ${categoryName.isEmpty ? 'this category' : categoryName} as $currentTypeName. Choosing $selectedTypeName asks you to confirm the switch. ${l10n.providerIdentityDataKept}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.providerTypeNotVerification,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton.icon(
                  onPressed: saving ? null : onContinue,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
              if (selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.providerTypeChooseOne,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: saving ? null : onContinue,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.btnContinue),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IdentitySwitchConfirmStep extends StatelessWidget {
  const IdentitySwitchConfirmStep({
    super.key,
    required this.categoryName,
    required this.from,
    required this.to,
    required this.pendingOffers,
    required this.onContinue,
    required this.onCancel,
  });

  final String categoryName;
  final ProviderCategoryType from;
  final ProviderCategoryType to;
  final int pendingOffers;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final toName = to == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final fromNameShort = from == ProviderCategoryType.company
        ? l10n.companyLabel
        : l10n.providerTypeIndividual;
    final toNameShort = to == ProviderCategoryType.company
        ? l10n.companyLabel
        : l10n.providerTypeIndividual;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.providerIdentitySwitchingCategoryBadge,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.providerIdentitySwitchTitle(toName),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  categoryName.isNotEmpty
                      ? l10n.providerIdentitySwitchCategoryBody(categoryName)
                      : l10n.providerIdentitySwitchBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Identity Transition Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colors.surfaceContainerLow
                              : const Color(0xFFF8FAFC),
                          border: Border.all(
                            color: isDark
                                ? colors.outlineVariant
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              from == ProviderCategoryType.company
                                  ? Icons.business_outlined
                                  : Icons.person_outline_rounded,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                fromNameShort,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Transform.scale(
                        scaleX: isRtl ? -1 : 1,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colors.primary.withValues(alpha: 0.08)
                              : const Color(0xFFF4F8FF),
                          border: Border.all(
                            color: colors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              to == ProviderCategoryType.company
                                  ? Icons.business_outlined
                                  : Icons.person_outline_rounded,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                toNameShort,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // "Kept safe" Section Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F291E)
                        : const Color(0xFFF0FDF4),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                          : const Color(0xFFDCFCE7),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gpp_good_outlined,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.providerIdentityKeptSafeHeader,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBulletItem(
                        icon: Icons.check_rounded,
                        iconColor: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                        text: l10n.providerIdentityKeptServiceInfo,
                        textColor: colors.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _buildBulletItem(
                        icon: Icons.check_rounded,
                        iconColor: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                        text: l10n.providerIdentityKeptDealsReviews,
                        textColor: colors.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _buildBulletItem(
                        icon: Icons.check_rounded,
                        iconColor: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                        text: l10n.providerIdentityKeptJobRoles,
                        textColor: colors.onSurface,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // "What changes" Section Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.surfaceContainerLow
                        : const Color(0xFFF4F7FC),
                    border: Border.all(
                      color: isDark
                          ? colors.outlineVariant.withValues(alpha: 0.5)
                          : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.providerIdentityWhatChangesHeader,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBulletItem(
                        icon: Icons.schedule_rounded,
                        iconColor: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97706),
                        text: l10n.providerIdentityChangeServicesInactive(
                            fromNameShort),
                        textColor: colors.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _buildBulletItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: colors.primary,
                        text: l10n.providerIdentityChangeNewOffers(toNameShort),
                        textColor: colors.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _buildBulletItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: colors.primary,
                        text: l10n.providerIdentityChangeVerification,
                        textColor: colors.onSurface,
                      ),
                      if (pendingOffers > 0) ...[
                        const SizedBox(height: 10),
                        _buildBulletItem(
                          icon: Icons.pending_actions_rounded,
                          iconColor: colors.tertiary,
                          text:
                              l10n.providerIdentityPendingOffers(pendingOffers),
                          textColor: colors.onSurface,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: isDark
              ? colors.outlineVariant.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onContinue,
                    child: Text(
                      l10n.btnContinue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onCancel,
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.38,
              color: textColor,
            ),
          ),
        ),
      ],
    );
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
    required this.inactiveCapabilities,
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
  final List<ProviderCapability> inactiveCapabilities;
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'STEP 2 OF 2',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.providerIdentityReviewTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: colors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                ),
                child: Column(
                  children: [
                    _IdentityReviewRow(
                      label: l10n.providerIdentityCategory,
                      value: categoryName,
                    ),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    _IdentityReviewRow(
                      label: l10n.providerIdentityNewIdentity,
                      value: '$toName\nwas $fromName',
                    ),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    _IdentityReviewRow(
                      label: l10n.providerIdentityPublicName,
                      value: withRep
                          ? '$displayName\n${l10n.providerIdentityRepresentedBy(rep)}'
                          : (displayName.isNotEmpty ? displayName : '-'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.providerIdentityReused.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                ),
                child: Column(
                  children: [
                    _ReviewCheckRow(text: l10n.providerIdentityDataKept),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    if (pendingOffers > 0)
                      _ReviewCheckRow(
                        text: l10n.providerIdentityPendingOffers(pendingOffers),
                      )
                    else
                      const _ReviewCheckRow(
                        text: 'Locations: Kampala, Wakiso',
                      ),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    const _ReviewCheckRow(
                      text: 'Images (2) and contact preferences',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.providerIdentityNeedsAttention.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFAA6500),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 8),
              if (inactiveCapabilities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFDCE4EF)),
                  ),
                  child: Text(
                    'No inactive services for this identity.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B6470),
                        ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFDCE4EF)),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < inactiveCapabilities.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 12, endIndent: 12),
                        _ReviewAttentionRow(
                          title: inactiveCapabilities[i].capabilityName ??
                              inactiveCapabilities[i].capabilitySlug,
                          subtitle: _inactiveCapabilityReason(
                              inactiveCapabilities[i]),
                          badge: _inactiveCapabilityStatus(
                            inactiveCapabilities[i],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: colors.error)),
                TextButton.icon(
                  onPressed: saving ? null : onConfirm,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving ? null : onConfirm,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.providerIdentityConfirm,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: saving ? null : onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                    ),
                    child: Text(
                      l10n.btnBack,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityReviewRow extends StatelessWidget {
  const _IdentityReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5B6470),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF1F2A37),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _ReviewCheckRow extends StatelessWidget {
  const _ReviewCheckRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF168044), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1F2A37),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewAttentionRow extends StatelessWidget {
  const _ReviewAttentionRow({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    const badgeBg = Color(0xFFEEF1F5);
    const badgeText = Color(0xFF5A6575);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F2A37),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B6470),
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: badgeText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _inactiveCapabilityStatus(ProviderCapability capability) =>
    switch (capability.status) {
      ProviderCapabilityStatus.pendingReview => 'Pending review',
      ProviderCapabilityStatus.rejected => 'Rejected',
      ProviderCapabilityStatus.expired => 'Expired',
      _ => 'Inactive',
    };

String _inactiveCapabilityReason(ProviderCapability capability) {
  if (capability.pendingEvidenceCount > 0) return 'Proof is awaiting review.';
  if (capability.rejectedEvidenceCount > 0) {
    return capability.latestRejectReason ?? 'Proof was not approved.';
  }
  if (capability.expiredEvidenceCount > 0) return 'Proof has expired.';
  if (capability.verificationPolicy ==
      ProviderVerificationPolicy.requiredProof) {
    return 'Required proof has not been approved.';
  }
  return 'This service is currently inactive.';
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
class _RoleProgressIndicator extends StatelessWidget {
  const _RoleProgressIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? AppColors.borderDark : const Color(0xFFE2E6EE);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          for (var index = 1; index <= 3; index++) ...[
            if (index > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: index <= step ? AppColors.proPurple : inactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCapabilitiesView extends StatelessWidget {
  const _CategoryCapabilitiesView({
    this.categorySlug,
    required this.capabilities,
    required this.roles,
    required this.existingSlugs,
    required this.selected,
    required this.selectedRoles,
    required this.pendingProofCounts,
    required this.approvedProofCounts,
    required this.removingRoleSlugs,
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
  final Map<String, int> pendingProofCounts;
  final Map<String, int> approvedProofCounts;
  final Set<String> removingRoleSlugs;
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
            // Provider type is category scoped and can be changed from C/D.
            if (providerType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.bg3Dark.withValues(alpha: 0.7)
                        : const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.providerTypeOfferingAs} ${companyType ? l10n.providerTypeCompany : l10n.providerTypeIndividual}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: onChangeProviderType,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.providerTypeChange,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_providerSafetyNotice(l10n, categorySlug)
                case final String notice)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              _RoleProgressIndicator(step: 1),
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
                individualType ? 'Choose roles' : l10n.providerTypeWhatRoles,
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
                    pendingProofCount: pendingProofCounts[role.slug] ?? 0,
                    approvedProofCount: approvedProofCounts[role.slug] ?? 0,
                    isRemoving: removingRoleSlugs.contains(role.slug),
                    border: border,
                    text2: text2,
                    onTap: removingRoleSlugs.contains(role.slug)
                        ? null
                        : () => onToggleRole(role.slug),
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
    required this.pendingProofCount,
    required this.approvedProofCount,
    required this.isRemoving,
    required this.border,
    required this.text2,
    required this.onTap,
  });

  final ProviderServiceRole role;
  final bool isSelected;
  final int pendingProofCount;
  final int approvedProofCount;
  final bool isRemoving;
  final Color border;
  final Color text2;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.proPurple;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
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
            if (isRemoving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
                  if (role.requiresProof ||
                      pendingProofCount > 0 ||
                      approvedProofCount > 0) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (role.requiresProof)
                          _ProofCountPill(
                            icon: Icons.lock_outline_rounded,
                            label: l10n.providerPolicyNeedsProofTag,
                            color: Colors.amber.shade800,
                          ),
                        if (pendingProofCount > 0)
                          _ProofCountPill(
                            icon: Icons.schedule_rounded,
                            label:
                                '$pendingProofCount proof${pendingProofCount == 1 ? '' : 's'} under review',
                            color: Colors.amber.shade800,
                          ),
                        if (approvedProofCount > 0)
                          _ProofCountPill(
                            icon: Icons.verified_rounded,
                            label:
                                '$approvedProofCount approved proof${approvedProofCount == 1 ? '' : 's'}',
                            color: AppColors.success,
                          ),
                      ],
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

class _ProofCountPill extends StatelessWidget {
  const _ProofCountPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
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
class _KindsStepView extends StatefulWidget {
  const _KindsStepView(
      {required this.roles,
      required this.selectedKindsByRole,
      required this.scrollController,
      required this.onNext});
  final List<ProviderServiceRole> roles;
  final Map<String, Set<String>> selectedKindsByRole;
  final ScrollController scrollController;
  final VoidCallback onNext;
  @override
  State<_KindsStepView> createState() => _KindsStepViewState();
}

class _KindsStepViewState extends State<_KindsStepView> {
  String _instruction(ProviderServiceRole role) {
    final q = (role.kindQuestion ?? '').toLowerCase();
    final slug = role.slug.toLowerCase();
    if (slug == 'developer' || q.contains('build') || q.contains('software')) {
      return 'Pick all that apply. Employers search by tech stack.';
    }
    if (slug == 'driver' || q.contains('vehicle') || q.contains('drive')) {
      return 'Pick all that apply. Employers search by vehicle type.';
    }
    return 'Pick all that apply. Employers search by specialty.';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = dark ? AppColors.text2Dark : AppColors.text2Light;
    final ready = widget.roles.isNotEmpty &&
        widget.roles.every((r) =>
            (widget.selectedKindsByRole[r.slug] ?? const <String>{})
                .isNotEmpty);
    return Stack(children: [
      ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            _RoleProgressIndicator(step: 2),
            Text('STEP 2 OF 3',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: text2)),
            const SizedBox(height: 12),
            Text('Role details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final role in widget.roles)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: dark ? AppColors.bg3Dark : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border.withValues(alpha: .6))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(role.kindQuestion ?? 'Which kind do you do?',
                          style: TextStyle(fontSize: 13, color: text2)),
                      const SizedBox(height: 3),
                      Text(_instruction(role),
                          style: TextStyle(fontSize: 11, color: text2)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final kind in role.kinds)
                          _KindChip(
                            label: kind.name,
                            selected:
                                (widget.selectedKindsByRole[role.slug] ?? {})
                                    .contains(kind.slug),
                            onTap: () => setState(() {
                              final values = widget.selectedKindsByRole
                                  .putIfAbsent(role.slug, () => <String>{});
                              if (!values.add(kind.slug)) {
                                values.remove(kind.slug);
                              }
                            }),
                          )
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          '${(widget.selectedKindsByRole[role.slug] ?? const <String>{}).length} selected',
                          style: TextStyle(
                              fontSize: 11,
                              color: text2,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
          ]),
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
                    borderRadius: BorderRadius.circular(12))),
            onPressed: ready ? widget.onNext : null,
            child: const Text('Next: add qualifications',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          )),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Sheet F: Qualifications & Proof (Step 3 of 3)
// ---------------------------------------------------------------------------
class _QualificationsStepView extends StatefulWidget {
  const _QualificationsStepView({
    required this.roles,
    required this.existingCapabilities,
    required this.providerRepository,
    required this.qualificationsByRole,
    required this.yearsExperienceByRole,
    required this.availabilityByRole,
    required this.languagesByRole,
    required this.willingToTravelByRole,
    required this.expectedPayAmountByRole,
    required this.expectedPayPeriodByRole,
    required this.defaultCurrency,
    required this.evidenceDrafts,
    required this.showSharedPreferencesHint,
    required this.scrollController,
    required this.onSave,
  });

  final List<ProviderServiceRole> roles;
  final List<ProviderCapability> existingCapabilities;
  final IProviderRepository providerRepository;
  final Map<String, Set<String>> qualificationsByRole;
  final Map<String, String> yearsExperienceByRole;
  final Map<String, String> availabilityByRole;
  final Map<String, Set<String>> languagesByRole;
  final Map<String, bool> willingToTravelByRole;
  final Map<String, String> expectedPayAmountByRole;
  final Map<String, String> expectedPayPeriodByRole;
  final String defaultCurrency;
  final List<PendingRoleEvidenceDraft> evidenceDrafts;
  final bool showSharedPreferencesHint;
  final ScrollController scrollController;
  final VoidCallback onSave;

  @override
  State<_QualificationsStepView> createState() =>
      _QualificationsStepViewState();
}

class _QualificationsStepViewState extends State<_QualificationsStepView> {
  final _amountController = TextEditingController();
  final Map<String, String> _claimStatusOverrides = {};
  final Set<String> _withdrawnEvidenceKeys = {};

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

  bool _requiredProofIsReady(
    ProviderServiceRole role,
    ProviderRoleQualification qualification,
  ) {
    final proofKey = _proofKey(role.slug, qualification.slug);
    final hasDraft = widget.evidenceDrafts.any(
      (draft) => _proofKey(draft.roleSlug, draft.qualificationSlug) == proofKey,
    );
    if (hasDraft) return true;

    final capabilitySlug = role.capabilitySlug ?? 'work_${role.slug}';
    final capability = widget.existingCapabilities
        .where((item) => item.capabilitySlug == capabilitySlug)
        .firstOrNull;
    final claim = capability?.roleQualificationClaims
        .where((item) =>
            item['role_slug'] == role.slug &&
            item['qualification_slug'] == qualification.slug)
        .firstOrNull;
    final status =
        _claimStatusOverrides[proofKey] ?? claim?['status']?.toString();
    return claim?['has_evidence'] == true &&
        (status == 'pending_review' ||
            status == 'verified' ||
            (status == 'expired' && claim?['verified_at'] != null));
  }

  bool get _allRequiredProofsReady => widget.roles.every(
        (role) => role.requiredProofQualifications.every(
          (qualification) => _requiredProofIsReady(role, qualification),
        ),
      );

  Future<bool> _confirmQualificationUntick({
    required ProviderRoleQualification qualification,
    required String status,
  }) async {
    final pending = status == 'pending_review';
    return await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.bg2Dark
              : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(sheetContext).brightness == Brightness.dark
                                ? AppColors.borderDark
                                : const Color(0xFFE2E6EE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pending
                        ? 'Withdraw this proof?'
                        : 'Remove this qualification?',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pending
                        ? '${qualification.name} is being reviewed. Unticking withdraws it from review. You can upload it again later.'
                        : 'Unticking ${qualification.name} will remove your Nipanze badge for this qualification.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.proPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Withdraw and untick'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.proPurple,
                        side: BorderSide(
                            color: AppColors.proPurple.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _untickQualification({
    required ProviderServiceRole role,
    required ProviderRoleQualification qualification,
    required Set<String> roleQualifications,
    required ProviderCapability? existingCapability,
    required Map<String, dynamic>? existingClaim,
    required PendingRoleEvidenceDraft? evidenceDraft,
  }) async {
    final key = _proofKey(role.slug, qualification.slug);
    final status = _claimStatusOverrides[key] ??
        existingClaim?['status']?.toString() ??
        'self_declared';
    final wasApproved = existingClaim?['has_evidence'] == true &&
        (status == 'verified' ||
            (status == 'expired' && existingClaim?['verified_at'] != null));
    if (wasApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.providerApprovedProofLocked)),
      );
      return;
    }
    final needsConfirmation =
        existingClaim?['has_evidence'] == true && status == 'pending_review';

    if (needsConfirmation &&
        !await _confirmQualificationUntick(
          qualification: qualification,
          status: status,
        )) {
      return;
    }

    if (needsConfirmation && existingCapability != null) {
      try {
        final result =
            await widget.providerRepository.withdrawRoleQualification(
          providerCapabilityId: existingCapability.id,
          roleSlug: role.slug,
          qualificationSlug: qualification.slug,
          expectedStatus: status,
        );
        if (!mounted) return;
        if (result['withdrawn'] != true) {
          setState(() {
            _claimStatusOverrides[key] = result['status']?.toString() ?? status;
            roleQualifications.add(qualification.slug);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Proof status changed. The qualification is still selected with its latest status.',
              ),
            ),
          );
          return;
        }
        setState(() {
          roleQualifications.remove(qualification.slug);
          _claimStatusOverrides[key] = 'withdrawn';
          _withdrawnEvidenceKeys.add(key);
          if (evidenceDraft != null) {
            widget.evidenceDrafts.remove(evidenceDraft);
          }
        });
        if (status == 'pending_review') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Proof withdrawn. You can upload it again anytime.',
              ),
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
        );
      }
      return;
    }

    setState(() {
      roleQualifications.remove(qualification.slug);
      if (evidenceDraft != null) widget.evidenceDrafts.remove(evidenceDraft);
    });
  }

  Future<void> _pickQualificationEvidence({
    required (ProviderServiceRole, ProviderRoleQualification) target,
  }) async {
    final (role, qualification) = target;
    if (!role.acceptsProofFor(qualification)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('This qualification does not accept document evidence.')),
      );
      return;
    }

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
    final l10n = AppLocalizations.of(context)!;
    final text2 =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final primaryRoleSlug = widget.roles.firstOrNull?.slug ?? '';

    return Stack(
      children: [
        ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            _RoleProgressIndicator(step: 3),
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
              'Qualifications & proof',
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
              if (widget.roles.length > 1 || role.requiresProof) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    role.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
              if (role.requiresProof) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        _requiredProofIsReady(
                                role, role.requiredProofQualifications.first)
                            ? Icons.check_circle_outline_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: _requiredProofIsReady(
                                role, role.requiredProofQualifications.first)
                            ? AppColors.success
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _requiredProofIsReady(
                                  role, role.requiredProofQualifications.first)
                              ? l10n.providerRoleRequiredProofIncluded
                              : l10n.providerRoleRequiredProofHint,
                          style: TextStyle(
                            fontSize: 11,
                            color: _requiredProofIsReady(role,
                                    role.requiredProofQualifications.first)
                                ? AppColors.success
                                : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              for (final qual in role.qualifications)
                Builder(builder: (ctx) {
                  final roleQuals = widget.qualificationsByRole
                      .putIfAbsent(role.slug, () => {});
                  final evidenceDraft = widget.evidenceDrafts
                      .where((draft) =>
                          draft.roleSlug == role.slug &&
                          draft.qualificationSlug == qual.slug)
                      .firstOrNull;
                  final capabilitySlug =
                      role.capabilitySlug ?? 'work_${role.slug}';
                  final existingCapability = widget.existingCapabilities
                      .where((capability) =>
                          capability.capabilitySlug == capabilitySlug)
                      .firstOrNull;
                  final existingClaim = existingCapability
                      ?.roleQualificationClaims
                      .where((claim) =>
                          claim['role_slug'] == role.slug &&
                          claim['qualification_slug'] == qual.slug)
                      .firstOrNull;
                  final proofKey = _proofKey(role.slug, qual.slug);
                  final existingStatus = _claimStatusOverrides[proofKey] ??
                      existingClaim?['status']?.toString();
                  final hasUploadedEvidence = evidenceDraft != null ||
                      (existingClaim?['has_evidence'] == true &&
                          existingStatus != 'withdrawn' &&
                          !_withdrawnEvidenceKeys.contains(proofKey));
                  final isChecked = roleQuals.contains(qual.slug) ||
                      evidenceDraft != null ||
                      (existingClaim?['has_evidence'] == true &&
                          existingStatus != 'withdrawn' &&
                          !_withdrawnEvidenceKeys.contains(proofKey));
                  final evidenceStatus = evidenceDraft != null
                      ? AppLocalizations.of(context)!.companyEvidenceUploaded
                      : switch (existingStatus) {
                          'pending_review' => AppLocalizations.of(context)!
                              .companyVerificationPending,
                          'verified' => AppLocalizations.of(context)!
                              .companyEvidenceApproved,
                          'rejected' => AppLocalizations.of(context)!
                              .companyEvidenceRejected,
                          'expired' => AppLocalizations.of(context)!
                              .companyEvidenceExpired,
                          'withdrawn' => 'Proof withdrawn',
                          _ => AppLocalizations.of(context)!
                              .companyEvidenceNotAdded,
                        };
                  final isExistingEvidenceApproved = evidenceDraft == null &&
                      existingClaim?['has_evidence'] == true &&
                      (existingStatus == 'verified' ||
                          (existingStatus == 'expired' &&
                              existingClaim?['verified_at'] != null));
                  final acceptsProof = role.acceptsProofFor(qual);
                  final isRequiredProof =
                      role.isRequiredProofQualification(qual);

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final border =
                      isDark ? AppColors.borderDark : AppColors.borderLight;
                  const activeColor = AppColors.proPurple;

                  return Column(
                    children: [
                      InkWell(
                        onTap: isChecked
                            ? () => _untickQualification(
                                  role: role,
                                  qualification: qual,
                                  roleQualifications: roleQuals,
                                  existingCapability: existingCapability,
                                  existingClaim: existingClaim,
                                  evidenceDraft: evidenceDraft,
                                )
                            : () => setState(
                                  () => roleQuals.add(qual.slug),
                                ),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      qual.name,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (isRequiredProof) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.providerPolicyNeedsProofTag,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade800,
                                        ),
                                      ),
                                    ],
                                    if (acceptsProof)
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              evidenceStatus,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: evidenceDraft != null
                                                    ? AppColors.proPurple
                                                    : existingStatus ==
                                                            'rejected'
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .error
                                                        : text2,
                                              ),
                                            ),
                                          ),
                                          if (existingStatus ==
                                                  'pending_review' &&
                                              hasUploadedEvidence) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.lock_outline_rounded,
                                                size: 12, color: text2),
                                          ],
                                          if (isExistingEvidenceApproved) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.lock_rounded,
                                              size: 12,
                                              color: AppColors.success,
                                            ),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (acceptsProof &&
                                  isChecked &&
                                  !isExistingEvidenceApproved)
                                IconButton(
                                  tooltip: 'Upload proof for ${qual.name}',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: isExistingEvidenceApproved
                                      ? null
                                      : () => _pickQualificationEvidence(
                                            target: (role, qual),
                                          ),
                                  icon: const Icon(
                                    Icons.file_upload_outlined,
                                    color: AppColors.proPurple,
                                    size: 20,
                                  ),
                                ),
                              if (evidenceDraft != null)
                                IconButton(
                                  tooltip: AppLocalizations.of(context)!
                                      .companyDocumentRemove,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() {
                                    widget.evidenceDrafts.remove(evidenceDraft);
                                  }),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.proPurple,
                                    size: 20,
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

            if (widget.showSharedPreferencesHint) ...[
              Text(
                l10n.providerWorkPreferencesSharedHint,
                style: TextStyle(
                  fontSize: 11,
                  color: text2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
            ],

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
            Text(
              l10n.expectedPay,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                    decoration: InputDecoration(
                      labelText:
                          l10n.amountLabelWithCurrency(widget.defaultCurrency),
                      prefixText: '${widget.defaultCurrency} ',
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: l10n.payPeriod,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in _payPeriods)
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                            '/ ${switch (p) {
                              'hour' => l10n.perHour,
                              'day' => l10n.perDay,
                              'week' => l10n.perWeek,
                              'month' => l10n.perMonth,
                              'project' => l10n.perProject,
                              _ => p,
                            }}',
                          ),
                        ),
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
            onPressed: _allRequiredProofsReady ? widget.onSave : null,
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
