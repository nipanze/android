import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/currency_model.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/forex_repository.dart';

const _defaultTradeableCurrencies = [
  CurrencyModel(
    code: 'UGX',
    name: 'Ugandan Shilling',
    isMarketCurrency: true,
    marketCountry: 'UG',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'KES',
    name: 'Kenyan Shilling',
    isMarketCurrency: true,
    marketCountry: 'KE',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'TZS',
    name: 'Tanzanian Shilling',
    isMarketCurrency: true,
    marketCountry: 'TZ',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'RWF',
    name: 'Rwandan Franc',
    isMarketCurrency: true,
    marketCountry: 'RW',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'BIF',
    name: 'Burundian Franc',
    isMarketCurrency: true,
    marketCountry: 'BI',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'SSP',
    name: 'South Sudanese Pound',
    isMarketCurrency: true,
    marketCountry: 'SS',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'CDF',
    name: 'Congolese Franc',
    isMarketCurrency: true,
    marketCountry: 'CD',
    forexTradingEnabled: true,
  ),
  CurrencyModel(
    code: 'SOS',
    name: 'Somali Shilling',
    isMarketCurrency: true,
    marketCountry: 'SO',
    forexTradingEnabled: true,
  ),
  CurrencyModel(code: 'USD', name: 'US Dollar', forexTradingEnabled: true),
  CurrencyModel(code: 'EUR', name: 'Euro', forexTradingEnabled: true),
  CurrencyModel(code: 'GBP', name: 'British Pound', forexTradingEnabled: true),
  CurrencyModel(code: 'AED', name: 'UAE Dirham', forexTradingEnabled: true),
  CurrencyModel(code: 'SAR', name: 'Saudi Riyal', forexTradingEnabled: true),
  CurrencyModel(code: 'CNY', name: 'Chinese Yuan', forexTradingEnabled: true),
  CurrencyModel(code: 'INR', name: 'Indian Rupee', forexTradingEnabled: true),
];

const _settlementPreferences = [
  'In person',
  'Mobile money',
  'Bank transfer',
  'Other',
];

class ForexCreatePage extends StatefulWidget {
  const ForexCreatePage({super.key});

  @override
  State<ForexCreatePage> createState() => _ForexCreatePageState();
}

class _ForexCreatePageState extends State<ForexCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _preferredRateController = TextEditingController();
  String? _currencyHeld;
  String? _currencyNeeded;
  String _settlementPreference = _settlementPreferences.first;
  bool _isUrgent = false;
  bool _submitting = false;
  List<CurrencyModel>? _currencies;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final data = await getIt<ForexRepository>().getTradeableCurrencies();
      if (!mounted) return;
      setState(() => _currencies = _mergeCurrencies(data));
    } catch (_) {
      if (!mounted) return;
      setState(() => _currencies = _defaultTradeableCurrencies);
    }
  }

  List<CurrencyModel> _mergeCurrencies(List<CurrencyModel> fetched) {
    final byCode = <String, CurrencyModel>{
      for (final currency in _defaultTradeableCurrencies)
        currency.code: currency,
    };
    for (final currency in fetched) {
      byCode[currency.code] = currency;
    }
    return byCode.values.toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _preferredRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (!authState.user.kycApproved) {
      _showMessage('Complete KYC verification before posting a forex request.');
      return;
    }

    final canSetPreferredRate =
        authState.user.subscriptionPlan == SubscriptionPlan.pro;
    setState(() => _submitting = true);
    try {
      final id = await getIt<ForexRepository>().createRequest(
        currencyHeld: _currencyHeld!,
        currencyNeeded: _currencyNeeded!,
        amount: int.parse(_amountController.text),
        settlementPreference: _settlementPreference,
        preferredRate: canSetPreferredRate
            ? double.tryParse(_preferredRateController.text)
            : null,
        isUrgent: _isUrgent,
        country: authState.user.country,
      );
      if (!mounted) return;
      context.go('/forex/$id');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(e is AppException
          ? e.message
          : 'Could not publish this forex request.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _currencies;
    final authState = context.watch<AuthBloc>().state;
    final isPro = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Text(
            '<',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Post forex request'),
      ),
      body: currencies == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currencies.length < 2)
                        const _InfoBox(
                          text:
                              'Forex is waiting on currency trading approval. Try again once at least two currencies are enabled.',
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _CurrencyField(
                              label: 'You hold',
                              value: _currencyHeld,
                              currencies: currencies,
                              onChanged: (value) =>
                                  setState(() => _currencyHeld = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CurrencyField(
                              label: 'You need',
                              value: _currencyNeeded,
                              currencies: currencies,
                              onChanged: (value) =>
                                  setState(() => _currencyNeeded = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount you will send',
                          helperText:
                              'The amount in the currency you hold. Offers use it to show how much of the currency you need you can receive.',
                        ),
                        validator: (v) {
                          final amount = int.tryParse(v ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter an amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _settlementPreference,
                        decoration:
                            const InputDecoration(labelText: 'Settlement'),
                        items: _settlementPreferences
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                          () => _settlementPreference =
                              v ?? _settlementPreferences.first,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _preferredRateController,
                        enabled: isPro,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Preferred rate',
                          helperText: isPro
                              ? 'Optional'
                              : 'Pro unlocks preferred rate suggestions',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Urgent'),
                        value: _isUrgent,
                        onChanged: (value) => setState(() => _isUrgent = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed:
              _submitting || (currencies?.length ?? 0) < 2 ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publish forex request'),
        ),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({
    required this.label,
    required this.value,
    required this.currencies,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<CurrencyModel> currencies;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: currencies
          .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
          .toList(),
      validator: (v) => v == null ? 'Choose currency' : null,
      onChanged: onChanged,
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
