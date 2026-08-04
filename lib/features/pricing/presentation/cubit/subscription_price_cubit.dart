// lib/features/pricing/presentation/cubit/subscription_price_cubit.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/subscription_price_repository.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class SubscriptionPriceState extends Equatable {
  const SubscriptionPriceState();
  @override
  List<Object?> get props => [];
}

class SubscriptionPriceInitial extends SubscriptionPriceState {
  const SubscriptionPriceInitial();
}

class SubscriptionPriceLoading extends SubscriptionPriceState {
  const SubscriptionPriceLoading();
}

class SubscriptionPriceLoaded extends SubscriptionPriceState {
  const SubscriptionPriceLoaded(this.data);
  final SubscriptionPriceData data;
  @override
  List<Object?> get props => [data.countryCode, data.lenderAmount, data.proAmount];
}

class SubscriptionPriceError extends SubscriptionPriceState {
  const SubscriptionPriceError(this.fallback);
  // Even on error we carry the fallback so UI can render without crashing.
  final SubscriptionPriceData fallback;
  @override
  List<Object?> get props => [fallback.countryCode];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

@injectable
class SubscriptionPriceCubit extends Cubit<SubscriptionPriceState> {
  SubscriptionPriceCubit(this._repo)
      : super(const SubscriptionPriceInitial());

  final SubscriptionPriceRepository _repo;

  /// Fetch prices for [countryCode] from the DB.
  /// Always resolves — on failure emits [SubscriptionPriceError] with the
  /// hardcoded fallback so the UI is never stuck.
  Future<void> load(String countryCode, {bool forceRefresh = false}) async {
    emit(const SubscriptionPriceLoading());
    try {
      final data = await _repo.getPricesForCountry(
        countryCode,
        forceRefresh: forceRefresh,
      );
      emit(SubscriptionPriceLoaded(data));
    } catch (_) {
      // Repository already swallows errors and returns fallback,
      // so this catch is a last-resort safety net.
      final fallback = await _repo.getPricesForCountry(countryCode);
      emit(SubscriptionPriceError(fallback));
    }
  }
}
