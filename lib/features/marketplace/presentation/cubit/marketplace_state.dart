// lib/features/marketplace/presentation/cubit/marketplace_state.dart
part of 'marketplace_cubit.dart';

/// Immutable criteria for the Pro Advanced Filters bottom sheet.
/// All fields are nullable / default-false — a fully-default instance means
/// "no Pro filter active", which the cubit uses to skip the RPC call entirely.
class ProFilterCriteria extends Equatable {
  const ProFilterCriteria({
    this.moduleFilter,
    this.employmentTypes = const [],
    this.incomeBrackets = const [],
    this.suggestedTermsOnly = false,
    this.verifiedOnly = false,
    this.institutionMatchOnly = false,
    this.amountBands = const [],
    this.location = '',
    this.favoriteCurrencies = const [],
    this.needType = '',
    this.urgency = '',
    this.hasClearBudget = false,
    this.amongFirst = false,
    this.matchesMyCategories = false,
    this.myNeedCategorySlugs = const [],
    this.myRoleCapabilitySlugs = const [],
  });

  final MarketplaceModule? moduleFilter;
  final List<String> employmentTypes;
  final List<String> incomeBrackets;
  final bool suggestedTermsOnly;
  final bool verifiedOnly;
  final bool institutionMatchOnly;
  final List<String> amountBands;
  final String location;
  final List<String> favoriteCurrencies;
  final String needType;
  final String urgency;
  final bool hasClearBudget;
  final bool amongFirst;
  final bool matchesMyCategories;
  final List<String> myNeedCategorySlugs;
  final List<String> myRoleCapabilitySlugs;

  /// True when at least one filter is actually active.
  bool get isActive {
    final shared =
        verifiedOnly || amountBands.isNotEmpty || location.isNotEmpty;
    final typeSpecific = switch (moduleFilter) {
      MarketplaceModule.loan => employmentTypes.isNotEmpty ||
          incomeBrackets.isNotEmpty ||
          suggestedTermsOnly ||
          institutionMatchOnly,
      MarketplaceModule.forex => favoriteCurrencies.isNotEmpty,
      MarketplaceModule.needs => needType.isNotEmpty ||
          urgency.isNotEmpty ||
          hasClearBudget ||
          amongFirst ||
          matchesMyCategories,
      null => false,
    };
    return shared || typeSpecific || moduleFilter != null;
  }

  ProFilterCriteria copyWith({
    List<String>? employmentTypes,
    List<String>? incomeBrackets,
    bool? suggestedTermsOnly,
    bool? verifiedOnly,
    bool? institutionMatchOnly,
    MarketplaceModule? moduleFilter,
    List<String>? amountBands,
    String? location,
    List<String>? favoriteCurrencies,
    String? needType,
    String? urgency,
    bool? hasClearBudget,
    bool? amongFirst,
    bool? matchesMyCategories,
    List<String>? myNeedCategorySlugs,
    List<String>? myRoleCapabilitySlugs,
  }) {
    return ProFilterCriteria(
      employmentTypes: employmentTypes ?? this.employmentTypes,
      incomeBrackets: incomeBrackets ?? this.incomeBrackets,
      suggestedTermsOnly: suggestedTermsOnly ?? this.suggestedTermsOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      institutionMatchOnly: institutionMatchOnly ?? this.institutionMatchOnly,
      moduleFilter: moduleFilter ?? this.moduleFilter,
      amountBands: amountBands ?? this.amountBands,
      location: location ?? this.location,
      favoriteCurrencies: favoriteCurrencies ?? this.favoriteCurrencies,
      needType: needType ?? this.needType,
      urgency: urgency ?? this.urgency,
      hasClearBudget: hasClearBudget ?? this.hasClearBudget,
      amongFirst: amongFirst ?? this.amongFirst,
      matchesMyCategories: matchesMyCategories ?? this.matchesMyCategories,
      myNeedCategorySlugs: myNeedCategorySlugs ?? this.myNeedCategorySlugs,
      myRoleCapabilitySlugs:
          myRoleCapabilitySlugs ?? this.myRoleCapabilitySlugs,
    );
  }

  /// Resets all criteria to defaults (no filter).
  ProFilterCriteria cleared() => const ProFilterCriteria();

  @override
  List<Object?> get props => [
        employmentTypes,
        incomeBrackets,
        suggestedTermsOnly,
        verifiedOnly,
        institutionMatchOnly,
        moduleFilter,
        amountBands,
        location,
        favoriteCurrencies,
        needType,
        urgency,
        hasClearBudget,
        amongFirst,
        matchesMyCategories,
        myNeedCategorySlugs,
        myRoleCapabilitySlugs,
      ];
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
    this.moduleFilter,
    this.proFilterCriteria = const ProFilterCriteria(),
    this.proFilterActive = false,
    this.interestCategorySlugs = const {},
  });

  final List<MarketplaceItem> listings;
  final String activeFilter;
  final MarketplaceModule? moduleFilter;

  /// Current Pro filter criteria (always present; `.isActive` tells you
  /// whether they have any effect on the displayed listing set).
  final ProFilterCriteria proFilterCriteria;

  /// True while the Pro filter RPC result is being applied to the feed.
  final bool proFilterActive;
  final Set<String> interestCategorySlugs;

  MarketplaceLoaded copyWith({
    List<MarketplaceItem>? listings,
    String? activeFilter,
    MarketplaceModule? moduleFilter,
    ProFilterCriteria? proFilterCriteria,
    bool? proFilterActive,
    Set<String>? interestCategorySlugs,
  }) {
    return MarketplaceLoaded(
      listings: listings ?? this.listings,
      activeFilter: activeFilter ?? this.activeFilter,
      moduleFilter: moduleFilter ?? this.moduleFilter,
      proFilterCriteria: proFilterCriteria ?? this.proFilterCriteria,
      proFilterActive: proFilterActive ?? this.proFilterActive,
      interestCategorySlugs:
          interestCategorySlugs ?? this.interestCategorySlugs,
    );
  }

  @override
  List<Object?> get props => [
        listings,
        activeFilter,
        moduleFilter,
        proFilterCriteria,
        proFilterActive,
        interestCategorySlugs
      ];
}

class MarketplaceError extends MarketplaceState {
  const MarketplaceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
