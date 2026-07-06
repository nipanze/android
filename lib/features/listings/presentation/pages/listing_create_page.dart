import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/data/system_settings_repository.dart';
import '../../data/listing_repository.dart';

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
  'Kampala',
  'Wakiso',
  'Mukono',
  'Jinja',
  'Mbale',
  'Gulu',
  'Mbarara',
  'Masaka',
  'Lira',
  'Soroti',
  'Arua',
  'Fort Portal',
  'Kabale',
  'Other',
];

const _repaymentPlans = [
  {'value': 'monthly', 'label': 'Monthly'},
  {'value': 'weekly', 'label': 'Weekly'},
  {'value': 'one_time', 'label': 'One-time payment'},
];

class ListingCreatePage extends StatefulWidget {
  const ListingCreatePage({super.key});
  @override
  State<ListingCreatePage> createState() => _ListingCreatePageState();
}

class _ListingCreatePageState extends State<ListingCreatePage> {
  final _pageController = PageController();
  int _step = 0; // 0 = loan details, 1 = repayment context, 2 = review

  // Step 1 fields
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPurpose;
  String? _customPurpose;
  String _district = 'Kampala';

  // Step 2 fields
  final _incomeSourceController = TextEditingController();
  final _repaymentAmountController = TextEditingController();
  final _repaymentTimelineController = TextEditingController();
  String? _preferredRepaymentPlan;

  final _loanDetailsFormKey = GlobalKey<FormState>();
  final _repaymentFormKey = GlobalKey<FormState>();

