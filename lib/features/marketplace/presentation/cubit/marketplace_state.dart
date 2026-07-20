// lib/features/marketplace/presentation/cubit/marketplace_state.dart
part of 'marketplace_cubit.dart';

/// Immutable criteria for the Pro Advanced Filters bottom sheet.
/// All fields are nullable / default-false — a fully-default instance means
/// "no Pro filter active", which the cubit uses to skip the RPC call entirely.
class ProFilterCriteria extends Equatable {
  const ProFilterCriteria({
    this.employmentTypes = const [],
    this.incomeBrackets = const [],
    this.suggestedTermsOnly = false,
    this.verifiedOnly = false,
  });

  final List<String> employmentTypes;
  final List<String> incomeBrackets;
  final bool suggestedTermsOnly;
  final bool verifiedOnly;

  /// True when at least one filter is actually active.
  bool get isActive =>
      employmentTypes.isNotEmpty ||
      incomeBrackets.isNotEmpty ||
      suggestedTermsOnly ||
      verifiedOnly;

  ProFilterCriteria copyWith({
    List<String>? employmentTypes,
    List<String>? incomeBrackets,
    bool? suggestedTermsOnly,
    bool? verifiedOnly,
  }) {
    return ProFilterCriteria(
      employmentTypes: employmentTypes ?? this.employmentTypes,
      incomeBrackets: incomeBrackets ?? this.incomeBrackets,
      suggestedTermsOnly: suggestedTermsOnly ?? this.suggestedTermsOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  /// Resets all criteria to defaults (no filter).
  ProFilterCriteria cleared() => const ProFilterCriteria();

  @override
  List<Object?> get props =>
      [employmentTypes, incomeBrackets, suggestedTermsOnly, verifiedOnly];
}

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();

  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceLoaded extends MarketplaceState {
  const MarketplaceLoaded({
    required this.listings,
    required this.activeFilter,
    this.proFilterCriteria = const ProFilterCriteria(),
    this.proFilterActive = false,
  });

  final List<LoanListing> listings;
  final String activeFilter;

  /// Current Pro filter criteria (always present; `.isActive` tells you
  /// whether they have any effect on the displayed listing set).
  final ProFilterCriteria proFilterCriteria;

  /// True while the Pro filter RPC result is being applied to the feed.
  final bool proFilterActive;

  MarketplaceLoaded copyWith({
    List<LoanListing>? listings,
    String? activeFilter,
    ProFilterCriteria? proFilterCriteria,
    bool? proFilterActive,
  }) {
    return MarketplaceLoaded(
      listings: listings ?? this.listings,
      activeFilter: activeFilter ?? this.activeFilter,
      proFilterCriteria: proFilterCriteria ?? this.proFilterCriteria,
      proFilterActive: proFilterActive ?? this.proFilterActive,
    );
  }

  @override
  List<Object?> get props =>
      [listings, activeFilter, proFilterCriteria, proFilterActive];
}

class MarketplaceError extends MarketplaceState {
  const MarketplaceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
