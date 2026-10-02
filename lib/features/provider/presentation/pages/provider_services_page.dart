// lib/features/provider/presentation/pages/provider_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../needs/data/needs_repository.dart';
import '../../domain/entities/provider_capability.dart';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                  ),
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

          if (caps.isEmpty) {
            return _EmptyState(l10n: l10n, isDark: isDark);
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<CapabilitiesCubit>().loadWithOpportunities(),
            child: ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
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
                // Capabilities
                ...caps.map(
                  (cap) => CapabilityBadge(
                    capability: cap,
                    phoneVerified: profile?.trustPhoneVerified ?? false,
                    identityVerified: profile?.isKycApproved ?? false,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.addService),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final cubit = context.read<CapabilitiesCubit>();
    final loaded = cubit.state;
    final existingSlugs = loaded is CapabilitiesLoaded
        ? loaded.capabilities.map((c) => c.capabilitySlug).toSet()
        : <String>{};

    final needsRepo = getIt<NeedsRepository>();
    final selection = await AddServiceSheet.show(
      context,
      existingSlugs: existingSlugs,
      existingAudienceMetadata: loaded is CapabilitiesLoaded
          ? loaded.capabilities
              .where((cap) => cap.capabilitySlug == 'i_have_an_audience')
              .firstOrNull
              ?.metadata
          : null,
      needsRepository: needsRepo,
    );
    if (selection != null &&
        (selection.slugs.isNotEmpty || selection.metadataBySlug.isNotEmpty)) {
      await cubit.addCapabilities(
        selection.slugs,
        metadataBySlug: selection.metadataBySlug,
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
