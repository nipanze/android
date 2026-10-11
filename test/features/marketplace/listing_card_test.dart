import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/marketplace/presentation/widgets/listing_card.dart';
import 'package:nipanze/l10n/app_localizations.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  testWidgets('card keeps original compact metadata with expiry replacing age',
      (tester) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthAuthenticated(
      user: NipanzeUser(
        id: 'user-1',
        email: 'tester@example.com',
        subscriptionPlan: SubscriptionPlan.pro,
        isEmailVerified: true,
      ),
    ));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());

    final listing = MarketplaceItem.loan(
      LoanListing(
        requestId: 'req-1',
        title: 'Business growth loan',
        purpose: 'Expand my shop',
        district: 'Kampala',
        country: 'UG',
        durationMonths: 12,
        requestedAmount: 500000,
        incomeSource: 'Trading',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 60000,
        repaymentTimeline: '12 months',
        hasCollateral: true,
        collateralDetails: 'Motorbike logbook',
        status: 'active',
        listedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 9)),
        numberOfOffers: 3,
        trustIsVerified: true,
        currency: 'UGX',
      ),
    );

    var cardTaps = 0;
    var watchlistToggles = 0;
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: ListingCard(
                  listing: listing,
                  onTap: () => cardTaps++,
                  isSaved: false,
                  onWatchlistToggle: () => watchlistToggles++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final securedRect = tester.getRect(find.text('Secured'));
    final termRect = tester.getRect(find.text('12 months'));

    expect((securedRect.center.dy - termRect.center.dy).abs(), lessThan(2));
    expect(find.text('3 offers'), findsNothing);
    expect(find.textContaining('ago'), findsNothing);
    expect(find.text('Today'), findsNothing);
    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pump();
    expect(watchlistToggles, 1);
    expect(cardTaps, 0);

    await tester.tap(find.byTooltip('Show time remaining'));
    await tester.pump();
    expect(find.text('Listing expiry'), findsOneWidget);
    expect(cardTaps, 0);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
