// lib/features/provider/presentation/pages/provider_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/domain/models/user_profile.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../job_profile/data/job_profile_repository.dart';
import '../../../job_profile/domain/models/job_profile.dart';
import '../../../job_profile/presentation/widgets/work_profile_section.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_opportunity.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import '../cubit/capabilities_cubit.dart';
import '../cubit/capabilities_state.dart';
import '../widgets/capability_badge.dart';
import '../widgets/provider_opportunities_section.dart';
import 'add_service_sheet.dart';
import 'capability_detail_sheet.dart';

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
          final needsRepo = getIt<NeedsRepository>();
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.providerServicesTitle),
                centerTitle: false,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Offer Services'),
                    Tab(text: 'Available for Jobs'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _ErrorCategoryTab(
                    needsRepository: needsRepo,
                    title: 'Professional Categories',
                    subtitle:
                        'Choose what you offer. Categories stay on this page.',
                    errorMessage: state.message,
                    onSelectCategory: (category) => _showAddSheet(
                      context,
                      preselectedCategorySlug: category.slug,
                    ),
                  ),
                  _ErrorCategoryTab(
                    needsRepository: needsRepo,
                    title: 'Job Categories',
                    subtitle: 'Choose where you are available for work.',
                    errorMessage: state.message,
                    onSelectCategory: (_) {},
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state as CapabilitiesLoaded;
        final caps = loaded.capabilities;
        final opps = loaded.opportunities;
        final profileState = context.watch<ProfileCubit>().state;
        final profile =
            profileState is ProfileCubitLoaded ? profileState.profile : null;
        final needsRepo = getIt<NeedsRepository>();
        final workProfileRepository = getIt.isRegistered<JobProfileRepository>()
            ? getIt<JobProfileRepository>()
            : (getIt.isRegistered<supabase.SupabaseClient>()
                ? JobProfileRepository(getIt<supabase.SupabaseClient>())
                : null);

        // ── Screen A: unified summary when capability profiles flag is ON ──
        if (loaded.capabilityProfilesEnabled) {
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
                workProfilesEnabled: loaded.workProfilesEnabled,
                needsRepository: needsRepo,
                isDark: isDark,
                l10n: l10n,
                onAddService: () => _showAddSheet(context),
                onTapCapability: (cap) => _showCapabilityDetail(
                  context,
                  capability: cap,
                  opps: opps,
                  l10n: l10n,
                ),
                onEditCompanyDetails: (cap) => _showAddSheet(
                  context,
                  preselectedCategorySlug: cap.categorySlug,
                ),
                onRemoveCapability: (cap) => _confirmRemove(context, cap, l10n),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Service'),
            ),
          );
        }

        // ── Legacy 2-tab view when flag is OFF ──
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.providerServicesTitle),
              centerTitle: false,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Offer Services'),
                  Tab(text: 'Available for Jobs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () =>
                      context.read<CapabilitiesCubit>().loadWithOpportunities(),
                  child: _OfferServicesTab(
                    capabilities: caps,
                    opportunities: opps,
                    capabilityProfilesEnabled: loaded.capabilityProfilesEnabled,
                    needsRepository: needsRepo,
                    isDark: isDark,
                    onSelectCategory: (category) => _showAddSheet(
                      context,
                      preselectedCategorySlug: category.slug,
                    ),
                    onRemove: (capability) =>
                        _confirmRemove(context, capability, l10n),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () =>
                      context.read<CapabilitiesCubit>().loadWithOpportunities(),
                  child: _AvailableJobsTab(
                    needsRepository: needsRepo,
                    workProfileRepository: workProfileRepository,
                    profile: profile,
                    onSelectCategory: (category) => _showWorkProfileEditor(
                      context,
                      needsRepository: needsRepo,
                      profile: profile,
                      preselectedCategorySlug: category.slug,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddSheet(
    BuildContext context, {
    String? preselectedCategorySlug,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
    final l10n = AppLocalizations.of(context)!;
    final loaded = cubit.state;
    final existingSlugs = loaded is CapabilitiesLoaded
        ? loaded.capabilities.map((c) => c.capabilitySlug).toSet()
        : <String>{};
    final existingFinancialMetadata = loaded is CapabilitiesLoaded
        ? loaded.capabilities
            .where((cap) => const {
                  'bank_loan_agent',
                  'money_lender_private_lender',
                  'financial_advisory',
                  'forex_currency_exchange',
                  'loan_services',
                  'sacco_microfinance',
                  'other_financial_services',
                }.contains(cap.capabilitySlug))
            .firstOrNull
            ?.metadata
        : null;

    final profileState = context.read<ProfileCubit>().state;
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
    );
    if (selection?.companyPath == true) {
      await cubit.loadWithOpportunities();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.companyProfileSaved)),
        );
      }
      return;
    }
    if (selection != null &&
        (selection.slugs.isNotEmpty || selection.metadataBySlug.isNotEmpty)) {
      await cubit.addCapabilities(
        selection.slugs,
        metadataBySlug: selection.metadataBySlug,
      );
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
    } else if (selection != null &&
        selection.openWorkProfile &&
        context.mounted) {
      await WorkProfileEditorSheet.show(
        context,
        repository: getIt<JobProfileRepository>(),
        needsRepository: needsRepo,
        defaultCurrency: defaultCurrency,
        preselectedCategorySlug: selection.categorySlug,
      );
      if (context.mounted) {
        await cubit.loadWithOpportunities();
      }
    }
  }

  Future<void> _showWorkProfileEditor(
    BuildContext context, {
    required NeedsRepository needsRepository,
    required UserProfile? profile,
    String? preselectedCategorySlug,
  }) async {
    final defaultCurrency = profile?.incomeCurrency ?? 'UGX';
    await WorkProfileEditorSheet.show(
      context,
      repository: getIt<JobProfileRepository>(),
      needsRepository: needsRepository,
      defaultCurrency: defaultCurrency,
      preselectedCategorySlug: preselectedCategorySlug,
    );
  }

  void _confirmRemove(
    BuildContext context,
    ProviderCapability cap,
    AppLocalizations l10n,
  ) {
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
            onPressed: () {
              Navigator.pop(dCtx);
              cubit.removeCapability(cap.capabilitySlug);
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

  Future<void> _showCapabilityDetail(
    BuildContext context, {
    required ProviderCapability capability,
    required List<ProviderOpportunity> opps,
    required AppLocalizations l10n,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
    final oppCount = opps
        .where((o) => o.capabilitySlug == capability.capabilitySlug)
        .fold<int>(0, (sum, o) => sum + o.opportunityCount);
    await CapabilityDetailSheet.show(
      context,
      capability: capability,
      opportunityCount: oppCount,
      hiddenForCompanyOnly: !capability.isWork &&
          (cubit.state is CapabilitiesLoaded) &&
          (cubit.state as CapabilitiesLoaded)
                  .categoryTypes[capability.categorySlug] ==
              ProviderCategoryType.individual,
      onEdit: () => _showAddSheet(
        context,
        preselectedCategorySlug: capability.categorySlug,
      ),
      onTogglePause: (paused) => cubit.setCapabilityPaused(
        capabilitySlug: capability.capabilitySlug,
        paused: paused,
      ),
      onRemove: () => _confirmRemove(context, capability, l10n),
      onAddProof: () async {
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
              const SnackBar(
                  content:
                      Text('No evidence is configured for this capability.')),
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
          final picked =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked == null) return;
          final uid = client.auth.currentUser?.id;
          if (uid == null) return;
          final extension =
              picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
          final path =
              'evidence/$uid/${capability.capabilitySlug}/${DateTime.now().microsecondsSinceEpoch}.$extension';
          await client.storage.from('provider-evidence').uploadBinary(
                path,
                await picked.readAsBytes(),
                fileOptions: supabase.FileOptions(contentType: picked.mimeType),
              );
          await getIt<IProviderRepository>().submitCapabilityEvidence(
            providerCapabilityId: capability.id,
            requirementKey: key,
            fileUrl: path,
          );
          await cubit.loadWithOpportunities();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Evidence submitted for review.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not submit evidence: $e')),
            );
          }
        }
      },
    );
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
    required this.workProfilesEnabled,
    required this.needsRepository,
    required this.isDark,
    required this.l10n,
    required this.onAddService,
    required this.onTapCapability,
    this.onRemoveCapability,
    this.onEditCompanyDetails,
  });

  final List<ProviderCapability> capabilities;
  final Map<String, ProviderCategoryType> categoryTypes;
  final List<ProviderOpportunity> opportunities;
  final bool workProfilesEnabled;
  final NeedsRepository needsRepository;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onAddService;
  final ValueChanged<ProviderCapability> onTapCapability;
  final ValueChanged<ProviderCapability>? onRemoveCapability;
  final ValueChanged<ProviderCapability>? onEditCompanyDetails;

  @override
  State<_ScreenASummaryView> createState() => _ScreenASummaryViewState();
}

