// lib/features/provider/presentation/pages/provider_services_page.dart

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../job_profile/data/job_profile_repository.dart';
import '../../../job_profile/domain/models/job_profile.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_opportunity.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import '../cubit/capabilities_cubit.dart';
import '../cubit/capabilities_state.dart';
import '../widgets/provider_verification_chip.dart';
import 'add_service_sheet.dart';

class ProviderServicesPage extends StatelessWidget {
  const ProviderServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<CapabilitiesCubit>()..loadWithOpportunities(),
        ),
        BlocProvider(create: (_) => getIt<ProfileCubit>()..load()),
      ],
      child: const _ProviderServicesView(),
    );
  }
}

class _ProviderServicesView extends StatelessWidget {
  const _ProviderServicesView();

  static const _financeProviderCategorySlugs = <String>{
    'financial_services',
    'investment_services',
    'investment_opportunities',
    'forex_money_services',
    'savings_cooperatives',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CapabilitiesCubit, CapabilitiesState>(
      builder: (context, state) {
        if (state is CapabilitiesLoading || state is CapabilitiesInitial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.providerServicesTitle),
              centerTitle: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CapabilitiesError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.providerServicesTitle),
              centerTitle: false,
            ),
            body: Center(
              child: ErrorState(
                message: state.message,
                onRetry: () =>
                    context.read<CapabilitiesCubit>().loadWithOpportunities(),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              label: const Text('Add Service'),
            ),
          );
        }

        final loaded = state as CapabilitiesLoaded;
        final caps = loaded.capabilities;
        final opps = loaded.opportunities;

