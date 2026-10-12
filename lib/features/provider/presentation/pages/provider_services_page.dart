// lib/features/provider/presentation/pages/provider_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/domain/models/user_profile.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../job_profile/data/job_profile_repository.dart';
import '../../../job_profile/presentation/widgets/work_profile_section.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_opportunity.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import '../cubit/capabilities_cubit.dart';
import '../cubit/capabilities_state.dart';
import '../widgets/capability_badge.dart';
import '../widgets/provider_opportunities_section.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        body: BlocBuilder<CapabilitiesCubit, CapabilitiesState>(
          builder: (context, state) {
            if (state is CapabilitiesLoading || state is CapabilitiesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CapabilitiesError) {
              final needsRepo = getIt<NeedsRepository>();
              return TabBarView(
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
              );
            }

            final loaded = state as CapabilitiesLoaded;
            final caps = loaded.capabilities;
            final opps = loaded.opportunities;
            final profileState = context.watch<ProfileCubit>().state;
            final profile = profileState is ProfileCubitLoaded
                ? profileState.profile
                : null;
            final needsRepo = getIt<NeedsRepository>();
            final workProfileRepository =
                JobProfileRepository(getIt<supabase.SupabaseClient>());

            return TabBarView(
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddSheet(
    BuildContext context, {
    String? preselectedCategorySlug,
  }) async {
    final cubit = context.read<CapabilitiesCubit>();
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

    final needsRepo = getIt<NeedsRepository>();
    final providerRepo = getIt<IProviderRepository>();
    final selection = await AddServiceSheet.show(
      context,
      existingSlugs: existingSlugs,
      existingAudienceMetadata: loaded is CapabilitiesLoaded
          ? loaded.capabilities
              .where((cap) => cap.capabilitySlug == 'i_have_an_audience')
              .firstOrNull
              ?.metadata
          : null,
      existingFinancialMetadata: existingFinancialMetadata,
      needsRepository: needsRepo,
      providerRepository: providerRepo,
      capabilityProfilesEnabled:
          loaded is CapabilitiesLoaded && loaded.capabilityProfilesEnabled,
      preselectedCategorySlug: preselectedCategorySlug,
    );
    if (selection != null &&
        (selection.slugs.isNotEmpty || selection.metadataBySlug.isNotEmpty)) {
      await cubit.addCapabilities(
        selection.slugs,
        metadataBySlug: selection.metadataBySlug,
      );
    }

    if (selection != null && selection.openWorkProfile && context.mounted) {
      final profileState = context.read<ProfileCubit>().state;
      final profile =
          profileState is ProfileCubitLoaded ? profileState.profile : null;
      final defaultCurrency = profile?.incomeCurrency ?? 'UGX';

      await WorkProfileEditorSheet.show(
        context,
        repository: getIt<JobProfileRepository>(),
        needsRepository: needsRepo,
        defaultCurrency: defaultCurrency,
        preselectedCategorySlug: selection.categorySlug,
      );
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
  final JobProfileRepository workProfileRepository;
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
        WorkProfileSection(
          repository: workProfileRepository,
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
