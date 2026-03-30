import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class PositionsPage extends StatefulWidget {
  const PositionsPage({super.key});
  @override State<PositionsPage> createState() => _PositionsPageState();
}
class _PositionsPageState extends State<PositionsPage> with SingleTickerProviderStateMixin {
  late final TabController _tc;
  @override void initState() { super.initState(); _tc = TabController(length: 3, vsync: this); }
  @override void dispose() { _tc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('My positions', style: Theme.of(context).textTheme.headlineMedium),
            Text('Active listings + contracts', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ),
      TabBar(controller: _tc, indicatorColor: AppColors.accent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [Tab(text: 'As borrower'), Tab(text: 'As lender'), Tab(text: 'Contracts')],
      ),
      Expanded(child: TabBarView(controller: _tc, children: const [
        EmptyState(icon: Icons.person_outline, title: 'No active listings', subtitle: 'Create a listing to appear here.'),
        EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No active bids', subtitle: 'Place a bid on the marketplace.'),
        EmptyState(icon: Icons.handshake_outlined, title: 'No contracts', subtitle: 'Contracts appear here after a bid is accepted.'),
      ])),
    ])));
  }
}
