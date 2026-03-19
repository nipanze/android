// integration_test/main.dart
//
// Entry point for all integration tests.
// Run: flutter test integration_test/
//
// Individual suites:
//   flutter test integration_test/auth/register_test.dart
//   flutter test integration_test/wallet/top_up_test.dart
//   flutter test integration_test/marketplace/loan_listing_test.dart
//   flutter test integration_test/bids/place_bid_test.dart
//   flutter test integration_test/contracts/contract_activation_test.dart

// ignore_for_file: directives_ordering

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth/register_test.dart' as auth;
import 'wallet/top_up_test.dart' as wallet;
import 'marketplace/loan_listing_test.dart' as marketplace;
import 'bids/place_bid_test.dart' as bids;
import 'contracts/contract_activation_test.dart' as contracts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth', auth.main);
  group('Wallet', wallet.main);
  group('Marketplace', marketplace.main);
  group('Bids', bids.main);
  group('Contracts', contracts.main);
}
