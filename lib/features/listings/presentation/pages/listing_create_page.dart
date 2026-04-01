import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/data/system_settings_repository.dart';

// ─── Purpose options ──────────────────────────────────────────────────────────
const _purposes = [
  'Agricultural equipment',
  'Business expansion',
  'Education / School fees',
  'Emergency medical',
  'Greenhouse / Farming',
  'Home improvement',
  'Inventory / Stock',
  'Land purchase',
  'Livestock',
  'Solar / Energy',
  'Transport / Vehicle',
  'Water & Sanitation',
  'Wedding / Event',
  'Other',
];

// ─── Districts ────────────────────────────────────────────────────────────────
const _districts = [
  'Kampala', 'Wakiso', 'Mukono', 'Jinja', 'Mbale', 'Gulu', 'Mbarara',
  'Masaka', 'Lira', 'Soroti', 'Arua', 'Fort Portal', 'Kabale', 'Other',
];

class ListingCreatePage extends StatefulWidget {
  const ListingCreatePage({super.key});
  @override
  State<ListingCreatePage> createState() => _ListingCreatePageState();
}

class _ListingCreatePageState extends State<ListingCreatePage> {
  final _pageController = PageController();
  int _step = 0; // 0 = loan details, 1 = review & publish

  // Step 1 fields
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPurpose;
  String? _customPurpose;
  String _district = 'Kampala';
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  bool _savingDraft = false;
  PlatformLimits _limits = PlatformLimits.defaults;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final limits = await getIt<SystemSettingsRepository>().getLimits();
    if (mounted) setState(() { _limits = limits; });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _purposeValue =>
      _selectedPurpose == 'Other' ? (_customPurpose ?? '') : (_selectedPurpose ?? '');

  bool get _step1Valid {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedPurpose == null) return false;
    if (_selectedPurpose == 'Other' &&
        (_customPurpose == null || _customPurpose!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  void _next() {
    if (!_step1Valid) {
      _formKey.currentState!.validate();
      if (_selectedPurpose == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a purpose.')),
        );
      }
      return;
    }
    setState(() => _step = 1);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _submit({bool draft = false}) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (!authState.user.kycApproved) {
      _showGate('Complete KYC verification before posting a listing.');
      return;
    }
    if (!authState.user.canBorrow) {
      _showGate('A Borrower or Pro subscription is required to post a listing.');
      return;
    }

    setState(() => draft ? _savingDraft = true : _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800)); // replace with real insert
    if (!mounted) return;
    setState(() => draft ? _savingDraft = false : _submitting = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(draft ? 'Draft saved' : 'Request submitted'),
        content: Text(draft
            ? 'Your loan request has been saved as a draft. You can publish it from My Requests.'
            : 'Your loan request is now live on the marketplace. Lenders will start bidding shortly.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.myListings);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showGate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  setState(() => _step = 0);
                  _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                },
              )
            : null,
        title: Text(_step == 0 ? 'Request a loan' : 'Review & publish'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / 2,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 3,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2()],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Step 1: Loan details ───────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Loans: UGX ${_fmt(_limits.minLoanAmount)} – ${_fmt(_limits.maxLoanAmount)} · Up to 60 months · Max ${_limits.maxInterestRate.toStringAsFixed(0)}% interest',
                  style: const TextStyle(fontSize: 11, color: AppColors.accent),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Loan Amount (UGX) *',
              hintText: 'e.g. 2000000',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter an amount';
              final n = int.tryParse(v);
              if (n == null) return 'Enter a valid number';
              if (n < _limits.minLoanAmount) return 'Minimum UGX ${_fmt(_limits.minLoanAmount)}';
              if (n > _limits.maxLoanAmount) return 'Maximum UGX ${_fmt(_limits.maxLoanAmount)}';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Duration
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Duration (months) *',
              hintText: '1 – 60',
              prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter duration';
              final n = int.tryParse(v);
              if (n == null || n < 1 || n > 60) return '1 to 60 months';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Max interest rate
          TextFormField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Max Interest Rate (%) *',
              hintText: 'e.g. 15 (max ${_limits.maxInterestRate.toStringAsFixed(0)}%)',
              prefixIcon: const Icon(Icons.percent_rounded, size: 20),
              suffixText: '%',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a rate';
              final r = double.tryParse(v);
              if (r == null || r < _limits.minInterestRate || r > _limits.maxInterestRate) return '${_limits.minInterestRate.toStringAsFixed(0)}% to ${_limits.maxInterestRate.toStringAsFixed(0)}%';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Purpose dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedPurpose,
            decoration: const InputDecoration(
              labelText: 'Purpose *',
              prefixIcon: Icon(Icons.category_outlined, size: 20),
            ),
            hint: const Text('Select purpose'),
            items: _purposes
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedPurpose = v;
              if (v != 'Other') _customPurpose = null;
            }),
            validator: (v) => v == null ? 'Select a purpose' : null,
          ),

          // Custom purpose field when Other selected
          if (_selectedPurpose == 'Other') ...[
            const SizedBox(height: 14),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Describe your purpose *',
                prefixIcon: Icon(Icons.edit_outlined, size: 20),
              ),
              onChanged: (v) => _customPurpose = v,
              validator: (v) {
                if (_selectedPurpose == 'Other' &&
                    (v == null || v.trim().isEmpty)) {
                  return 'Please describe your purpose';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 14),

          // District
          DropdownButtonFormField<String>(
            initialValue: _district,
            decoration: const InputDecoration(
              labelText: 'District *',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
            items: _districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _district = v ?? 'Kampala'),
          ),
          const SizedBox(height: 14),

          // Description (optional)
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.notes_rounded, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Step 2: Review & publish ───────────────────────────────────────────────

  Widget _buildStep2() {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final duration = _durationController.text;
    final rate = _rateController.text;
    final description = _descriptionController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Review your request',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Confirm the details before publishing to the marketplace.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),

        // Summary card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(children: [
            _ReviewRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Amount',
              value: 'UGX ${_fmtAmount(amount)}',
              highlight: true,
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.calendar_month_outlined,
              label: 'Duration',
              value: '$duration months',
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.percent_rounded,
              label: 'Max interest rate',
              value: '$rate% per annum',
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.category_outlined,
              label: 'Purpose',
              value: _purposeValue,
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.location_on_outlined,
              label: 'District',
              value: _district,
            ),
            if (description.isNotEmpty) ...[
              _divider(),
              _ReviewRow(
                icon: Icons.notes_rounded,
                label: 'Description',
                value: description,
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        // Non-custodial note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.verified_outlined, size: 14, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your identity is never shown to lenders. Risk grading is assigned by Nipanze after review.',
                style: TextStyle(fontSize: 11, color: AppColors.success),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1,
      color: Theme.of(context).dividerColor);

  // ─── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: _step == 0
            ? ElevatedButton(
                onPressed: _next,
                child: const Text('Continue'),
              )
            : Column(mainAxisSize: MainAxisSize.min, children: [
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Publish to marketplace'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _savingDraft ? null : () => _submit(draft: true),
                  child: _savingDraft
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save as draft'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saved as draft first. Review and publish when ready.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
      ),
    );
  }

  String _fmt(int n) => _fmtAmount(n);

  String _fmtAmount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Review row ───────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 18 : 13,
                fontWeight: FontWeight.w600,
                fontFamily: highlight ? 'DM Mono' : 'DM Sans',
                color: highlight ? AppColors.accent : null,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}