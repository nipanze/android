// lib/features/home/presentation/pages/home_page.dart
// The /home route delegates directly to the MarketplacePage to deliver
// the unified, continuous marketplace discovery feed.

import 'package:flutter/material.dart';

import '../../../marketplace/presentation/pages/marketplace_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketplacePage();
  }
}