class _ScreenASummaryViewState extends State<_ScreenASummaryView> {
  _CapFilter _filter = _CapFilter.all;

  List<ProviderCapability> get _filtered {
    switch (_filter) {
      case _CapFilter.services:
        return widget.capabilities.where((c) => !c.isWork).toList();
      case _CapFilter.jobs:
        return widget.capabilities.where((c) => c.isWork).toList();
      case _CapFilter.all:
        return widget.capabilities;
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = widget.capabilities;
    final servicesCount = caps.where((c) => !c.isWork).length;
    final jobsCount = caps.where((c) => c.isWork).length;
    final totalJobMatches = widget.opportunities
        .where((o) => caps.any(
              (c) => c.isWork && c.capabilitySlug == o.capabilitySlug,
            ))
        .fold<int>(0, (sum, o) => sum + o.opportunityCount);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Filter chips ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: widget.l10n.providerSummaryAll(caps.length),
                    selected: _filter == _CapFilter.all,
                    onTap: () => setState(() => _filter = _CapFilter.all),
                  ),
                  const SizedBox(width: 8),
                  if (servicesCount > 0) ...[
                    _FilterChip(
                      label: widget.l10n.providerSummaryServices(servicesCount),
                      selected: _filter == _CapFilter.services,
                      color: AppColors.accent,
                      onTap: () =>
                          setState(() => _filter = _CapFilter.services),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _FilterChip(
                    label: widget.l10n.providerSummaryJobs(jobsCount),
                    selected: _filter == _CapFilter.jobs,
                    color: AppColors.proPurple,
                    onTap: () => setState(() => _filter = _CapFilter.jobs),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Capability cards ──
        if (_filtered.isEmpty)
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
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final cap = _filtered[i];
                final oppCount = widget.opportunities
                    .where((o) => o.capabilitySlug == cap.capabilitySlug)
                    .fold<int>(0, (sum, o) => sum + o.opportunityCount);
                return CapabilityBadge(
                  capability: cap,
                  hiddenForCompanyOnly: !cap.isWork &&
                      widget.categoryTypes[cap.categorySlug] ==
                          ProviderCategoryType.individual,
                  showProfileDetails: true,
                  providerType: widget.categoryTypes[cap.categorySlug],
                  onEditCompanyDetails:
                      widget.categoryTypes[cap.categorySlug] ==
                                  ProviderCategoryType.company &&
                              !cap.isWork
                          ? () => widget.onEditCompanyDetails?.call(cap)
                          : null,
                  opportunityCount: oppCount,
                  onTap: () => widget.onTapCapability(cap),
                  onEdit: () => widget.onTapCapability(cap),
                  onTogglePause: (val) {
                    context.read<CapabilitiesCubit>().setCapabilityPaused(
                          capabilitySlug: cap.capabilitySlug,
                          paused: val,
                        );
                  },
                  onRemove: widget.onRemoveCapability != null
                      ? () => widget.onRemoveCapability!(cap)
                      : null,
                );
              },
            ),
          ),

        // ── Work profile strip ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _WorkProfileStrip(
              jobsCount: jobsCount,
              totalJobMatches: totalJobMatches,
              workProfilesEnabled: widget.workProfilesEnabled,
              isDark: widget.isDark,
            ),
          ),
        ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
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

