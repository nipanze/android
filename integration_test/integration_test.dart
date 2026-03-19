// integration_test/integration_test.dart

// ignore_for_file: directives_ordering

import 'package:integration_test/integration_test.dart';

import 'auth/register_test.dart' as auth;
import 'wallet/top_up_test.dart' as wallet;
import 'marketplace/loan_listing_test.dart' as marketplace;
import 'bids/place_bid_test.dart' as bids;
import 'contracts/contract_activation_test.dart' as contracts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  auth.main();
  wallet.main();
  marketplace.main();
  bids.main();
  contracts.main();
}
