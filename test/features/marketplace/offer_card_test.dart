// test/features/marketplace/offer_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/presentation/widgets/loan_detail/offer_card.dart';
import 'package:nipanze/l10n/app_localizations.dart';

LoanOffer _offer({
  int offerAmount = 400000,
  int installmentAmount = 40000,
  String repaymentFrequency = 'monthly',
  double interestRatePct = 10.0,
  double lateFeePct = 2.0,
  String lenderId = 'public-offer-abc123',
}) {
  return LoanOffer(
    id: 'offer-1',
    requestId: 'req-1',
    lenderId: lenderId,
    offerAmount: offerAmount,
    interestRatePct: interestRatePct,
    lateFeePct: lateFeePct,
    repaymentFrequency: repaymentFrequency,
    installmentAmount: installmentAmount,
    status: 'pending',
    offeredAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('OfferCard shows masked lender label and coverage for non-participants',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(OfferCard(
      offer: _offer(),
      index: 0,
      requestedAmount: 1000000,
      isOwner: false,
      isParticipant: false,
      onAccept: (_) {},
      durationMonths: 12,
      onUpgrade: () {},
      dotColor: Colors.blue,
      marketBaselinePct: 10.0,
    )));

    // Lender identity must stay anonymised for non-participants.
    expect(find.text('Lender #1'), findsOneWidget);
    // Non-participants see approximate coverage instead of the real amount.
    expect(find.text('≈40%'), findsOneWidget);
    expect(find.text('400,000'), findsNothing);
  });

  testWidgets('OfferCard shows real amount for the listing owner',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(OfferCard(
      offer: _offer(offerAmount: 1000000),
      index: 0,
      requestedAmount: 1000000,
      isOwner: true,
      isParticipant: false,
      onAccept: (_) {},
      durationMonths: 12,
      onUpgrade: () {},
      dotColor: Colors.blue,
      marketBaselinePct: 10.0,
    )));

    // Owner sees the full offer amount and full-offer styling copy.
    expect(find.text('1,000,000'), findsOneWidget);
    expect(find.text('Full offer'), findsOneWidget);
  });

  testWidgets('OfferCard expands to reveal terms for the owner',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(OfferCard(
      offer: _offer(),
      index: 0,
      requestedAmount: 1000000,
      isOwner: true,
      isParticipant: false,
      onAccept: (_) {},
      durationMonths: 12,
      onUpgrade: () {},
      dotColor: Colors.blue,
      marketBaselinePct: 10.0,
    )));

    // Tap the card header row (first InkWell is the expand toggle).
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    // Expanded owner view shows the accept action.
    expect(find.text('Accept offer'), findsOneWidget);
  });

  testWidgets('TotalPayableRow computes total across monthly periods',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(TotalPayableRow(
      offer: _offer(installmentAmount: 50000),
      durationMonths: 12,
      isFull: true,
    )));

    // 12 monthly installments of 50,000 = 600,000 total payable.
    expect(find.text('UGX 600,000'), findsOneWidget);
    // Borrowing cost = 600,000 - 400,000 principal.
    expect(find.textContaining('Borrowing cost: UGX 200,000'), findsOneWidget);
  });
}