class _WorkProfileStrip extends StatelessWidget {
  const _WorkProfileStrip({
    required this.jobsCount,
    required this.totalJobMatches,
    required this.workProfilesEnabled,
    required this.isDark,
  });

  final int jobsCount;
  final int totalJobMatches;
  final bool workProfilesEnabled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    if (!workProfilesEnabled && jobsCount == 0) {
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Text('💼', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.workProfilesDisabled,
                style: TextStyle(fontSize: 13, color: text2),
              ),
            ),
          ],
        ),
      );
    }

    final summary = jobsCount == 0
        ? l10n.providerNoJobRolesAdded
        : '${l10n.rolesCount(jobsCount)} · ${l10n.providerAvailableForJobs}'
            '${totalJobMatches > 0 ? ' · ${l10n.providerOpenJobsMatch(totalJobMatches)}' : ''}';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.proPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('💼', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workProfileTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: text2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: text2),
        ],
      ),
    );
  }
}

class _ErrorCategoryTab extends StatelessWidget {
  const _ErrorCategoryTab({
    required this.needsRepository,
    required this.title,
    required this.subtitle,
    required this.errorMessage,
    required this.onSelectCategory,
  });

  final NeedsRepository needsRepository;
  final String title;
  final String subtitle;
  final String errorMessage;
  final ValueChanged<NeedCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CategoryEntrySection(
          needsRepository: needsRepository,
          title: title,
          subtitle: subtitle,
          onSelectCategory: onSelectCategory,
        ),
        const SizedBox(height: 16),
        ErrorState(
          message: errorMessage,
          onRetry: () =>
              context.read<CapabilitiesCubit>().loadWithOpportunities(),
        ),
      ],
    );
  }
}

