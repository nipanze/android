import 'package:flutter/material.dart';

/// Loan detail page — shows anonymised listing pre-bid, real-time bids.
/// Borrower sees "Accept Bid" per bid; lenders see "Place Bid" button.
/// Full implementation in Stage 2.4 / 2.6 of the build plan.
class LoanDetailPage extends StatelessWidget {
  const LoanDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),
      body: Center(
        child: Text('Loan: $requestId\n\nStage 2.6 — real-time bids + accept/bid flow.',
            textAlign: TextAlign.center),
      ),
    );
  }
}
