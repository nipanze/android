// lib/features/marketplace/presentation/widgets/loan_detail/make_offer_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/di/injection.dart';
import '../../../../../../core/errors/app_exception.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/marketplace_repository.dart';
import '../../../domain/models/loan_listing.dart';

class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet(
      {super.key,
      required this.listing,
      required this.onClose,
      required this.onOfferPlaced});
  final LoanListing listing;
  final VoidCallback onClose;
  final VoidCallback onOfferPlaced;
  @override
  State<MakeOfferSheet> createState() => MakeOfferSheetState();
}

class MakeOfferSheetState extends State<MakeOfferSheet> {
  final _amountController = TextEditingController();
  final _expController = TextEditingController();
  final _interestController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _installmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _repaymentFrequency = 'monthly';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill amount with the requested amount
    _amountController.text = widget.listing.requestedAmount.toString();
    for (final controller in [
      _amountController,
      _interestController,
      _lateFeeController,
      _installmentController,
    ]) {
      controller.addListener(_refreshButtonState);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _amountController,
      _interestController,
      _lateFeeController,
      _installmentController,
    ]) {
      controller.removeListener(_refreshButtonState);
    }
    _amountController.dispose();
    _expController.dispose();
    _interestController.dispose();
    _lateFeeController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  void _refreshButtonState() {
    if (mounted) setState(() {});
  }

  bool get _isOfferReady {
    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    final interest = double.tryParse(_interestController.text);
    final lateFee = double.tryParse(_lateFeeController.text);
    final installment =
        int.tryParse(_installmentController.text.replaceAll(',', ''));
    return amount != null &&
        amount > 0 &&
        interest != null &&
        interest >= 0 &&
        interest <= 100 &&
        lateFee != null &&
        lateFee >= 0 &&
        lateFee <= 100 &&
        installment != null &&
        installment > 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<MarketplaceRepository>().makeOffer(
        requestId: widget.listing.requestId,
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        interestRatePct: double.parse(_interestController.text),
        lateFeePct: double.parse(_lateFeeController.text),
        repaymentFrequency: _repaymentFrequency,
        installmentAmount:
            int.parse(_installmentController.text.replaceAll(',', '')),
        expectations: _expController.text,
      );
      widget.onOfferPlaced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.offerSentSuccessfully ??
                  'Offer sent successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userFacingErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: SingleChildScrollView(
        child: Form(
            key: _formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(l10n?.makeAnOffer ?? 'Make an offer',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose)
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                        labelText: l10n?.amountLabelWithCurrency(
                                widget.listing.currency) ??
                            'Amount (${widget.listing.currency})',
                        prefixIcon: const Icon(Icons.payments_outlined)),
                    validator: (v) => (v == null || v.isEmpty)
                        ? (l10n?.validationAmountRequired ?? 'Enter an amount')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _interestController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                        labelText:
                            l10n?.interestRateLabel ?? 'Interest rate (%)',
                        prefixIcon: const Icon(Icons.percent_rounded)),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) {
                        return l10n?.validationPercentRange ?? 'Use 0 to 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lateFeeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                        labelText:
                            l10n?.latePaymentFeeLabel ?? 'Late payment fee (%)',
                        prefixIcon: const Icon(Icons.warning_amber_rounded)),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) {
                        return l10n?.validationPercentRange ?? 'Use 0 to 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _repaymentFrequency,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.repaymentScheduleLabel ?? 'Repayment schedule',
                      prefixIcon: const Icon(Icons.event_repeat_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'monthly',
                          child: Text(l10n?.monthly ?? 'Monthly')),
                      DropdownMenuItem(
                          value: 'weekly',
                          child: Text(l10n?.weekly ?? 'Weekly')),
                      DropdownMenuItem(
                          value: 'one_time',
                          child:
                              Text(l10n?.oneTimePayment ?? 'One-time payment')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _repaymentFrequency = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _installmentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                        labelText: l10n?.installmentAmountLabel(
                                widget.listing.currency) ??
                            'Installment amount (${widget.listing.currency})',
                        prefixIcon: const Icon(Icons.price_check_outlined)),
                    validator: (v) => (v == null || v.isEmpty)
                        ? (l10n?.validationAmountRequired ?? 'Enter an amount')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: l10n?.additionalExpectationsLabel ??
                            'Additional expectations',
                        hintText: l10n?.optionalBorrowerNotesHint ??
                            'Optional notes for the borrower',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _loading || !_isOfferReady ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(l10n?.sendOffer ?? 'Send Offer')),
                ])),
      ),
    );
  }
}