  bool _submitting = false;
  PlatformLimits _limits = PlatformLimits.defaults;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final limits = await getIt<SystemSettingsRepository>().getLimits();
    if (mounted) {
      setState(() {
        _limits = limits;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _incomeSourceController.dispose();
    _repaymentAmountController.dispose();
    _repaymentTimelineController.dispose();
    super.dispose();
  }

  String get _purposeValue => _selectedPurpose == 'Other'
      ? (_customPurpose ?? '')
      : (_selectedPurpose ?? '');

  bool get _loanDetailsValid {
    if (!_loanDetailsFormKey.currentState!.validate()) return false;
    if (_selectedPurpose == null) return false;
    if (_selectedPurpose == 'Other' &&
        (_customPurpose == null || _customPurpose!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  bool get _repaymentValid {
    if (!_repaymentFormKey.currentState!.validate()) return false;
    if (_preferredRepaymentPlan == null) return false;
    return true;
  }

  void _next() {
    if (_step == 0 && !_loanDetailsValid) {
      _loanDetailsFormKey.currentState!.validate();
      if (_selectedPurpose == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a purpose.')),
        );
      }
      return;
    }
    if (_step == 1 && !_repaymentValid) {
      _repaymentFormKey.currentState!.validate();
      if (_preferredRepaymentPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a repayment plan.')),
        );
      }
      return;
    }
    if (_step >= 2) return;
    setState(() => _step += 1);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    if (!_loanDetailsValid || !_repaymentValid) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (!authState.user.kycApproved) {
      _showGate('Complete KYC verification before posting a listing.');
      return;
    }
    if (!authState.user.canBorrow) {
      _showGate(
          'A Borrower or Pro subscription is required to post a listing.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await getIt<ListingRepository>().createListing(
        title: _titleController.text.trim(),
        purpose: _purposeValue.trim(),
        requestedAmount: int.parse(_amountController.text),
        durationMonths: int.parse(_durationController.text),
        district: _district,
        incomeSource: _incomeSourceController.text.trim(),
        preferredRepaymentPlan: _preferredRepaymentPlan!,
        repaymentAmountPerPeriod: int.parse(_repaymentAmountController.text),
        repaymentTimeline: _repaymentTimelineController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showGate(e is AppException
          ? e.message
          : 'Could not publish this request. Please try again.');
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request submitted'),
        content: const Text(
          'Your loan request is now live on the marketplace. Lenders can review it and make offers.',
        ),
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
                onPressed: _back,
              )
            : null,
        title: Text(_titleForStep()),
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
        children: [_buildStep1(), _buildStep2(), _buildStep3()],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case 1:
        return 'Income & repayment';
      case 2:
        return 'Review & publish';
      default:
        return 'Request a loan';
    }
  }

  // ─── Step 1: Loan details ───────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _loanDetailsFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Requests: UGX ${_fmt(_limits.minLoanAmount)} – ${_fmt(_limits.maxLoanAmount)} · Up to 60 months · Lenders propose offer terms',
                  style: const TextStyle(fontSize: 11, color: AppColors.accent),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Title
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Request Title *',
              hintText: 'e.g. Farm equipment purchase',
              prefixIcon: Icon(Icons.title_rounded, size: 20),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter a title';
              if (value.length < 4) return 'Use at least 4 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),

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
              if (n < _limits.minLoanAmount) {
                return 'Minimum UGX ${_fmt(_limits.minLoanAmount)}';
              }
              if (n > _limits.maxLoanAmount) {
                return 'Maximum UGX ${_fmt(_limits.maxLoanAmount)}';
              }
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

  // ─── Step 2: Income & repayment ─────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _repaymentFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
            controller: _incomeSourceController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Income Source *',
              hintText: 'e.g. Salary, shop income, farming, side work',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.work_outline_rounded, size: 20),
              ),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter your repayment source';
              if (value.length < 6) return 'Add a little more detail';
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _preferredRepaymentPlan,
            decoration: const InputDecoration(
              labelText: 'Preferred Repayment Plan *',
              prefixIcon: Icon(Icons.payments_outlined, size: 20),
            ),
            hint: const Text('Select repayment plan'),
            items: _repaymentPlans
                .map((p) => DropdownMenuItem(
                      value: p['value'],
                      child: Text(p['label']!),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _preferredRepaymentPlan = v),
            validator: (v) => v == null ? 'Select a repayment plan' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _repaymentAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Repayment Amount Per Period (UGX) *',
              hintText: 'e.g. 250000',
              prefixIcon: Icon(Icons.savings_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter repayment amount';
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _repaymentTimelineController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Repayment Timeline *',
              hintText: 'e.g. Paid by the 5th of every month for 8 months',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.event_repeat_outlined, size: 20),
              ),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter repayment timeline';
              if (value.length < 10) return 'Add a clearer timeline';
              return null;
            },
          ),
        ]),
      ),
    );
  }

  // ─── Step 3: Review & publish ───────────────────────────────────────────────

  Widget _buildStep3() {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final duration = _durationController.text;
    final repaymentAmount = int.tryParse(_repaymentAmountController.text) ?? 0;
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
              icon: Icons.title_rounded,
              label: 'Title',
              value: _titleController.text.trim(),
            ),
            _divider(),
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
            _divider(),
            _ReviewRow(
              icon: Icons.work_outline_rounded,
              label: 'Income source',
              value: _incomeSourceController.text.trim(),
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.payments_outlined,
              label: 'Preferred repayment plan',
              value: _planLabel(_preferredRepaymentPlan),
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.savings_outlined,
              label: 'Repayment amount',
              value: 'UGX ${_fmtAmount(repaymentAmount)} per period',
            ),
            _divider(),
            _ReviewRow(
              icon: Icons.event_repeat_outlined,
              label: 'Repayment timeline',
              value: _repaymentTimelineController.text.trim(),
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
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.verified_outlined, size: 14, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your contact details stay hidden until an offer is accepted and the unlock flow is completed.',
                style: TextStyle(fontSize: 11, color: AppColors.success),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Theme.of(context).dividerColor);

  // ─── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            onPressed: _submitting ? null : (_step < 2 ? _next : _submit),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_step < 2 ? 'Continue' : 'Publish to marketplace'),
          ),
          if (_step > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _submitting ? null : _back,
              child: const Text('Back'),
            ),
          ],
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

  String _planLabel(String? value) {
    for (final plan in _repaymentPlans) {
      if (plan['value'] == value) return plan['label']!;
    }
    return '';
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
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
