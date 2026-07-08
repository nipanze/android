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

  Future<void> load({String? district}) async {
    if (isClosed) return;
    _districtFilter = district;
    emit(const MarketplaceLoading());
    try {
      final listings = await _repository.getListings(
        district: district,
      );
      if (isClosed) return;
      emit(MarketplaceLoaded(
          listings: listings, activeFilter: district ?? 'all'));
      _subscribeRealtime();
    } catch (e) {
      if (isClosed) return;
      emit(MarketplaceError(e.toString()));
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _repository.watchListings().listen(
      (listings) {
        if (!isClosed) {
          // Note: watchListings returns all, but we might want to apply the current filter locally
          // or re-fetch properly. For MVP, we'll just emit since Realtime usually handles single row updates.
          emit(MarketplaceLoaded(
            listings: listings,
            activeFilter: _districtFilter ?? 'all',
          ));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> refresh() => load(district: _districtFilter);

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
