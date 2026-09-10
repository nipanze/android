import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/auth/data/auth_repository.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/marketplace/presentation/widgets/listing_card.dart';
import 'package:nipanze/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('secured badge is aligned to the far right of the metadata row',
      (tester) async {
    final repo = MockAuthRepository();
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => repo.currentUser).thenReturn(null);
    when(() => repo.isEmailVerified).thenReturn(true);

    final authBloc = AuthBloc(repo);
    authBloc.emit(const AuthAuthenticated(
      user: NipanzeUser(
        id: 'user-1',
        email: 'tester@example.com',
        subscriptionPlan: SubscriptionPlan.pro,
        isEmailVerified: true,
      ),
    ));

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
        expiresAt: DateTime.now().add(const Duration(days: 9)),
        numberOfOffers: 3,
        trustIsVerified: true,
        currency: 'UGX',
      ),
    );

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
                  onTap: () {},
                  isSaved: false,
                  onWatchlistToggle: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final securedRect = tester.getRect(find.text('Secured'));
    final attributeRect = tester.getRect(find.text('12 months'));

    expect(securedRect.left, lessThan(attributeRect.left));

    await authBloc.close();
  });

}
