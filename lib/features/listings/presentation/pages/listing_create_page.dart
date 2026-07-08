// lib/features/listings/presentation/pages/listing_create_page.dart
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
  final _suggestedInterestController = TextEditingController();
  final _suggestedLateFeeController = TextEditingController();
  final _suggestedInstallmentController = TextEditingController();
  String? _preferredRepaymentPlan;
  String? _suggestedRepaymentPlan;

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
    _suggestedInterestController.dispose();
    _suggestedLateFeeController.dispose();
    _suggestedInstallmentController.dispose();
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
          const SnackBar(content: Text('Select a purpose to continue.')),
        );
      }
      return;
    }
    if (_step == 1 && !_repaymentValid) {
      _repaymentFormKey.currentState!.validate();
      if (_preferredRepaymentPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a repayment plan to continue.')),
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
      _showGate('Your account is not allowed to post a listing.');
      return;
    }

    final canSuggestTerms = authState.user.canSuggestBorrowerTerms;
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
        suggestedInterestRatePct: canSuggestTerms
            ? double.tryParse(_suggestedInterestController.text)
            : null,
        suggestedLateFeePct: canSuggestTerms
            ? double.tryParse(_suggestedLateFeeController.text)
            : null,
        suggestedRepaymentFrequency:
            canSuggestTerms ? _suggestedRepaymentPlan : null,
        suggestedInstallmentAmount: canSuggestTerms
            ? int.tryParse(_suggestedInstallmentController.text)
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showGate(e is AppException
          ? e.message
          : 'Could not publish this request. Try again.');
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request submitted'),
        content: const Text(
          'Your loan request is now live on the marketplace. Lenders can review it and make bids.',
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
      body: SafeArea(
        child: Column(
          children: [
            _TemplateHeader(
              title: _titleForStep(),
              subtitle: 'Step ${_step + 1} of 3 · ${_subtitleForStep()}',
              progress: (_step + 1) / 3,
              onBack: _step > 0 ? _back : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
          ],
        ),
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

  String _subtitleForStep() {
    switch (_step) {
      case 1:
        return 'repayment context';
      case 2:
        return 'review';
      default:
        return 'loan details';
    }
  }

  // ─── Step 1: Loan details ───────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _loanDetailsFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoBanner(
            text:
                'UGX ${_fmt(_limits.minLoanAmount)}-${_fmt(_limits.maxLoanAmount)} · Up to 60 months · terms lock on publish',
          ),
          const SizedBox(height: 14),
          _FormPanel(
            title: 'The basics',
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Request title',
                  hintText: 'e.g. Delivery van for Kampala route',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter a title';
                  if (value.length < 4) return 'Use at least 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPurpose,
                decoration: const InputDecoration(labelText: 'Purpose'),
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
              if (_selectedPurpose == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Describe your purpose',
                  ),
                  onChanged: (v) => _customPurpose = v,
                  validator: (v) {
                    if (_selectedPurpose == 'Other' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Describe your purpose';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _FormPanel(
            title: 'The numbers',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Amount (UGX)',
                        hintText: '7,000,000',
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: '6 months',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter duration';
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 60) {
                          return '1 to 60 months';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FormPanel(
            title: 'Location and details',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _district,
                decoration: const InputDecoration(labelText: 'District'),
                items: _districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _district = v ?? 'Kampala'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add any context lenders should know',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ─── Step 2: Income & repayment ─────────────────────────────────────────────

  Widget _buildStep2() {
    final authState = context.watch<AuthBloc>().state;
    final canSuggestTerms = authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _repaymentFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FormPanel(
            title: 'Repayment source',
            children: [
              TextFormField(
                controller: _incomeSourceController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Income source',
                  hintText: 'e.g. Salary, shop income, farming, side work',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter your repayment source';
                  if (value.length < 6) return 'Add a little more detail';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _preferredRepaymentPlan,
                decoration: const InputDecoration(
                  labelText: 'Preferred repayment plan',
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
            ],
          ),
          const SizedBox(height: 10),
          _FormPanel(
            title: 'Ability to repay',
            children: [
              TextFormField(
                controller: _repaymentAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Repayment amount per period (UGX)',
                  hintText: 'e.g. 250,000',
                  prefixIcon: Icon(Icons.savings_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter repayment amount';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repaymentTimelineController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Repayment timeline',
                  hintText: 'e.g. Paid by the 5th of every month for 8 months',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.event_repeat_outlined, size: 20),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter repayment timeline';
                  if (value.length < 10) return 'Add a clearer timeline';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FormPanel(
            title: 'Preferred terms',
            subtitle: canSuggestTerms
                ? 'Locked when the request is published.'
                : 'Upgrade to Pro to suggest interest, late fee, and repayment terms.',
            children: [
              TextFormField(
                controller: _suggestedInterestController,
                enabled: canSuggestTerms,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Suggested interest rate (%)',
                  prefixIcon: Icon(Icons.percent_rounded, size: 20),
                ),
                validator: (v) {
                  if (!canSuggestTerms || v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 0 || n > 100) return 'Use 0 to 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _suggestedLateFeeController,
                enabled: canSuggestTerms,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Suggested late payment fee (%)',
                  prefixIcon: Icon(Icons.warning_amber_rounded, size: 20),
                ),
                validator: (v) {
                  if (!canSuggestTerms || v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 0 || n > 100) return 'Use 0 to 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _suggestedRepaymentPlan,
                decoration: const InputDecoration(
                  labelText: 'Suggested repayment schedule',
                  prefixIcon: Icon(Icons.event_available_outlined, size: 20),
                ),
                items: _repaymentPlans
                    .map((p) => DropdownMenuItem(
                          value: p['value'],
                          child: Text(p['label']!),
                        ))
                    .toList(),
                onChanged: canSuggestTerms
                    ? (v) => setState(() => _suggestedRepaymentPlan = v)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _suggestedInstallmentController,
                enabled: canSuggestTerms,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Suggested installment amount (UGX)',
                  prefixIcon: Icon(Icons.price_check_outlined, size: 20),
                ),
                validator: (v) {
                  if (!canSuggestTerms || v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
            ],
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
    final authState = context.watch<AuthBloc>().state;
    final canSuggestTerms = authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;

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
            if (canSuggestTerms &&
                (_suggestedInterestController.text.isNotEmpty ||
                    _suggestedLateFeeController.text.isNotEmpty ||
                    _suggestedRepaymentPlan != null ||
                    _suggestedInstallmentController.text.isNotEmpty)) ...[
              _divider(),
              _ReviewRow(
                icon: Icons.lock_outline_rounded,
                label: 'Locked preferred terms',
                value: [
                  if (_suggestedInterestController.text.isNotEmpty)
                    '${_suggestedInterestController.text}% interest',
                  if (_suggestedLateFeeController.text.isNotEmpty)
                    '${_suggestedLateFeeController.text}% late fee on missed installment',
                  if (_suggestedRepaymentPlan != null)
                    _planLabel(_suggestedRepaymentPlan),
                  if (_suggestedInstallmentController.text.isNotEmpty)
                    'UGX ${_fmtAmount(int.tryParse(_suggestedInstallmentController.text) ?? 0)} installment',
                ].join(' · '),
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
                'Your contact details stay hidden until a bid is accepted and the unlock flow is completed.',
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

// ─── Header with step progress ───────────────────────────────────────────────

class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                // Screen title uses Sora (heading font) per app_theme.dart —
                // headlineSmall already carries AppFonts.heading, no override needed.
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info banner ──────────────────────────────────────────────────────────────
// Theme fix: previously hardcoded Color(0xFF062B57)/Color(0xFF7DB7FF), which
// only look correct in dark mode and never adapt. Now derived from
// AppColors.accent so it reads correctly in both light and dark themes.

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10.5,
          color: AppColors.accentDark,
        ),
      ),
    );
  }
}

// ─── Grouped form panel ───────────────────────────────────────────────────────
// Groups related fields under one labeled panel instead of one long flat list,
// so the form reads as a handful of short sections rather than a wall of inputs.

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.48),
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

// ─── Review row ───────────────────────────────────────────────────────────────
// Theme fix: previously used raw 'DM Mono'/'DM Sans' font-family strings that
// don't exist in this theme (AppTheme registers Sora/Inter via AppFonts).
// Hero numeric values now correctly use AppFonts.heading (Sora), matching the
// "hero numbers" rule in app_theme.dart's doc comment.

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
                fontFamily: highlight ? AppFonts.heading : AppFonts.body,
                color: highlight ? AppColors.accent : null,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
