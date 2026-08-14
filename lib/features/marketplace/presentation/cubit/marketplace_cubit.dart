// lib/features/marketplace/presentation/cubit/marketplace_cubit.dart
import 'dart:async';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/marketplace_item.dart';

part 'marketplace_state.dart';

@injectable
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit(this._repository) : super(const MarketplaceInitial());

  final MarketplaceRepository _repository;
  final int _anonymousFeedSeed = Random().nextInt(0x7fffffff);
  StreamSubscription<List<MarketplaceItem>>? _realtimeSub;
  StreamSubscription<List<MarketplaceItem>>? _forexRealtimeSub;

  String? _districtFilter;
  MarketplaceModule? _moduleFilter;
  String? _viewerFeedKey;

  /// Full, unfiltered listings fetched from the view (kept in memory so we
  /// can re-apply a Pro filter client-side without another network fetch).
  List<MarketplaceItem> _allListings = const [];

  /// Request IDs where the current user has an active (pending/accepted) offer.
  /// Listings matching these are hidden from the marketplace feed.
  Set<String> _myOfferRequestIds = {};

  /// Current Pro filter criteria.
  ProFilterCriteria _proFilter = const ProFilterCriteria();

  // ── Public interface ──────────────────────────────────────────────────────

  Future<void> load({String? district, MarketplaceModule? module}) async {
    if (isClosed) return;
    _districtFilter = district;
    _moduleFilter = module;
    _viewerFeedKey = _resolveViewerFeedKey();
    emit(const MarketplaceLoading());
    try {
      final listings =
          await _repository.getListings(district: district, module: module);
      if (isClosed) return;
      _allListings = listings;
      _myOfferRequestIds = await _fetchMyOfferRequestIds();
      if (isClosed) return;
      _emitLoaded();
      _subscribeRealtime();
    } catch (e) {
      if (isClosed) return;
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> refresh() =>
      load(district: _districtFilter, module: _moduleFilter);

  Future<void> setModuleFilter(MarketplaceModule? module) {
    return load(district: _districtFilter, module: module);
  }

  /// Apply (or replace) Pro Advanced Filters.
  ///
  /// The cubit calls the Pro-gated RPC to get the matching request_id set, then
  /// intersects it with [_allListings] locally.  Non-Pro callers receive an empty
  /// set from the DB and therefore see an empty marketplace — the DB gate handles
  /// all authorisation; the cubit just does the set math.
  Future<void> applyProFilters(ProFilterCriteria criteria) async {
    if (isClosed) return;

    _proFilter = criteria;

    if (!criteria.isActive) {
      // Filters cleared — restore full listing set immediately.
      _emitLoaded();
      return;
    }

    // Mark the current loaded state as "filtering in progress" while the RPC
    // round-trip completes so the UI can show a subtle loading cue.
    if (state is MarketplaceLoaded) {
      emit(
        (state as MarketplaceLoaded)
            .copyWith(proFilterActive: true, proFilterCriteria: criteria),
      );
    }

    final allowedIds = await _repository.getProFilteredRequestIds(
      employmentTypes:
          criteria.employmentTypes.isEmpty ? null : criteria.employmentTypes,
      incomeBrackets:
          criteria.incomeBrackets.isEmpty ? null : criteria.incomeBrackets,
      suggestedTermsOnly: criteria.suggestedTermsOnly,
      verifiedOnly: criteria.verifiedOnly,
    );

    if (isClosed) return;

    final filtered =
        _allListings.where((l) => allowedIds.contains(l.requestId)).toList();

    _emitLoaded(overrideListings: filtered);
  }

  /// Clear all Pro filters and restore the full listing set.
  void clearProFilters() {
    _proFilter = const ProFilterCriteria();
    _emitLoaded();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _emitLoaded({List<MarketplaceItem>? overrideListings}) {
    final visibleListings = (overrideListings ?? _allListings)
        .where((l) => !_myOfferRequestIds.contains(_offerKey(l)))
        .toList();
    final rankedListings = _rankPersonalized(visibleListings);
    final listings = _moduleFilter == null
        ? _interleaveModules(rankedListings)
        : rankedListings;
    emit(MarketplaceLoaded(
      listings: listings,
      activeFilter: _districtFilter ?? 'all',
      moduleFilter: _moduleFilter,
      proFilterCriteria: _proFilter,
      proFilterActive: false,
    ));
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _forexRealtimeSub?.cancel();
    _realtimeSub = _repository.watchListings(module: _moduleFilter).listen(
      (listings) async {
        if (isClosed) return;
        _allListings = listings;
        // Re-apply any active Pro filter on the fresh list.
        if (_proFilter.isActive) {
          await applyProFilters(_proFilter);
        } else {
          _emitLoaded();
        }
      },
      onError: (_) {},
    );
    _forexRealtimeSub =
        _repository.watchForexListings(module: _moduleFilter).listen(
      (listings) async {
        if (isClosed) return;
        _allListings = listings;
        if (_proFilter.isActive) {
          await applyProFilters(_proFilter);
        } else {
          _emitLoaded();
        }
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    _forexRealtimeSub?.cancel();
    return super.close();
  }

  /// Fetch request IDs where the current user has a pending or accepted offer.
  Future<Set<String>> _fetchMyOfferRequestIds() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return {};
      final data = await Supabase.instance.client
          .from(TableNames.loanOffers)
          .select('request_id')
          .eq('lender_id', userId)
          .inFilter('status', ['pending', 'accepted']);
      final keys = (data as List)
          .map((r) => 'loan:${r['request_id'] as String}')
          .toSet();
      final forexData = await Supabase.instance.client
          .from(TableNames.forexOffers)
          .select('request_id')
          .eq('offer_maker_id', userId)
          .inFilter('status', ['pending', 'accepted']);
      keys.addAll(
          (forexData as List).map((r) => 'forex:${r['request_id'] as String}'));
      return keys;
    } catch (_) {
      return {};
    }
  }

  String _offerKey(MarketplaceItem item) =>
      '${item.module == MarketplaceModule.loan ? 'loan' : 'forex'}:${item.requestId}';

  String _resolveViewerFeedKey() {
    try {
      return _repository.currentViewerId ?? 'anon:$_anonymousFeedSeed';
    } catch (_) {
      return 'anon:$_anonymousFeedSeed';
    }
  }

  String get _feedKey => _viewerFeedKey ??= _resolveViewerFeedKey();

  List<MarketplaceItem> _rankPersonalized(List<MarketplaceItem> listings) {
    final ranked = [...listings];
    ranked.sort((a, b) {
      final scoreCompare = _feedScore(b).compareTo(_feedScore(a));
      if (scoreCompare != 0) return scoreCompare;

      final listedCompare = b.listedAt.compareTo(a.listedAt);
      if (listedCompare != 0) return listedCompare;

      return a.requestId.compareTo(b.requestId);
    });
    return ranked;
  }

  double _feedScore(MarketplaceItem item) {
    final now = DateTime.now().toUtc();
    final listedAt = item.listedAt.toUtc();
    final ageHours = now.difference(listedAt).inHours.clamp(0, 24 * 14);
    final freshness = 28 * (1 - (ageHours / (24 * 14)));

    final remaining =
        (item.loan?.expiresAt ?? item.forex!.expiresAt).toUtc().difference(now);
    final urgency = remaining.isNegative
        ? -30
        : remaining.inHours <= 6
            ? 16
            : remaining.inHours <= 24
                ? 10
                : remaining.inHours <= 72
                    ? 4
                    : 0;

    final offers = item.loan?.numberOfOffers ?? item.forex!.numberOfOffers;
    final offerCoverage = switch (offers) {
      0 => 14,
      1 => 8,
      2 => 4,
      >= 6 => -3,
      _ => 0,
    };

    final trust = _trustScore(item);
    final fit = _listingFitScore(item);
    final jitter = _personalizedJitter(item) * 24;

    return freshness + urgency + offerCoverage + trust + fit + jitter;
  }

  double _trustScore(MarketplaceItem item) {
    final rating = item.loan?.trustRatingAvg ?? item.forex?.trustRatingAvg;
    final reviewCount =
        item.loan?.trustReviewCount ?? item.forex?.trustReviewCount ?? 0;
    final completedDeals = item.loan?.trustCompletedDealsCount ??
        item.forex?.trustCompletedDealsCount ??
        0;
    final verified =
        item.loan?.trustIsVerified ?? item.forex?.trustIsVerified ?? false;
    final phoneVerified = item.loan?.trustPhoneVerified ??
        item.forex?.trustPhoneVerified ??
        false;
    final repeat = item.loan?.trustIsRepeatParticipant ??
        item.forex?.trustIsRepeatParticipant ??
        false;

    return (rating == null ? 0 : (rating - 3).clamp(0, 2) * 3) +
        reviewCount.clamp(0, 5) +
        completedDeals.clamp(0, 5) +
        (verified ? 7 : 0) +
        (phoneVerified ? 3 : 0) +
        (repeat ? 2 : 0);
  }

  double _listingFitScore(MarketplaceItem item) {
    final loan = item.loan;
    if (loan != null) {
      return ((loan.isSponsored ? 10 : 0) +
              (loan.hasCollateral ? 5 : 0) +
              (loan.suggestedInterestRatePct != null ? 3 : 0))
          .toDouble();
    }

    final forex = item.forex!;
    return ((forex.preferredRate != null ? 4 : 0) +
            (forex.termsLockedAt != null ? 3 : 0))
        .toDouble();
  }

  double _personalizedJitter(MarketplaceItem item) {
    final dayBucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final key = '$_feedKey|$dayBucket|${item.module}|${item.requestId}';
    return _stableHash(key) / 0x7fffffff;
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  List<MarketplaceItem> _interleaveModules(List<MarketplaceItem> listings) {
    final loans =
        listings.where((l) => l.module == MarketplaceModule.loan).toList();
    final forex =
        listings.where((l) => l.module == MarketplaceModule.forex).toList();

    if (loans.isEmpty || forex.isEmpty) return listings;

    final mixed = <MarketplaceItem>[];
    var loanIndex = 0;
    var forexIndex = 0;
    MarketplaceModule? lastModule;
    var streak = 0;
    final dayBucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final random = Random(_stableHash('$_feedKey|$dayBucket|module-mix'));

    while (loanIndex < loans.length || forexIndex < forex.length) {
      final canPickLoan = loanIndex < loans.length;
      final canPickForex = forexIndex < forex.length;
      final forceSwitch = streak >= 2 && canPickLoan && canPickForex;

      late final MarketplaceModule nextModule;
      if (!canPickLoan) {
        nextModule = MarketplaceModule.forex;
      } else if (!canPickForex) {
        nextModule = MarketplaceModule.loan;
      } else if (forceSwitch) {
        nextModule = lastModule == MarketplaceModule.loan
            ? MarketplaceModule.forex
            : MarketplaceModule.loan;
      } else {
        final loanWeight = loans.length - loanIndex;
        final forexWeight = forex.length - forexIndex;
        final pick = random.nextInt(loanWeight + forexWeight);
        nextModule = pick < loanWeight
            ? MarketplaceModule.loan
            : MarketplaceModule.forex;
      }

      mixed.add(nextModule == MarketplaceModule.loan
          ? loans[loanIndex++]
          : forex[forexIndex++]);

      if (lastModule == nextModule) {
        streak++;
      } else {
        lastModule = nextModule;
        streak = 1;
      }
    }

    return mixed;
  }
}
