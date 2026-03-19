// ignore_for_file: unused_import, directives_ordering

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opencapital/core/errors/app_errors.dart';
import 'package:opencapital/features/marketplace/data/marketplace_repository.dart';
import 'package:opencapital/shared/models/loan_listing_model.dart';

import '../../../shared/models/loan_listing_model.dart';
import '../data/marketplace_repository.dart';
import '../../../core/errors/app_errors.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  @override List<Object?> get props => [];
}
class MarketplaceInitial extends MarketplaceState { const MarketplaceInitial(); }
class MarketplaceLoading extends MarketplaceState { const MarketplaceLoading(); }
class MarketplaceLoaded extends MarketplaceState {
  const MarketplaceLoaded(this.listings, {this.filteredListings});
  final List<LoanListingModel> listings;
  final List<LoanListingModel>? filteredListings;
  List<LoanListingModel> get display => filteredListings ?? listings;
  @override List<Object?> get props => [listings, filteredListings];
}
class MarketplaceError extends MarketplaceState {
  const MarketplaceError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}

class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit({required this.repository}) : super(const MarketplaceInitial());

  final MarketplaceRepository repository;
  StreamSubscription<List<LoanListingModel>>? _sub;
  List<LoanListingModel> _all = [];

  void watch() {
    emit(const MarketplaceLoading());
    _sub?.cancel();
    _sub = repository.watchListings().listen(
      (listings) {
        _all = listings;
        emit(MarketplaceLoaded(listings));
      },
      onError: (e) => emit(MarketplaceError(parseSupabaseError(e).message)),
    );
  }

  void applyFilters({
    String? purpose,
    String? district,
    String? riskCategory,
    double? maxRate,
  }) {
    var filtered = List<LoanListingModel>.from(_all);
    if (purpose != null && purpose.isNotEmpty) {
      filtered = filtered.where((l) => l.purpose == purpose).toList();
    }
    if (district != null && district.isNotEmpty) {
      filtered = filtered.where((l) => l.district == district).toList();
    }
    if (riskCategory != null && riskCategory.isNotEmpty) {
      filtered = filtered.where((l) => l.riskCategory == riskCategory).toList();
    }
    if (maxRate != null) {
      filtered = filtered
          .where((l) => l.maxInterestRate == null || l.maxInterestRate! <= maxRate)
          .toList();
    }
    emit(MarketplaceLoaded(_all, filteredListings: filtered));
  }

  void clearFilters() => emit(MarketplaceLoaded(_all));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
