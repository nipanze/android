// lib/features/marketplace/presentation/cubit/marketplace_cubit.dart
import 'dart:async';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/marketplace_item.dart';

part 'marketplace_state.dart';

@injectable
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit(this._repository) : super(const MarketplaceInitial()) {
    _connectionSubscription = OfflineService().onReconnected.listen((_) {
      if (!isClosed) unawaited(refresh());
    });
  }

  final MarketplaceRepository _repository;
  late final StreamSubscription<void> _connectionSubscription;
  final int _anonymousFeedSeed = Random().nextInt(0x7fffffff);
  StreamSubscription<List<MarketplaceItem>>? _realtimeSub;
  StreamSubscription<List<MarketplaceItem>>? _forexRealtimeSub;

  String? _districtFilter;
  MarketplaceModule? _moduleFilter;
  String? _viewerFeedKey;
  String? _countryFilter;

  /// Full, unfiltered listings fetched from the view (kept in memory so we
  /// can re-apply a Pro filter client-side without another network fetch).
  List<MarketplaceItem> _allListings = const [];

  /// Request IDs where the current user has an active (pending/accepted) offer.
  /// Listings matching these are hidden from the marketplace feed.
  Set<String> _myOfferRequestIds = {};

  /// Current Pro filter criteria.
  ProFilterCriteria _proFilter = const ProFilterCriteria();

  /// Cached allowed request IDs from the last successful Pro filter RPC execution.
  Set<String>? _cachedProFilteredIds;

  // ── Public interface ──────────────────────────────────────────────────────

  Future<void> load(
      {String? district, MarketplaceModule? module, String? country}) async {
    if (isClosed) return;
    _districtFilter = district;
    _moduleFilter = module;
    _countryFilter = country;
    _viewerFeedKey = _resolveViewerFeedKey();

    emit(const MarketplaceLoading());

    try {
      final listings = await _repository.getListings(
          district: district, module: module, country: country);
      if (isClosed) return;
      _allListings = listings;
      _myOfferRequestIds = await _fetchMyOfferRequestIds();
      if (isClosed) return;
      _emitLoaded();
      _subscribeRealtime();
    } catch (e) {
      if (isClosed) return;
      OfflineService().reportRequestFailure(e);
      emit(MarketplaceError(userFacingErrorMessage(e)));
    }
  }

  Future<void> refresh() => load(
      district: _districtFilter,
      module: _moduleFilter,
      country: _countryFilter);

  Future<void> setModuleFilter(MarketplaceModule? module) async {
    if (isClosed) return;
    // If institutionMatchOnly is active and user selects a non-loan module,
    // automatically disable institutionMatchOnly so it stops forcing loan mode.
    if (_proFilter.institutionMatchOnly && module != MarketplaceModule.loan) {
      _proFilter = _proFilter.copyWith(institutionMatchOnly: false);
      _cachedProFilteredIds = null;
    }
    await load(
        district: _districtFilter, module: module, country: _countryFilter);
    if (_proFilter.isActive) {
      await applyProFilters(_proFilter);
    }
  }

  /// Apply (or replace) Pro Advanced Filters.
  ///
  /// The cubit calls the Pro-gated RPC to get the matching request_id set, then
  /// intersects it with [_allListings] locally.  Non-Pro callers receive an empty
  /// set from the DB and therefore see an empty marketplace — the DB gate handles
  /// all authorisation; the cubit just does the set math.
  ///
  /// When [criteria.institutionMatchOnly] is true the feed is automatically
  /// restricted to Loan listings only (institution matching is a loan-only
  /// feature); the module filter is restored when filters are cleared.
  Future<void> applyProFilters(ProFilterCriteria criteria) async {
    if (isClosed) return;

    _proFilter = criteria;

    if (!criteria.isActive) {
      // Filters cleared — restore full listing set immediately.
      _cachedProFilteredIds = null;
      _emitLoaded();
      return;
    }

    // Institution matching is Loan-only: automatically switch module filter
    // to loan if needed without causing a recursive load loop.
    if (criteria.institutionMatchOnly &&
        _moduleFilter != MarketplaceModule.loan) {
      _moduleFilter = MarketplaceModule.loan;
      try {
        _allListings = await _repository.getListings(
            district: _districtFilter,
            module: MarketplaceModule.loan,
            country: _countryFilter);
      } catch (_) {}
    }

    // Mark current state as filtering in progress for UI loading feedback.
    if (state is MarketplaceLoaded) {
      emit(
        (state as MarketplaceLoaded)
            .copyWith(proFilterActive: true, proFilterCriteria: criteria),
      );
    }

    try {
      final allowedIds = await _repository.getProFilteredRequestIds(
        employmentTypes:
            criteria.employmentTypes.isEmpty ? null : criteria.employmentTypes,
        incomeBrackets:
            criteria.incomeBrackets.isEmpty ? null : criteria.incomeBrackets,
        suggestedTermsOnly: criteria.suggestedTermsOnly,
        verifiedOnly: criteria.verifiedOnly,
        institutionMatchOnly: criteria.institutionMatchOnly,
      );

      if (isClosed) return;

      _cachedProFilteredIds = allowedIds;

      final filtered =
          _allListings.where((l) => allowedIds.contains(l.requestId)).toList();

      _emitLoaded(overrideListings: filtered);
    } catch (_) {
      if (isClosed) return;
      // On RPC error, reset proFilterActive so the UI never hangs indefinitely.
      _emitLoaded();
    }
  }

  /// Clear all Pro filters and restore the full listing set.
  void clearProFilters() {
    _proFilter = const ProFilterCriteria();
    _cachedProFilteredIds = null;
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
    _realtimeSub = _repository
        .watchListings(module: _moduleFilter, country: _countryFilter)
        .listen(
      (listings) {
        if (isClosed) return;
        _allListings = listings;
        if (_proFilter.isActive && _cachedProFilteredIds != null) {
          final filtered = _allListings
              .where((l) => _cachedProFilteredIds!.contains(l.requestId))
              .toList();
          _emitLoaded(overrideListings: filtered);
        } else {
          _emitLoaded();
        }
      },
      onError: (_) {},
    );
    _forexRealtimeSub = _repository
        .watchForexListings(module: _moduleFilter, country: _countryFilter)
        .listen(
      (listings) {
        if (isClosed) return;
        _allListings = listings;
        if (_proFilter.isActive && _cachedProFilteredIds != null) {
          final filtered = _allListings
              .where((l) => _cachedProFilteredIds!.contains(l.requestId))
              .toList();
          _emitLoaded(overrideListings: filtered);
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
    _connectionSubscription.cancel();
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
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      return {};
    }
  }

  String _offerKey(MarketplaceItem item) => switch (item.module) {
        MarketplaceModule.loan => 'loan:${item.requestId}',
        MarketplaceModule.forex => 'forex:${item.requestId}',
        MarketplaceModule.needs => 'needs:${item.requestId}',
      };

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

    final expiresAt =
        item.loan?.expiresAt ?? item.forex?.expiresAt ?? item.needs?.expiresAt;
    final double urgency;
    if (expiresAt != null) {
      final remaining = expiresAt.toUtc().difference(now);
      urgency = remaining.isNegative
          ? -30
          : remaining.inHours <= 6
              ? 16
              : remaining.inHours <= 24
                  ? 10
                  : remaining.inHours <= 72
                      ? 4
                      : 0;
    } else if (item.needs?.urgency.toLowerCase() == 'urgent' ||
        item.needs?.urgency.toLowerCase() == 'high') {
      urgency = 10;
    } else {
      urgency = 0;
    }

    final offers = item.loan?.numberOfOffers ??
        item.forex?.numberOfOffers ??
        item.needs?.numberOfOffers ??
        0;
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
    final rating = item.loan?.trustRatingAvg ??
        item.forex?.trustRatingAvg ??
        item.needs?.trustRatingAvg;
    final reviewCount = item.loan?.trustReviewCount ??
        item.forex?.trustReviewCount ??
        item.needs?.trustReviewCount ??
        0;
    final completedDeals = item.loan?.trustCompletedDealsCount ??
        item.forex?.trustCompletedDealsCount ??
        item.needs?.trustCompletedDealsCount ??
        0;
    final verified = item.loan?.trustIsVerified ??
        item.forex?.trustIsVerified ??
        item.needs?.trustIsVerified ??
        false;
    final phoneVerified = item.loan?.trustPhoneVerified ??
        item.forex?.trustPhoneVerified ??
        item.needs?.trustPhoneVerified ??
        false;
    final repeat = item.loan?.trustIsRepeatParticipant ??
        item.forex?.trustIsRepeatParticipant ??
        item.needs?.trustIsRepeatParticipant ??
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

    final forex = item.forex;
    if (forex != null) {
      return ((forex.preferredRate != null ? 4 : 0) +
              (forex.termsLockedAt != null ? 3 : 0))
          .toDouble();
    }

    final needs = item.needs;
    if (needs != null) {
      return ((needs.capabilitySlug != null ? 4 : 0) +
              (needs.budget > 0 ? 3 : 0))
          .toDouble();
    }

    return 0.0;
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
    final modules = [
      listings.where((l) => l.module == MarketplaceModule.loan).toList(),
      listings.where((l) => l.module == MarketplaceModule.forex).toList(),
      listings.where((l) => l.module == MarketplaceModule.needs).toList(),
    ].where((list) => list.isNotEmpty).toList();

    if (modules.length <= 1) return listings;

    final indices = List<int>.filled(modules.length, 0);
    final mixed = <MarketplaceItem>[];
    int? lastModuleIdx;
    var streak = 0;
    final dayBucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final random = Random(_stableHash('$_feedKey|$dayBucket|module-mix'));

    while (true) {
      final availableIndices = <int>[];
      for (var i = 0; i < modules.length; i++) {
        if (indices[i] < modules[i].length) {
          availableIndices.add(i);
        }
      }
      if (availableIndices.isEmpty) break;

      int selectedIdx;
      if (availableIndices.length == 1) {
        selectedIdx = availableIndices.first;
      } else if (streak >= 2 &&
          lastModuleIdx != null &&
          availableIndices.any((i) => i != lastModuleIdx)) {
        final otherIndices =
            availableIndices.where((i) => i != lastModuleIdx).toList();
        selectedIdx = otherIndices[random.nextInt(otherIndices.length)];
      } else {
        final totalWeight = availableIndices.fold<int>(
            0, (sum, i) => sum + (modules[i].length - indices[i]));
        var pick = random.nextInt(totalWeight);
        selectedIdx = availableIndices.first;
        for (final i in availableIndices) {
          final weight = modules[i].length - indices[i];
          if (pick < weight) {
            selectedIdx = i;
            break;
          }
          pick -= weight;
        }
      }

      mixed.add(modules[selectedIdx][indices[selectedIdx]++]);
      if (lastModuleIdx == selectedIdx) {
        streak++;
      } else {
        lastModuleIdx = selectedIdx;
        streak = 1;
      }
    }

    return mixed;
  }
}