        // ── Always show Screen A (unified summary view) ──
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.providerServicesTitle),
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<CapabilitiesCubit>().loadWithOpportunities(),
            child: _ScreenASummaryView(
              capabilities: caps,
              categoryTypes: loaded.categoryTypes,
              opportunities: opps,
              isDark: isDark,
              l10n: l10n,
              onAddService: () => _showAddSheet(context),
              onAddProof: (cap) => _openCapabilityProofDestination(
                context,
                capability: cap,
                l10n: l10n,
              ),
              onEditCategory: (categorySlug) => _showAddSheet(
                context,
                preselectedCategorySlug: categorySlug,
              ),
              onRemoveCapability: (cap) => _confirmRemove(context, cap, l10n),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet(context),
            label: const Text('Add Service'),
          ),
        );
      },
    );
  }

  Future<void> _showAddSheet(
    BuildContext context, {
    String? preselectedCategorySlug,
    String? initialProofRoleSlug,
    bool initialCompanyCertification = false,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
    final l10n = AppLocalizations.of(context)!;
    final loaded = cubit.state;
    final existingSlugs = loaded is CapabilitiesLoaded
        ? loaded.capabilities
            .where((capability) =>
                !capability.isWork ||
                capability.metadata['is_role_active'] != false)
            .map((c) => c.capabilitySlug)
            .toSet()
        : <String>{};
    final existingFinancialMetadata = loaded is CapabilitiesLoaded
        ? loaded.capabilities
            .where((cap) =>
                const {
                  'bank_loan_agent',
                  'money_lender_private_lender',
                  'financial_advisory',
                  'forex_currency_exchange',
                  'loan_services',
                  'sacco_microfinance',
                  'other_financial_services',
                }.contains(cap.capabilitySlug) &&
                (cap.identityType ==
                        loaded.categoryTypes['financial_services']?.name ||
                    cap.identityType == null))
            .firstOrNull
            ?.metadata
        : null;

    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state is! ProfileCubitLoaded) {
      await profileCubit.refresh();
      if (!context.mounted) return;
    }
    final profileState = profileCubit.state;
    final initialPersonalName = profileState is ProfileCubitLoaded
        ? profileState.profile.fullName?.trim() ?? ''
        : '';
    final initialDistrict = profileState is ProfileCubitLoaded
        ? profileState.profile.district
        : null;
    final initialPersonalAvatarUrl = profileState is ProfileCubitLoaded
        ? profileState.profile.avatarUrl
        : null;
    final defaultCurrency = profileState is ProfileCubitLoaded
        ? profileState.profile.incomeCurrency
        : 'UGX';
    final needsRepo = getIt<NeedsRepository>();
    final providerRepo = getIt<IProviderRepository>();
    final selection = await AddServiceSheet.show(
      context,
      existingSlugs: existingSlugs,
      existingCapabilities:
          loaded is CapabilitiesLoaded ? loaded.capabilities : const [],
      existingAudienceMetadata: loaded is CapabilitiesLoaded
          ? loaded.capabilities
              .where((cap) => cap.capabilitySlug == 'i_have_an_audience')
              .firstOrNull
              ?.metadata
          : null,
      existingFinancialMetadata: existingFinancialMetadata,
      needsRepository: needsRepo,
      providerRepository: providerRepo,
      capabilityProfilesEnabled: loaded is CapabilitiesLoaded
          ? loaded.capabilityProfilesEnabled
          : true,
      workProfilesEnabled: loaded is CapabilitiesLoaded
          ? (loaded.workProfilesEnabled ||
              loaded.capabilities.any((c) => c.isWork))
          : true,
      preselectedCategorySlug: preselectedCategorySlug,
      initialPersonalName: initialPersonalName,
      initialDistrict: initialDistrict,
      initialPersonalAvatarUrl: initialPersonalAvatarUrl,
      defaultCurrency: defaultCurrency,
      initialProofRoleSlug: initialProofRoleSlug,
      initialCompanyCertification: initialCompanyCertification,
      onFinancialServicesContinue: (selection) async {
        final saved = await cubit.addCapabilitiesAndReport(
          selection.slugs,
          categorySlug: selection.categorySlug,
          metadataBySlug: selection.metadataBySlug,
        );
        if (saved) {
          unawaited(cubit.loadWithOpportunities());
          return null;
        }
        final saveState = cubit.state;
        return saveState is CapabilitiesError
            ? saveState.message
            : 'Could not save Financial Services. Check your connection and try again.';
      },
    );
    if (selection?.identitySwitchCompleted == true) {
      await cubit.loadWithOpportunities();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.providerIdentitySwitchSuccess)),
        );
      }
      return;
    }
    if (selection?.companyPath == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.companyProfileSaved)),
        );
      }
      if (context.mounted) await cubit.loadWithOpportunities();
      return;
    }
    var capabilitiesSaved = selection?.capabilitiesSaved ?? false;
    if (selection != null &&
        !capabilitiesSaved &&
        (selection.slugs.isNotEmpty ||
            selection.metadataBySlug.isNotEmpty ||
            _financeProviderCategorySlugs.contains(selection.categorySlug))) {
      capabilitiesSaved = await cubit.addCapabilitiesAndReport(
        selection.slugs,
        categorySlug: selection.categorySlug,
        metadataBySlug: selection.metadataBySlug,
      );
    }
    final isFinanceProviderCategorySelection =
        _financeProviderCategorySlugs.contains(selection?.categorySlug);
    if (isFinanceProviderCategorySelection) {
      if (!capabilitiesSaved && context.mounted) {
        final currentState = cubit.state;
        final message = currentState is CapabilitiesError
            ? currentState.message
            : 'Could not save Financial Services. Check your connection and try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 6),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial services saved.')),
        );
      }
      if (context.mounted) await cubit.loadWithOpportunities();
      return;
    }
    await cubit.loadWithOpportunities();

    if (selection != null &&
        selection.workRoles.isNotEmpty &&
        selection.categorySlug != null) {
      final roleDrafts = <JobProfileRoleDraft>[];
      for (final roleSlug in selection.workRoles) {
        final meta = selection.workMetadataByRole[roleSlug] ?? {};
        final kinds = (meta['kind_ids'] as List? ?? const [])
            .map((k) => k.toString())
            .toList();
        final qualifications = (meta['qualification_ids'] as List? ?? const [])
            .map((q) => q.toString())
            .toList();
        final years = meta['years_experience']?.toString();
        roleDrafts.add(
          JobProfileRoleDraft(
            roleSlug: roleSlug,
            yearsExperience: years,
            workTypeSlugs: kinds,
            qualificationSlugs: qualifications,
          ),
        );
      }

      final firstRoleMeta =
          selection.workMetadataByRole[selection.workRoles.first] ?? {};
      final expPay = firstRoleMeta['expected_pay'] as Map<String, dynamic>?;
      final draft = JobProfileDraft(
        categorySlug: selection.categorySlug!,
        preferredCurrency: expPay?['currency']?.toString() ?? defaultCurrency,
        availability: firstRoleMeta['availability']?.toString(),
        expectedPayAmount: expPay?['amount'] as int?,
        expectedPayPeriod: expPay?['period']?.toString(),
        languages: (firstRoleMeta['languages'] as List? ?? const ['English'])
            .map((l) => l.toString())
            .toList(),
        roles: roleDrafts,
      );

      final jobRepo = getIt.isRegistered<JobProfileRepository>()
          ? getIt<JobProfileRepository>()
          : (getIt.isRegistered<supabase.SupabaseClient>()
              ? JobProfileRepository(getIt<supabase.SupabaseClient>())
              : null);

      if (jobRepo != null) {
        try {
          await jobRepo.saveProfile(draft);
        } catch (_) {}
      }
      if (context.mounted) {
        await cubit.loadWithOpportunities();
      }

      var submittedProofs = 0;
      String? proofError;
      for (final proof in selection.roleEvidenceDrafts) {
        try {
          final state = cubit.state;
          final capability = state is CapabilitiesLoaded
              ? state.capabilities
                  .where(
                      (item) => item.capabilitySlug == proof.roleCapabilitySlug)
                  .firstOrNull
              : null;
          if (capability == null) {
            throw StateError(
                'Could not find the saved work profile for ${proof.roleSlug}.');
          }
          final path = await providerRepo.uploadRoleQualificationEvidence(
            capabilitySlug: proof.roleCapabilitySlug,
            roleSlug: proof.roleSlug,
            qualificationSlug: proof.qualificationSlug,
            fileName: proof.fileName,
            mimeType: proof.mimeType,
            bytes: proof.bytes,
          );
          await providerRepo.submitRoleQualificationEvidence(
            providerCapabilityId: capability.id,
            roleSlug: proof.roleSlug,
            qualificationSlug: proof.qualificationSlug,
            evidenceObjectPath: path,
          );
          submittedProofs++;
        } catch (error) {
          proofError ??= error.toString();
        }
      }
      if (submittedProofs > 0 && context.mounted) {
        await cubit.loadWithOpportunities();
      }
      if (context.mounted && selection.roleEvidenceDrafts.isNotEmpty) {
        final message = proofError == null
            ? '$submittedProofs proof${submittedProofs == 1 ? '' : 's'} submitted for review.'
            : submittedProofs > 0
                ? '$submittedProofs proof${submittedProofs == 1 ? '' : 's'} submitted. One or more files could not be submitted: $proofError'
                : 'Work profile saved, but proof could not be submitted: $proofError';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _confirmRemove(
    BuildContext context,
    ProviderCapability cap,
    AppLocalizations l10n,
  ) {
    if (cap.isWork) {
      unawaited(_deactivateWorkRole(context, cap));
      return;
    }
    final cubit = context.read<CapabilitiesCubit>();
    showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.removeService),
        content: Text(l10n.removeServiceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(
              MaterialLocalizations.of(dCtx).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              try {
                await cubit.removeCapability(cap.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userFacingErrorMessage(e)),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.removeService,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateWorkRole(
    BuildContext context,
    ProviderCapability capability,
  ) async {
    final roleSlug = capability.metadata['role_id']?.toString() ??
        capability.capabilitySlug.replaceFirst('work_', '');
    final claims = capability.roleQualificationClaims
        .where((claim) =>
            (claim['role_slug']?.toString() ?? roleSlug) == roleSlug &&
            claim['has_evidence'] == true &&
            (claim['status'] == 'pending_review' ||
                claim['status'] == 'verified'))
        .toList()
      ..sort((a, b) => (a['qualification_slug']?.toString() ?? '')
          .compareTo(b['qualification_slug']?.toString() ?? ''));
    final pendingCount =
        claims.where((claim) => claim['status'] == 'pending_review').length;
    final approvedCount = claims.length - pendingCount;
    if (claims.isNotEmpty) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
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
                              : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Remove ${capability.capabilityName ?? roleSlug}?',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _workRoleRemovalNote(
                  Icons.visibility_off_outlined,
                  'Its specialties and qualifications are hidden from employers.',
                  Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
                if (pendingCount > 0)
                  _workRoleRemovalNote(
                    Icons.schedule_rounded,
                    '$pendingCount proof${pendingCount == 1 ? '' : 's'} under review ${pendingCount == 1 ? 'is' : 'are'} withdrawn.',
                    Colors.amber.shade800,
                  ),
                if (approvedCount > 0)
                  _workRoleRemovalNote(
                    Icons.verified_outlined,
                    '$approvedCount approved Nipanze badge${approvedCount == 1 ? '' : 's'} ${approvedCount == 1 ? 'stops' : 'stop'} showing.',
                    Colors.amber.shade800,
                  ),
                _workRoleRemovalNote(
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
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Remove role'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final expectedClaimStates = claims
        .map((claim) => <String, String>{
              'role_slug': roleSlug,
              'qualification_slug':
                  claim['qualification_slug']?.toString() ?? '',
              'status': claim['status']?.toString() ?? '',
            })
        .toList();
    try {
      final result = await getIt<IProviderRepository>().setWorkRoleActive(
        providerCapabilityId: capability.id,
        roleSlug: roleSlug,
        active: false,
        expectedClaimStates: expectedClaimStates,
      );
      if (!context.mounted) return;
      if (result['changed'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Proof status changed. Review the updated status before removing this role.',
            ),
          ),
        );
        await context.read<CapabilitiesCubit>().loadWithOpportunities();
        return;
      }
      await context.read<CapabilitiesCubit>().loadWithOpportunities();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role removed. Tick it again to restore your answers.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingErrorMessage(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _workRoleRemovalNote(IconData icon, String label, Color color) =>
      Padding(
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

  Future<void> _openCapabilityProofDestination(
    BuildContext context, {
    required ProviderCapability capability,
    required AppLocalizations l10n,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
    final loaded = cubit.state;
    final providerType = loaded is CapabilitiesLoaded
        ? (ProviderCategoryType.fromValue(capability.identityType) ??
            loaded.categoryTypes[capability.categorySlug])
        : ProviderCategoryType.fromValue(capability.identityType);

    if (capability.isWork) {
      final roleSlug = capability.metadata['role_id']?.toString() ??
          capability.capabilitySlug.replaceFirst('work_', '');
      await _showAddSheet(
        context,
        preselectedCategorySlug: capability.categorySlug,
        initialProofRoleSlug: roleSlug,
      );
      return;
    }
    if (providerType == ProviderCategoryType.company) {
      await _showAddSheet(
        context,
        preselectedCategorySlug: capability.categorySlug,
        initialCompanyCertification: true,
      );
      return;
    }

    await _uploadCapabilityProof(context, capability: capability, l10n: l10n);
  }

  Future<void> _uploadCapabilityProof(
    BuildContext context, {
    required ProviderCapability capability,
    required AppLocalizations l10n,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
    var uploadStage = 'loading proof requirements';
    try {
      final client = getIt<supabase.SupabaseClient>();
      final rules = await client
          .from('verification_requirements')
          .select(
              'scope_type, scope_id, provider_type, evidence_requirements, required_evidence')
          .eq('is_active', true)
          .inFilter('provider_type', [
        ((cubit.state is CapabilitiesLoaded)
                    ? (cubit.state as CapabilitiesLoaded)
                        .categoryTypes[capability.categorySlug]
                    : null) ==
                ProviderCategoryType.company
            ? 'company'
            : 'individual',
        'both',
      ]).inFilter('scope_type', ['capability', 'category']);
      final providerType = (cubit.state is CapabilitiesLoaded
                  ? (cubit.state as CapabilitiesLoaded)
                      .categoryTypes[capability.categorySlug]
                  : null) ==
              ProviderCategoryType.company
          ? 'company'
          : 'individual';
      final matching = (rules as List)
          .cast<Map<String, dynamic>>()
          .where((row) =>
              row['provider_type'] == providerType ||
              row['provider_type'] == 'both')
          .toList()
        ..sort((a, b) => (b['provider_type'] == providerType ? 1 : 0)
            .compareTo(a['provider_type'] == providerType ? 1 : 0));
      Map<String, dynamic>? rule;
      for (final type in ['capability', 'category']) {
        rule = matching.cast<Map<String, dynamic>?>().firstWhere(
              (r) =>
                  r?['scope_type'] == type &&
                  r?['scope_id'] ==
                      (type == 'capability'
                          ? capability.capabilitySlug
                          : capability.categorySlug),
              orElse: () => null,
            );
        if (rule != null) break;
      }
      final raw = rule?['evidence_requirements'];
      final labels =
          raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
      final required = (rule?['required_evidence'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
      final keys = {...required, ...labels}
          .where((key) => key.trim().isNotEmpty)
          .toList();
      if (keys.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.providerEvidenceNoRequirements)),
        );
        return;
      }
      if (!context.mounted) return;
      final key = keys.length == 1
          ? keys.single
          : await showDialog<String>(
              context: context,
              builder: (dialogContext) => SimpleDialog(
                title: const Text('Choose evidence type'),
                children: [
                  for (final evidenceKey in keys)
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(dialogContext, evidenceKey),
                      child: Text(evidenceKey),
                    ),
                ],
              ),
            );
      if (key == null) return;
      final evidenceTypes = XTypeGroup(
        label: l10n.companyVerificationTitle,
        extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      final picked = await openFile(acceptedTypeGroups: [evidenceTypes]);
      if (picked == null) return;
      if (await picked.length() > 5 * 1024 * 1024) {
        throw StateError(l10n.companyEvidenceTooLarge);
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw StateError(l10n.companyEvidenceTooLarge);
      }
      final extension = picked.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        _ => '',
      };
      if (mime.isEmpty) throw StateError(l10n.companyEvidenceUnsupported);
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;
      final safeName = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = 'evidence/$uid/${capability.capabilitySlug}/'
          '${DateTime.now().microsecondsSinceEpoch}_$safeName';
      uploadStage = 'uploading the file';
      await client.storage.from('provider-evidence').uploadBinary(
            path,
            bytes,
            fileOptions: supabase.FileOptions(contentType: mime),
          );
      uploadStage = 'saving the proof submission';
      await getIt<IProviderRepository>().submitCapabilityEvidence(
        providerCapabilityId: capability.id,
        requirementKey: key,
        fileUrl: path,
      );
      await cubit.loadWithOpportunities();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.providerEvidenceSubmitted)),
        );
      }
    } catch (e) {
      debugPrint('Provider proof failed while $uploadStage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Screen A — unified summary view (capabilityProfilesEnabled = true)
// ────────────────────────────────────────────────────────────────────────────

enum _CapFilter { all, services, jobs }

class _ScreenASummaryView extends StatefulWidget {
  const _ScreenASummaryView({
    required this.capabilities,
    required this.categoryTypes,
    required this.opportunities,
    required this.isDark,
    required this.l10n,
    required this.onAddService,
    required this.onAddProof,
    required this.onEditCategory,
    this.onRemoveCapability,
  });

  final List<ProviderCapability> capabilities;
  final Map<String, ProviderCategoryType> categoryTypes;
  final List<ProviderOpportunity> opportunities;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onAddService;
  final ValueChanged<ProviderCapability> onAddProof;
  final ValueChanged<String?> onEditCategory;
  final ValueChanged<ProviderCapability>? onRemoveCapability;

  @override
  State<_ScreenASummaryView> createState() => _ScreenASummaryViewState();
}

class _ScreenASummaryViewState extends State<_ScreenASummaryView> {
  _CapFilter _filter = _CapFilter.all;

  bool _belongsToSelectedFinancialIdentity(ProviderCapability capability) {
    if (capability.categorySlug != 'financial_services' ||
        capability.identityType == null) {
      return true;
    }
    final selected = widget.categoryTypes['financial_services'];
    return selected == null || capability.identityType == selected.name;
  }

  List<ProviderCapability> get _visibleCapabilities =>
      widget.capabilities.where((capability) {
        if (!_belongsToSelectedFinancialIdentity(capability)) return false;
        return !capability.isWork ||
            capability.metadata['is_role_active'] != false;
      }).toList();

  Map<String, List<ProviderCapability>> _groupCapabilities(
    Iterable<ProviderCapability> capabilities,
  ) {
    final grouped = <String, List<ProviderCapability>>{};
    for (final capability in capabilities) {
      final key = capability.categorySlug?.isNotEmpty == true
          ? capability.categorySlug!
          : capability.capabilitySlug;
      grouped.putIfAbsent(key, () => []).add(capability);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _visibleCapabilities;
    final allGroups = _groupCapabilities(capabilities);
    final serviceCategoryCount = allGroups.values
        .where((items) => items.any((item) => !item.isWork))
        .length;
    final jobCategoryCount = allGroups.values
        .where((items) => items.any((item) => item.isWork))
        .length;
    final filteredGroups = <MapEntry<String, List<ProviderCapability>>>[];
    for (final entry in allGroups.entries) {
      final items = switch (_filter) {
        _CapFilter.services =>
          entry.value.where((item) => !item.isWork).toList(),
        _CapFilter.jobs => entry.value.where((item) => item.isWork).toList(),
        _CapFilter.all => entry.value,
      };
      if (items.isNotEmpty) {
        filteredGroups.add(MapEntry(entry.key, items));
      }
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: widget.l10n.providerSummaryAll(allGroups.length),
                    selected: _filter == _CapFilter.all,
                    onTap: () => setState(() => _filter = _CapFilter.all),
                  ),
                  const SizedBox(width: 8),
                  if (serviceCategoryCount > 0) ...[
                    _FilterChip(
                      label: widget.l10n
                          .providerSummaryServices(serviceCategoryCount),
                      selected: _filter == _CapFilter.services,
                      color: AppColors.accent,
                      onTap: () =>
                          setState(() => _filter = _CapFilter.services),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _FilterChip(
                    label: widget.l10n.providerSummaryJobs(jobCategoryCount),
                    selected: _filter == _CapFilter.jobs,
                    color: AppColors.proPurple,
                    onTap: () => setState(() => _filter = _CapFilter.jobs),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.categoryTypes.values.contains(ProviderCategoryType.company))
          SliverToBoxAdapter(
            child: _CompanyVerificationSummary(
              categoryTypes: widget.categoryTypes,
              capabilities: capabilities,
              l10n: widget.l10n,
            ),
          ),
        if (filteredGroups.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _EmptyState(l10n: widget.l10n, isDark: widget.isDark),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.builder(
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final entry = filteredGroups[index];
                final items = entry.value;
                final first = items.first;
                final providerType = ProviderCategoryType.fromValue(
                      first.identityType,
                    ) ??
                    widget.categoryTypes[first.categorySlug];
                final opportunitiesByCapability = <String, int>{};
                for (final opportunity in widget.opportunities) {
                  opportunitiesByCapability.update(
                    opportunity.capabilitySlug,
                    (count) => count + opportunity.opportunityCount,
                    ifAbsent: () => opportunity.opportunityCount,
                  );
                }
                return _ProviderCategoryCard(
                  capabilities: items,
                  providerType: providerType,
                  opportunitiesByCapability: opportunitiesByCapability,
                  l10n: widget.l10n,
                  onEdit: () => widget.onEditCategory(first.categorySlug),
                  onAddProof: widget.onAddProof,
                  onTogglePause: (capability, paused) =>
                      context.read<CapabilitiesCubit>().setCapabilityPaused(
                            providerCapabilityId: capability.id,
                            paused: paused,
                          ),
                  onRemove: widget.onRemoveCapability,
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _ProviderCategoryCard extends StatelessWidget {
  const _ProviderCategoryCard({
    required this.capabilities,
    required this.providerType,
    required this.opportunitiesByCapability,
    required this.l10n,
    required this.onEdit,
    required this.onAddProof,
    required this.onTogglePause,
    required this.onRemove,
  });

  final List<ProviderCapability> capabilities;
  final ProviderCategoryType? providerType;
  final Map<String, int> opportunitiesByCapability;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final ValueChanged<ProviderCapability> onAddProof;
  final void Function(ProviderCapability capability, bool paused) onTogglePause;
  final ValueChanged<ProviderCapability>? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final first = capabilities.first;
    final localeCode = Localizations.localeOf(context).languageCode;
    final categorySlug = first.categorySlug ?? '';
    final categoryName = NeedCategory(
      slug: categorySlug,
      name: first.categoryName ?? categorySlug,
      icon: first.categoryIcon ?? '💼',
    ).localizedName(localeCode);
    final categoryKind = providerType == ProviderCategoryType.company
        ? l10n.providerTypeCompany
        : providerType == ProviderCategoryType.individual
            ? l10n.providerTypeIndividual
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(first.categoryIcon ?? '💼',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [categoryName, if (categoryKind != null) categoryKind]
                        .where((item) => item.isNotEmpty)
                        .join(' · '),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: onEdit, child: Text(l10n.edit)),
              ],
            ),
            const Divider(height: 12),
            for (var index = 0; index < capabilities.length; index++) ...[
              if (index > 0) const Divider(height: 16),
              _CategoryCapabilityRow(
                capability: capabilities[index],
                localeCode: localeCode,
                l10n: l10n,
                opportunityCount: opportunitiesByCapability[
                        capabilities[index].capabilitySlug] ??
                    0,
                onAddProof: () => onAddProof(capabilities[index]),
                onTogglePause: (paused) =>
                    onTogglePause(capabilities[index], paused),
                onRemove: onRemove == null
                    ? null
                    : () => onRemove!(capabilities[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCapabilityRow extends StatelessWidget {
  const _CategoryCapabilityRow({
    required this.capability,
    required this.localeCode,
    required this.l10n,
    required this.opportunityCount,
    required this.onAddProof,
    required this.onTogglePause,
    required this.onRemove,
  });

  final ProviderCapability capability;
  final String? localeCode;
  final AppLocalizations l10n;
  final int opportunityCount;
  final VoidCallback onAddProof;
  final ValueChanged<bool> onTogglePause;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isJob = capability.isWork;
    final capabilityName = NeedCapability(
      slug: capability.capabilitySlug,
      categorySlug: capability.categorySlug ?? '',
      name: capability.capabilityName ?? capability.capabilitySlug,
    ).localizedName(localeCode);
    final noProofIndividualLoan =
        capability.categorySlug == 'financial_services' &&
            capability.identityType == 'individual';
    final hasRoleProofToAdd = !isJob ||
        capability.roleQualificationClaims.any(
          (claim) {
            if (claim['is_evidence'] != true) return false;
            final hasEvidence = claim['has_evidence'] == true;
            final status = claim['status']?.toString();
            return !(hasEvidence &&
                (status == 'pending_review' ||
                    status == 'verified' ||
                    (status == 'expired' && claim['verified_at'] != null)));
          },
        );
    final canAddProof = hasRoleProofToAdd &&
        !noProofIndividualLoan &&
        capability.status != ProviderCapabilityStatus.providerVerified;
    final statusNote = switch (capability.status) {
      ProviderCapabilityStatus.pendingReview =>
        l10n.providerCapabilityPendingReview,
      ProviderCapabilityStatus.rejected =>
        capability.latestRejectReason ?? l10n.providerCapabilityRejected,
      ProviderCapabilityStatus.expired => l10n.expired,
      _
          when capability.verificationPolicy ==
                  ProviderVerificationPolicy.requiredProof &&
              capability.status != ProviderCapabilityStatus.providerVerified =>
        l10n.providerPolicyProofRequired,
      _
          when capability.verificationPolicy ==
              ProviderVerificationPolicy.optionalProof =>
        l10n.providerPolicyProofLater,
      _ => '',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isJob
                ? AppColors.proPurple.withValues(alpha: 0.14)
                : AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isJob ? 'Job' : 'Service',
            style: TextStyle(
              fontSize: 10,
              color: isJob ? AppColors.proPurple : AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(capabilityName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ProviderVerificationChip(
                    level: capability.verificationLevel,
                    status: capability.status,
                  ),
                  if (opportunityCount > 0)
                    Text('$opportunityCount open needs match this profile'),
                ],
              ),
              if (statusNote.isNotEmpty || canAddProof) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (statusNote.isNotEmpty)
                      Expanded(
                        child: Text(
                          statusNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    if (canAddProof)
                      TextButton(
                        onPressed: onAddProof,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(l10n.companyEvidenceAdd),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.edit,
          onSelected: (value) {
            if (value == 'pause') onTogglePause(!capability.isPaused);
            if (value == 'remove') onRemove?.call();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pause',
              child: Text(capability.isPaused ? 'Resume' : 'Pause'),
            ),
            if (onRemove != null)
              PopupMenuItem(value: 'remove', child: Text(l10n.removeService)),
          ],
        ),
      ],
    );
  }
}

class _CompanyVerificationSummary extends StatelessWidget {
  const _CompanyVerificationSummary({
    required this.categoryTypes,
    required this.capabilities,
    required this.l10n,
  });

  final Map<String, ProviderCategoryType> categoryTypes;
  final List<ProviderCapability> capabilities;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final categories = categoryTypes.entries
        .where((entry) => entry.value == ProviderCategoryType.company)
        .map((entry) => entry.key)
        .toList();
    final userId = supabase.Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || categories.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.Supabase.instance.client
          .from(TableNames.providerCompanyVerificationSubmissions)
          .select('category_slug, document_type, status, reject_reason')
          .eq('user_id', userId)
          .inFilter('category_slug', categories),
      builder: (context, snapshot) {
        final rows = (snapshot.data ?? const <Map<String, dynamic>>[]);
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.companyVerificationTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  for (final slug in categories) ...[
                    const SizedBox(height: 6),
                    Builder(builder: (context) {
                      final docs = rows
                          .where((row) => row['category_slug'] == slug)
                          .toList();
                      final statuses = docs.map((row) => row['status']).toSet();
                      final status = statuses.contains('pending')
                          ? l10n.companyVerificationPending
                          : statuses.contains('rejected')
                              ? l10n.companyVerificationRejected
                              : statuses.contains('approved')
                                  ? l10n.companyVerificationVerified
                                  : l10n.companyVerificationNotSubmitted;
                      final categoryName = capabilities
                              .where((cap) => cap.categorySlug == slug)
                              .map((cap) => cap.categoryName)
                              .firstOrNull ??
                          slug.replaceAll('_', ' ');
                      final reason = docs
                          .where((row) => row['status'] == 'rejected')
                          .map((row) => row['reject_reason']?.toString())
                          .whereType<String>()
                          .firstOrNull;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.business_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(categoryName,
                                    style: theme.textTheme.bodyMedium),
                                Text(
                                    reason == null
                                        ? status
                                        : '$status · $reason',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.accent;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? activeColor : null,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛠️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              l10n.noServicesYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noServicesYetSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
