// lib/features/listings/presentation/pages/my_listings_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/data/agreement_repository.dart';
import '../../domain/models/my_listing.dart';
import '../cubit/my_listings_cubit.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyListingsCubit>()..load(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MyListingsCubit, MyListingsState>(
        listener: (context, state) {
          if (state is MyListingsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ));
          }
        },
        builder: (context, state) {
          if (state is MyListingsInitial || state is MyListingsLoading) {
            return _LoadingSkeleton();
          }
          if (state is MyListingsError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<MyListingsCubit>().refresh(),
            );
          }
          if (state is MyListingsLoaded) {
            final active = state.listings.where((l) => l.isActive).toList();
            final closed = state.listings
                .where((l) => l.isExpired || l.isCancelled)
                .toList();
            final contracted =
                state.listings.where((l) => l.isContracted).toList();

            // Show empty state if nothing visible
            if (active.isEmpty && closed.isEmpty && contracted.isEmpty) {
              return _EmptyRequestState();
            }
            return _ListingsBody(listings: state.listings);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Listings body ────────────────────────────────────────────────────────────

class _ListingsBody extends StatelessWidget {
  const _ListingsBody({required this.listings});
  final List<MyListing> listings;

  List<MyListing> get _active => listings.where((l) => l.isActive).toList();
  List<MyListing> get _closed =>
      listings.where((l) => l.isExpired || l.isCancelled).toList();
  List<MyListing> get _contracted =>
      listings.where((l) => l.isContracted).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MyListingsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        children: [
          if (_active.isNotEmpty) ...[
            SectionHeader(AppLocalizations.of(context)!.sectionActive(_active.length)),
            ..._active.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () => context.push('/marketplace/${l.id}'),
                    onCancel: () => _confirmCancel(context, l),
                  ),
                )),
          ],
          if (_contracted.isNotEmpty) ...[
            SectionHeader(AppLocalizations.of(context)!.sectionContracted(_contracted.length)),
            ..._contracted.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () {},
                    onCancel: () {},
                    onViewAgreement: () => _openAgreement(context, l),
                  ),
                )),
          ],
          if (_closed.isNotEmpty) ...[
            SectionHeader(AppLocalizations.of(context)!.sectionClosed(_closed.length)),
            ..._closed.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      MyListingCard(listing: l, onTap: () {}, onCancel: () {}),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _openAgreement(BuildContext context, MyListing listing) async {
    try {
      final repo = getIt<AgreementRepository>();
      final agreement = await repo.getAgreementByRequestId(listing.id);
      if (!context.mounted) return;
      if (agreement != null) {
        await context.push('/marketplace/agreement/${agreement.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.contractNotGenerated)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading contract: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _confirmCancel(BuildContext context, MyListing listing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelListing),
        content: Text(
          AppLocalizations.of(context)!.cancelListingConfirm(listing.title),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
            },
            child: Text(AppLocalizations.of(context)!.keepIt),
          ),
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
              context.read<MyListingsCubit>().cancelListing(listing.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppLocalizations.of(context)!.cancelListingBtn),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyRequestState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.request_page_outlined,
      title: AppLocalizations.of(context)!.noLoanRequests,
      subtitle: AppLocalizations.of(context)!.noLoanRequestsSubtitle,
      action: ElevatedButton(
        onPressed: () => context.go(AppRoutes.listingCreate),
        child: Text(AppLocalizations.of(context)!.createLoanRequest),
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SkeletonBox(width: 130, height: 13),
                Spacer(),
                SkeletonBox(width: 55, height: 20, radius: 10),
              ]),
              SizedBox(height: 8),
              SkeletonBox(width: 80, height: 10),
              SizedBox(height: 10),
              SkeletonBox(width: 150, height: 20),
              SizedBox(height: 10),
              Row(children: [
                SkeletonBox(width: 60, height: 20, radius: 10),
                SizedBox(width: 8),
                SkeletonBox(width: 80, height: 10),
              ]),
            ]),
      ),
    );
  }
}
