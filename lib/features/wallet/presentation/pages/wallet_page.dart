// ignore_for_file: deprecated_member_use, unawaited_futures, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/wallet_model.dart';
import '../cubit/wallet_cubit.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return BlocProvider(
      create: (_) => WalletCubit(walletRepository: getIt())
        ..watchWallet(userId)
        ..loadTransactions(userId),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Funds',
            onPressed: () => _showTopUpSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (ctx, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WalletError) {
            return Center(child: Text(state.message));
          }
          if (state is WalletLoaded || state is WalletTopUpSuccess) {
            final wallet = state is WalletLoaded
                ? state.wallet
                : (ctx.read<WalletCubit>().state as WalletLoaded?)?.wallet;
            if (wallet == null) return const SizedBox.shrink();

            final transactions = state is WalletLoaded ? state.transactions : [];

            return RefreshIndicator(
              onRefresh: () async {
                final uid = Supabase.instance.client.auth.currentUser!.id;
                ctx.read<WalletCubit>()
                  ..watchWallet(uid)
                  ..loadTransactions(uid);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Balance cards
                  _BalanceCard(
                    key: const Key('lendableCard'),
                    label: 'Available to Lend',
                    sublabel: 'Your own deposited funds',
                    amount: wallet.lendableBalance,
                    color: AppColors.lendable,
                    icon: Icons.savings_outlined,
                    tooltipText:
                        'These are your own funds. The only pool eligible for placing bids.',
                  ),
                  const SizedBox(height: 12),
                  _BalanceCard(
                    key: const Key('lockedCard'),
                    label: 'Locked for Repayment',
                    sublabel: 'Reserved on active loans',
                    amount: wallet.lockedRepayment,
                    color: AppColors.locked,
                    icon: Icons.lock_outline_rounded,
                    tooltipText:
                        'Reserved when your bid is accepted. Released back as repayments arrive.',
                  ),
                  const SizedBox(height: 12),
                  _BalanceCard(
                    key: const Key('borrowedCard'),
                    label: 'Borrowed Funds',
                    sublabel: 'Received from loans',
                    amount: wallet.nonLendableBorrowed,
                    color: AppColors.borrowed,
                    icon: Icons.money_off_csred_outlined,
                    tooltipText:
                        'Funds you received from loans. Cannot be lent — ever.',
                  ),
                  const SizedBox(height: 32),

                  // Top-up button (MVP mock — labelled clearly)
                  OutlinedButton.icon(
                    onPressed: () => _showTopUpSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Funds (Test Top-Up)'),
                  ),
                  const SizedBox(height: 32),

                  // Transaction history
                  Text('Recent Activity',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('No transactions yet',
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.45),
                                )),
                      ),
                    )
                  else
                    ...transactions.map((t) => _TxRow(transaction: t)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Test Funds', style: Theme.of(sheetCtx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'MVP mock top-up — replaces Mobile Money in Stage 4.',
              style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetCtx)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text);
                if (amt == null || amt <= 0) return;
                final userId =
                    Supabase.instance.client.auth.currentUser!.id;
                context.read<WalletCubit>().topUp(userId: userId, amount: amt);
                Navigator.pop(sheetCtx);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.color,
    required this.icon,
    required this.tooltipText,
  });

  final String label;
  final String sublabel;
  final double amount;
  final Color color;
  final IconData icon;
  final String tooltipText;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_UG');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'UGX ${fmt.format(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Tooltip(
                  key: Key('${label.toLowerCase().replaceAll(' ', '_')}Info'),
                  message: tooltipText,
                  child: Icon(Icons.info_outline_rounded,
                      size: 14,
                      color:
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.transaction});
  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_UG');
    final isDisbursement = transaction['type'] == 'disbursement';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final date = transaction['completed_at'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(transaction['completed_at'] as String))
        : '—';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDisbursement ? AppColors.info : AppColors.success)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDisbursement
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          size: 18,
          color: isDisbursement ? AppColors.info : AppColors.success,
        ),
      ),
      title: Text(
        isDisbursement ? 'Loan Disbursement' : 'Repayment',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(date, style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(
        'UGX ${fmt.format(amount)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDisbursement ? AppColors.info : AppColors.success,
            ),
      ),
    );
  }
}
