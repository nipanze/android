// lib/features/marketplace/presentation/cubit/marketplace_cubit.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/loan_listing.dart';

part 'marketplace_state.dart';

@injectable
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit(this._repository) : super(const MarketplaceInitial());

  final MarketplaceRepository _repository;
  StreamSubscription<List<LoanListing>>? _realtimeSub;

  String? _districtFilter;

  /// Full, unfiltered listings fetched from the view (kept in memory so we
  /// can re-apply a Pro filter client-side without another network fetch).
  List<LoanListing> _allListings = const [];

  /// Current Pro filter criteria.
  ProFilterCriteria _proFilter = const ProFilterCriteria();

  // ── Public interface ──────────────────────────────────────────────────────

  Future<void> load({String? district}) async {
    if (isClosed) return;
    _districtFilter = district;
    emit(const MarketplaceLoading());
    try {
      _allListings = await _repository.getListings(district: district);
      if (isClosed) return;
      _emitLoaded();
      _subscribeRealtime();
    } catch (e) {
      if (isClosed) return;
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> refresh() => load(district: _districtFilter);

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

    final filtered = _allListings
        .where((l) => allowedIds.contains(l.requestId))
        .toList();

    _emitLoaded(overrideListings: filtered);
  }

  /// Clear all Pro filters and restore the full listing set.
  void clearProFilters() {
    _proFilter = const ProFilterCriteria();
    _emitLoaded();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _emitLoaded({List<LoanListing>? overrideListings}) {
    final listings = overrideListings ?? _allListings;
    emit(MarketplaceLoaded(
      listings: listings,
      activeFilter: _districtFilter ?? 'all',
      proFilterCriteria: _proFilter,
      proFilterActive: false,
    ));
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _repository.watchListings().listen(
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
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
