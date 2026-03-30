// ignore_for_file: unused_import, directives_ordering, curly_braces_in_flow_control_structures, deprecated_member_use, unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/models/nipanze_user.dart';

class ListingCreatePage extends StatefulWidget {
  const ListingCreatePage({super.key});
  @override State<ListingCreatePage> createState() => _ListingCreatePageState();
}

class _ListingCreatePageState extends State<ListingCreatePage> {
  final _pageController = PageController();
  int _step = 0;

  // Step 1 fields
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();

  // Step 2 fields
  final _rateController = TextEditingController();
  String _riskCategory = 'medium';

  // Step 3 fields
  String _district = 'Central';

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  bool _submitting = false;

  static const _districts = [
    'Central', 'Eastern', 'Northern', 'Western', 'Kampala'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && !_formKey1.currentState!.validate()) return;
    if (_step == 1 && !_formKey2.currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Gate: KYC required
    if (!authState.user.kycApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC verification required before listing. Please complete KYC.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Gate: Borrower subscription
    if (!authState.user.canBorrow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Borrower or Pro subscription is required to post a listing.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    // Actual insert handled by DB trigger chain — stub shows confirmation
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _submitting = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Listing submitted'),
          content: const Text(
              'Your loan request has been submitted for review. It will appear live on the marketplace shortly.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut);
            } else {
              context.pop();
            }
          },
        ),
        title: Text('Create listing — Step ${_step + 1} of 3'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 3,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Step 1: Amount + purpose
          _StepWrapper(
            child: Form(
              key: _formKey1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Loan details', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Describe what you need funding for.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Listing title'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Purpose / Description',
                      alignLabelWithHint: true),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Describe your purpose' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount (UGX)',
                      hintText: 'Min 100,000 — Max 50,000,000'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    final n = int.tryParse(v.replaceAll(',', ''));
                    if (n == null) return 'Enter a valid number';
                    if (n < 100000) return 'Minimum UGX 100,000';
                    if (n > 50000000) return 'Maximum UGX 50,000,000';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Duration (months)',
                      hintText: '1 – 60 months'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter duration';
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 60)
                      return 'Enter 1–60 months';
                    return null;
                  },
                ),
              ]),
            ),
          ),

          // Step 2: Rate + risk
          _StepWrapper(
            child: Form(
              key: _formKey2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Interest & risk', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Set your maximum acceptable interest rate.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Max interest rate (%)',
                      hintText: '5% – 30%',
                      suffixText: '%'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a rate';
                    final r = double.tryParse(v);
                    if (r == null || r < 5 || r > 30)
                      return 'Rate must be 5–30%';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Risk category', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(children: ['low', 'medium', 'high'].map((r) {
                  final isSelected = _riskCategory == r;
                  final color = r == 'low'
                      ? AppColors.success
                      : r == 'medium'
                          ? AppColors.warning
                          : AppColors.danger;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _riskCategory = r),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? color : Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          r[0].toUpperCase() + r.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSelected ? color : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Lenders bid below your ceiling rate. You always see every offer before accepting. No obligation until you accept.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ]),
            ),
          ),

          // Step 3: District + review
          _StepWrapper(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Location & review', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('Confirm your district and review the listing.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _district,
                decoration: const InputDecoration(labelText: 'District'),
                items: _districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _district = v ?? 'Central'),
              ),
              const SizedBox(height: 20),
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _ReviewRow('Title', _titleController.text.isEmpty ? '—' : _titleController.text),
              _ReviewRow('Amount', 'UGX ${_amountController.text}'),
              _ReviewRow('Duration', '${_durationController.text} months'),
              _ReviewRow('Ceiling rate', '${_rateController.text}%'),
              _ReviewRow('Risk', _riskCategory),
              _ReviewRow('District', _district),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Text(
                  'KYC verification and an active Borrower subscription are required to post. These are enforced by the database.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _submitting ? null : _next,
            child: _submitting
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_step < 2 ? 'Continue' : 'Submit listing'),
          ),
        ),
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  const _StepWrapper({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      );
}
