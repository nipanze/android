// lib/features/provider/presentation/pages/provider_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../job_profile/data/job_profile_repository.dart';
import '../../../job_profile/presentation/widgets/work_profile_section.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providerServicesTitle),
        centerTitle: false,
      ),
      body: BlocBuilder<CapabilitiesCubit, CapabilitiesState>(
        builder: (context, state) {
          if (state is CapabilitiesLoading || state is CapabilitiesInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CapabilitiesError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _AddServiceEntryCard(
                  onAdd: () => _showAddSheet(context),
                ),
                const SizedBox(height: 16),
                ErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<CapabilitiesCubit>().loadWithOpportunities(),
                ),
              ],
            );
          }

          final loaded = state as CapabilitiesLoaded;
          final caps = loaded.capabilities;
          final opps = loaded.opportunities;
          final profileState = context.watch<ProfileCubit>().state;
          final profile =
              profileState is ProfileCubitLoaded ? profileState.profile : null;
          final needsRepo = getIt<NeedsRepository>();
          final workProfileRepository =
              JobProfileRepository(getIt<supabase.SupabaseClient>());

          if (caps.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _AddServiceEntryCard(
                  onAdd: () => _showAddSheet(context),
                ),
                const SizedBox(height: 16),
                _CategoryEntrySection(
                  needsRepository: needsRepo,
                  onViewAll: () => _showAddSheet(context),
                  onSelectCategory: (category) => _showAddSheet(
                    context,
                    preselectedCategorySlug: category.slug,
                  ),
                ),
                const SizedBox(height: 16),
                WorkProfileSection(
                  repository: workProfileRepository,
                  needsRepository: needsRepo,
                  profile: profile,
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: _EmptyState(l10n: l10n, isDark: isDark),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<CapabilitiesCubit>().loadWithOpportunities(),
            child: ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 24),
              children: [
                // Subtitle
                Text(
                  l10n.providerServicesSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                  ),
                ),
                const SizedBox(height: 4),
                // Opportunities
                if (opps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ProviderOpportunitiesSection(
                    opportunities: opps,
                  ),
                ],
                const SizedBox(height: 16),
                WorkProfileSection(
                  repository: workProfileRepository,
                  needsRepository: needsRepo,
                  profile: profile,
                ),
                const SizedBox(height: 16),
                _CategoryEntrySection(
                  needsRepository: needsRepo,
                  onViewAll: () => _showAddSheet(context),
                  onSelectCategory: (category) => _showAddSheet(
                    context,
                    preselectedCategorySlug: category.slug,
                  ),
                ),
                const SizedBox(height: 16),
                // Capabilities
                ...caps.map(
                  (cap) => CapabilityBadge(
                    capability: cap,
                    showProfileDetails: loaded.capabilityProfilesEnabled,
                    opportunityCount: opps
                        .where((o) => o.capabilitySlug == cap.capabilitySlug)
                        .fold<int>(0, (sum, o) => sum + o.opportunityCount),
                    onRemove: () => _confirmRemove(context, cap, l10n),
                  ),
                ),
              ],
            ),
          );
        },
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

class _AddServiceEntryCard extends StatelessWidget {
  const _AddServiceEntryCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.addService,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.providerServicesSubtitle,
                      style: TextStyle(fontSize: 12, color: text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAdd,
                tooltip: l10n.addService,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  fixedSize: const Size.square(40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryEntrySection extends StatefulWidget {
  const _CategoryEntrySection({
    required this.needsRepository,
    required this.onSelectCategory,
    required this.onViewAll,
  });

  final NeedsRepository needsRepository;
  final ValueChanged<NeedCategory> onSelectCategory;
  final VoidCallback onViewAll;

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

        final visibleCategories = categories.take(6).toList();

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
                      'Add another service',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a category to add services or job availability.',
                      style: TextStyle(fontSize: 12, color: text2),
                    ),
                  ],
                ),
              ),
              for (final entry in visibleCategories.indexed)
                _CategoryEntryTile(
                  category: entry.$2,
                  localeCode: localeCode,
                  showDivider: entry.$1 != visibleCategories.length - 1,
                  onTap: () => widget.onSelectCategory(entry.$2),
                ),
              if (categories.length > visibleCategories.length)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('View all categories'),
                  ),
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