class _OfferServicesTab extends StatelessWidget {
  const _OfferServicesTab({
    required this.capabilities,
    required this.opportunities,
    required this.capabilityProfilesEnabled,
    required this.needsRepository,
    required this.isDark,
    required this.onSelectCategory,
    required this.onRemove,
  });

  final List<ProviderCapability> capabilities;
  final List<ProviderOpportunity> opportunities;
  final bool capabilityProfilesEnabled;
  final NeedsRepository needsRepository;
  final bool isDark;
  final ValueChanged<NeedCategory> onSelectCategory;
  final ValueChanged<ProviderCapability> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          l10n.providerServicesSubtitle,
          style: TextStyle(fontSize: 14, color: text2),
        ),
        if (opportunities.isNotEmpty) ...[
          const SizedBox(height: 12),
          ProviderOpportunitiesSection(
            opportunities: opportunities,
          ),
        ],
        const SizedBox(height: 16),
        _CategoryEntrySection(
          needsRepository: needsRepository,
          title: 'Professional Categories',
          subtitle: 'Choose what you offer. Categories stay on this page.',
          onSelectCategory: onSelectCategory,
        ),
        const SizedBox(height: 16),
        if (capabilities.isEmpty)
          _EmptyState(l10n: l10n, isDark: isDark)
        else ...[
          Text(
            l10n.yourServices,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...capabilities.map(
            (capability) => CapabilityBadge(
              capability: capability,
              showProfileDetails: capabilityProfilesEnabled,
              opportunityCount: opportunities
                  .where((opportunity) =>
                      opportunity.capabilitySlug == capability.capabilitySlug)
                  .fold<int>(
                    0,
                    (sum, opportunity) => sum + opportunity.opportunityCount,
                  ),
              onRemove: () => onRemove(capability),
            ),
          ),
        ],
      ],
    );
  }
}

class _AvailableJobsTab extends StatelessWidget {
  const _AvailableJobsTab({
    required this.needsRepository,
    required this.workProfileRepository,
    required this.profile,
    required this.onSelectCategory,
  });

  final NeedsRepository needsRepository;
  final JobProfileRepository? workProfileRepository;
  final UserProfile? profile;
  final ValueChanged<NeedCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CategoryEntrySection(
          needsRepository: needsRepository,
          title: 'Job Categories',
          subtitle: 'Choose where you are available for work.',
          onSelectCategory: onSelectCategory,
        ),
        const SizedBox(height: 16),
        if (workProfileRepository != null)
          WorkProfileSection(
            repository: workProfileRepository!,
            needsRepository: needsRepository,
            profile: profile,
          ),
      ],
    );
  }
}

class _CategoryEntrySection extends StatefulWidget {
  const _CategoryEntrySection({
    required this.needsRepository,
    required this.title,
    required this.subtitle,
    required this.onSelectCategory,
  });

  final NeedsRepository needsRepository;
  final String title;
  final String subtitle;
  final ValueChanged<NeedCategory> onSelectCategory;

  @override
  State<_CategoryEntrySection> createState() => _CategoryEntrySectionState();
}

class _CategoryEntrySectionState extends State<_CategoryEntrySection> {
  late Future<List<NeedCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.needsRepository.getCategories();
  }

  @override
  void didUpdateWidget(covariant _CategoryEntrySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.needsRepository != widget.needsRepository) {
      _future = widget.needsRepository.getCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final localeCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder<List<NeedCategory>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 92,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = (snapshot.data ?? const <NeedCategory>[])
            .where((category) => category.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 12, color: text2),
                    ),
                  ],
                ),
              ),
              for (final entry in categories.indexed)
                _CategoryEntryTile(
                  category: entry.$2,
                  localeCode: localeCode,
                  showDivider: entry.$1 != categories.length - 1,
                  onTap: () => widget.onSelectCategory(entry.$2),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryEntryTile extends StatelessWidget {
  const _CategoryEntryTile({
    required this.category,
    required this.localeCode,
    required this.showDivider,
    required this.onTap,
  });

  final NeedCategory category;
  final String localeCode;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final description = category.localizedDescription(localeCode);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    category.icon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.localizedName(localeCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: text2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 54, color: border.withValues(alpha: 0.7)),
      ],
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
