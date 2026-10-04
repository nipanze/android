import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/currency_model.dart';
import '../../../../shared/widgets/kyc_gate_screen.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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

List<String> _settlementPreferencesForCountry(String countryCode) {
  switch (countryCode) {
    case 'KE':
      return ['In person', 'M-Pesa', 'Bank transfer', 'Other'];
    case 'TZ':
      return ['In person', 'M-Pesa / Tigo Pesa', 'Bank transfer', 'Other'];
    case 'RW':
      return ['In person', 'MTN MoMo / Airtel', 'Bank transfer', 'Other'];
    case 'NG':
      return ['In person', 'Bank transfer', 'Cash pickup', 'Other'];
    case 'ZA':
      return ['In person', 'Bank transfer', 'Cash pickup', 'Other'];
    case 'EG':
      return ['In person', 'Vodafone Cash', 'Bank transfer', 'Other'];
    case 'UG':
    default:
      return ['In person', 'Mobile money', 'Bank transfer', 'Other'];
  }
}

String _normalizeSettlementLabel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return 'Other';
  if (normalized.toLowerCase().contains('bank')) return 'Bank transfer';
  if (normalized.toLowerCase().contains('m-pesa') ||
      normalized.toLowerCase().contains('mpesa') ||
      normalized.toLowerCase().contains('momo') ||
      normalized.toLowerCase().contains('airtel') ||
      normalized.toLowerCase().contains('vodafone') ||
      normalized.toLowerCase().contains('mobile money') ||
      normalized.toLowerCase().contains('mobile')) {
    return 'Mobile money';
  }
  if (normalized.toLowerCase().contains('cash pickup') ||
      normalized.toLowerCase().contains('pickup') ||
      normalized.toLowerCase().contains('cash') ||
      normalized.toLowerCase().contains('person')) {
    return 'In person';
  }
  return normalized;
}

String _settlementInputHint(String countryCode, String selected) {
  final normalized = _normalizeSettlementLabel(selected);
  switch (countryCode) {
    case 'KE':
      if (normalized == 'Bank transfer') {
        return 'e.g. KCB, Nairobi CBD or Westlands branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. M-Pesa, Nairobi CBD / Westlands';
      }
      if (normalized == 'In person') {
        return 'e.g. Nairobi CBD, Westlands, or nearby area';
      }
      return 'e.g. agreed location or provider';
    case 'TZ':
      if (normalized == 'Bank transfer') {
        return 'e.g. CRDB, Dar es Salaam branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. Tigo Pesa, Dar es Salaam / Arusha';
      }
      if (normalized == 'In person') {
        return 'e.g. Dar es Salaam CBD or nearby meetup area';
      }
      return 'e.g. agreed location or provider';
    case 'RW':
      if (normalized == 'Bank transfer') {
        return 'e.g. Bank of Kigali, Kigali branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. MTN MoMo, Kigali / Huye';
      }
      if (normalized == 'In person') {
        return 'e.g. Kigali city center or nearby area';
      }
      return 'e.g. agreed location or provider';
    case 'NG':
      if (normalized == 'Bank transfer') {
        return 'e.g. Access Bank, Lagos branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. Opay, Lagos / Abuja';
      }
      if (normalized == 'In person') {
        return 'e.g. Lagos island or local pickup point';
      }
      return 'e.g. agreed location or provider';
    case 'ZA':
      if (normalized == 'Bank transfer') {
        return 'e.g. Capitec Bank, Johannesburg branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. Capitec Pay, Johannesburg / Cape Town';
      }
      if (normalized == 'In person') {
        return 'e.g. Cape Town CBD or nearby area';
      }
      return 'e.g. agreed location or provider';
    case 'EG':
      if (normalized == 'Bank transfer') {
        return 'e.g. CIB, Cairo branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. Vodafone Cash, Cairo / Alexandria';
      }
      if (normalized == 'In person') {
        return 'e.g. Cairo downtown or nearby meetup area';
      }
      return 'e.g. agreed location or provider';
    case 'UG':
    default:
      if (normalized == 'Bank transfer') {
        return 'e.g. Stanbic, Kampala branch';
      }
      if (normalized == 'Mobile money') {
        return 'e.g. MTN/Airtel, Kampala / Jinja';
      }
      if (normalized == 'In person') {
        return 'e.g. Kampala CBD or nearby meeting point';
      }
      return 'e.g. agreed location or provider';
  }
}

String _suggestedLocationForCountry(String countryCode) {
  switch (countryCode) {
    case 'KE':
      return 'Nairobi CBD';
    case 'TZ':
      return 'Dar es Salaam CBD';
    case 'RW':
      return 'Kigali city center';
    case 'NG':
      return 'Lagos island';
    case 'ZA':
      return 'Johannesburg CBD';
    case 'EG':
      return 'Cairo downtown';
    case 'UG':
    default:
      return 'Kampala CBD';
  }
}

String _suggestedRateHint(
    String countryCode, String? currencyHeld, String? currencyNeeded) {
  if (currencyHeld == null ||
      currencyNeeded == null ||
      currencyHeld == currencyNeeded) {
    return 'Suggested local market area: ${_suggestedLocationForCountry(countryCode)}';
  }

  final rates = {
    'UG': {
      'USD': 3600.0,
      'KES': 29.0,
      'TZS': 0.9,
      'RWF': 2.5,
      'NGN': 0.4,
      'ZAR': 0.2,
      'EGP': 0.07
    },
    'KE': {
      'USD': 128.0,
      'UGX': 0.035,
      'TZS': 0.05,
      'RWF': 0.1,
      'NGN': 0.085,
      'ZAR': 0.007,
      'EGP': 0.013
    },
    'TZ': {
      'USD': 2500.0,
      'UGX': 0.69,
      'KES': 19.5,
      'RWF': 1.9,
      'NGN': 1.7,
      'ZAR': 0.14,
      'EGP': 0.051
    },
    'RW': {
      'USD': 1300.0,
      'UGX': 0.36,
      'KES': 10.1,
      'TZS': 0.52,
      'NGN': 0.87,
      'ZAR': 0.07,
      'EGP': 0.027
    },
    'NG': {
      'USD': 1500.0,
      'UGX': 0.42,
      'KES': 11.7,
      'TZS': 0.6,
      'RWF': 1.15,
      'ZAR': 0.083,
      'EGP': 0.03
    },
    'ZA': {
      'USD': 18.0,
      'UGX': 0.005,
      'KES': 0.14,
      'TZS': 0.007,
      'RWF': 0.014,
      'NGN': 0.012,
      'EGP': 0.37
    },
    'EG': {
      'USD': 49.0,
      'UGX': 0.0136,
      'KES': 0.38,
      'TZS': 0.02,
      'RWF': 0.038,
      'NGN': 0.033,
      'ZAR': 0.27
    },
  };

  final countryMap = rates[countryCode] ?? rates['UG']!;
  final quoteRate = countryMap[currencyNeeded] ?? 1.0;
  final baseText = quoteRate >= 1
      ? '1 $currencyHeld ≈ ${quoteRate.toStringAsFixed(0)} $currencyNeeded'
      : '1 $currencyHeld ≈ ${quoteRate.toStringAsFixed(4)} $currencyNeeded';
  return 'Suggested market area: ${_suggestedLocationForCountry(countryCode)} • Suggested rate: $baseText';
}

class ForexCreatePage extends StatefulWidget {
  const ForexCreatePage({super.key});

  @override
  State<ForexCreatePage> createState() => _ForexCreatePageState();
}

class _ForexCreatePageState extends State<ForexCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _preferredRateController = TextEditingController();
  final _customDistrictController = TextEditingController();
  final _customSettlementController = TextEditingController();
  String? _currencyHeld;
  String? _currencyNeeded;
  String _settlementPreference = 'In person';
  String? _district;
  bool _submitting = false;
  List<CurrencyModel>? _currencies;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshButtonState);
    _preferredRateController.addListener(_refreshButtonState);
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
    _amountController.removeListener(_refreshButtonState);
    _amountController.dispose();
    _preferredRateController.removeListener(_refreshButtonState);
    _preferredRateController.dispose();
    _customDistrictController.dispose();
    _customSettlementController.dispose();
    super.dispose();
  }

  double? _parseDecimal(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _parseAmount(String value) {
    final parsed = _parseDecimal(value);
    if (parsed == null) return null;
    return parsed.round();
  }

  String? get _receivePreview {
    final amount = _parseDecimal(_amountController.text);
    final rate = _parseDecimal(_preferredRateController.text);
    if (amount == null ||
        amount <= 0 ||
        rate == null ||
        rate <= 0 ||
        _currencyHeld == null ||
        _currencyNeeded == null ||
        _currencyHeld == _currencyNeeded) {
      return null;
    }
    final value = amount * rate;
    return '${NumberFormat.decimalPattern().format(value)} $_currencyNeeded';
  }

  void _refreshButtonState() {
    if (mounted) setState(() {});
  }

  bool get _isReadyToPublish {
    final amount = _parseAmount(_amountController.text);
    return amount != null &&
        amount > 0 &&
        _currencyHeld != null &&
        _currencyNeeded != null &&
        _currencyHeld != _currencyNeeded;
  }

  Future<void> _submit() async {
    if (!await ensureOnlineForAction(context) || !mounted) return;
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final fallbackRegion =
        EastAfricaCountries.findByCode(authState.user.country).regions.first;
    final district = _district == 'Other'
        ? _customDistrictController.text.trim().isNotEmpty
            ? _customDistrictController.text.trim()
            : 'Other'
        : (_district ?? fallbackRegion);
    if (!authState.user.kycApproved) {
      _showMessage(
        l10n?.kycGateForex ??
            'Complete KYC verification before posting a forex request.',
      );
      return;
    }

    final canSetPreferredRate =
        authState.user.subscriptionPlan == SubscriptionPlan.pro;
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.reviewYourRequest ?? 'Review your request'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _previewItem(
              'Currency pair',
              '${_currencyHeld ?? ''} to ${_currencyNeeded ?? ''}',
            ),
            _previewItem(
              'Amount to exchange',
              '${NumberFormat.decimalPattern().format(_parseAmount(_amountController.text) ?? 0)} ${_currencyHeld ?? ''}',
            ),
            _previewItem('Estimated amount received',
                _receivePreview ?? 'Not available'),
            _previewItem('Location', district),
            _previewItem(
              'Settlement',
              _formattedSettlementPreference(),
            ),
            if (canSetPreferredRate)
              _previewItem(
                'Preferred rate',
                _parseDecimal(_preferredRateController.text)?.toString() ??
                    'Not specified',
              ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n?.needsPreviewEdit ?? 'Edit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n?.forexPublishBtn ?? 'Publish forex request'),
          ),
        ],
      ),
    );
    if (shouldPublish != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final settlementPreference = _formattedSettlementPreference();
      final id = await getIt<ForexRepository>().createRequest(
        currencyHeld: _currencyHeld!,
        currencyNeeded: _currencyNeeded!,
        amount: _parseAmount(_amountController.text)!,
        district: district,
        settlementPreference: settlementPreference,
        settlementMethod: _settlementMethodKey(_settlementPreference),
        settlementDetails: _customSettlementController.text.trim(),
        preferredRate: canSetPreferredRate
            ? _parseDecimal(_preferredRateController.text)
            : null,
        country: authState.user.country,
      );
      if (!mounted) return;
      context.go('/forex/$id');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        e is AppException
            ? e.message
            : (l10n?.couldNotPublishForex ??
                'Could not publish this forex request.'),
      );
    }
  }

  Widget _previewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
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

  String _getLocalizedSettlement(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'In person':
        return l10n?.forexSettlementInPerson ?? value;
      case 'Mobile money':
        return l10n?.forexSettlementMobileMoney ?? value;
      case 'Bank transfer':
        return l10n?.forexSettlementBankTransfer ?? value;
      case 'Other':
        return l10n?.forexSettlementOther ?? value;
      default:
        return value;
    }
  }

  String _settlementMethodKey(String value) {
    final normalized = _normalizeSettlementLabel(value).toLowerCase();
    if (normalized.contains('bank')) return 'bank';
    if (normalized.contains('mobile') ||
        normalized.contains('m-pesa') ||
        normalized.contains('mpesa') ||
        normalized.contains('momo') ||
        normalized.contains('airtel') ||
        normalized.contains('vodafone')) {
      return 'mobile_money';
    }
    if (normalized.contains('person') ||
        normalized.contains('cash') ||
        normalized.contains('pickup')) {
      return 'in_person';
    }
    return 'other';
  }

  String _formattedSettlementPreference() {
    final detail = _customSettlementController.text.trim();
    final normalized = _normalizeSettlementLabel(_settlementPreference);
    switch (normalized) {
      case 'Bank transfer':
        return detail.isEmpty ? 'Bank transfer' : 'Bank transfer — $detail';
      case 'Mobile money':
        return detail.isEmpty ? 'Mobile money' : 'Mobile money — $detail';
      case 'In person':
        return detail.isEmpty ? 'In person' : 'In person — $detail';
      default:
        return detail.isEmpty ? normalized : '$normalized — $detail';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;

    // ── KYC / eligibility gate ─────────────────────────────────────────────
    if (authState is AuthAuthenticated) {
      if (!authState.user.kycApproved) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n?.createForexRequestTitle ?? 'Post forex request',
        );
      }
      if (!authState.user.canBorrow) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n?.createForexRequestTitle ?? 'Post forex request',
          reason: l10n?.notAllowedListing ??
              'Your account is not eligible to post a request.',
        );
      }
    }

    final currencies = _currencies;
    final heldCurrencyOptions = currencies
        ?.where((currency) => currency.code != _currencyNeeded)
        .toList();
    final neededCurrencyOptions = currencies
        ?.where((currency) => currency.code != _currencyHeld)
        .toList();
    final countryInfo = authState is AuthAuthenticated
        ? EastAfricaCountries.findByCode(authState.user.country)
        : EastAfricaCountries.defaultCountry;
    final settlementOptions =
        _settlementPreferencesForCountry(countryInfo.code);
    final selectedSettlement = settlementOptions.contains(_settlementPreference)
        ? _settlementPreference
        : settlementOptions.first;
    final selectedLocation = _district ?? countryInfo.regions.first;
    final isPro = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.marketplace),
        ),
        title: Text(l10n?.createForexRequestTitle ?? 'Post forex request'),
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
                              label: l10n?.forexCurrencyHeld ?? 'You hold',
                              value: _currencyHeld,
                              currencies: heldCurrencyOptions ?? currencies,
                              onChanged: (value) => setState(() {
                                _currencyHeld = value;
                                if (_currencyNeeded == value) {
                                  _currencyNeeded = null;
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CurrencyField(
                              label: l10n?.forexCurrencyNeeded ?? 'You need',
                              value: _currencyNeeded,
                              currencies: neededCurrencyOptions ?? currencies,
                              onChanged: (value) => setState(() {
                                _currencyNeeded = value;
                                if (_currencyHeld == value) {
                                  _currencyHeld = null;
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        decoration: InputDecoration(
                          labelText: countryInfo.regionsLabel,
                        ),
                        items: countryInfo.regions
                            .map((region) => DropdownMenuItem(
                                  value: region,
                                  child: Text(region),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _district = value ?? countryInfo.regions.first;
                          if (value != 'Other') {
                            _customDistrictController.clear();
                          }
                        }),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Select a location'
                            : null,
                      ),
                      if (selectedLocation == 'Other') ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _customDistrictController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Enter custom location',
                            hintText: 'e.g. Jinja, Fort Portal, or local area',
                          ),
                          validator: (value) {
                            if (selectedLocation == 'Other' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Tell us the location';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: l10n?.forexAmountToExchange ??
                              'Amount you will send',
                          hintText: l10n?.forexAmountHint ?? 'e.g. 100',
                          helperText:
                              'The amount in the currency you hold. Offers use it to show how much of the currency you need you can receive.',
                        ),
                        validator: (v) {
                          final amount = _parseAmount(v ?? '');
                          if (amount == null || amount <= 0) {
                            return l10n?.validationAmountRequired ??
                                'Enter an amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedSettlement,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.forexSettlementPreference ?? 'Settlement',
                        ),
                        items: settlementOptions
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child:
                                      Text(_getLocalizedSettlement(context, p)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _settlementPreference = v ?? settlementOptions.first;
                          if (_normalizeSettlementLabel(
                                  _settlementPreference) ==
                              'In person') {
                            _customSettlementController.clear();
                          }
                        }),
                      ),
                      if (_normalizeSettlementLabel(_settlementPreference) !=
                          'In person') ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _customSettlementController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: switch (_normalizeSettlementLabel(
                                _settlementPreference)) {
                              'Bank transfer' => 'Bank name or branch',
                              'Mobile money' => 'Provider / wallet / area',
                              'Other' => 'Settlement detail',
                              _ => 'Settlement detail',
                            },
                            hintText: _settlementInputHint(
                              countryInfo.code,
                              _settlementPreference,
                            ),
                          ),
                          validator: (value) {
                            if (_normalizeSettlementLabel(
                                    _settlementPreference) ==
                                'In person') return null;
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return switch (_normalizeSettlementLabel(
                                  _settlementPreference)) {
                                'Bank transfer' => 'Enter the bank name',
                                'Mobile money' =>
                                  'Enter the mobile money provider',
                                'Other' => 'Add the settlement detail',
                                _ => 'Add a detail',
                              };
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (_currencyHeld != null && _currencyNeeded != null)
                        Text(
                          _suggestedRateHint(
                            countryInfo.code,
                            _currencyHeld,
                            _currencyNeeded,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.text2Dark
                                        : AppColors.text2Light,
                                  ),
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _preferredRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final rate = _parseDecimal(v);
                          if (rate == null || rate <= 0) {
                            return 'Enter a valid rate';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText:
                              l10n?.forexPreferredRate ?? 'Preferred rate',
                          hintText: l10n?.forexRateHint ?? 'e.g. 3700',
                          helperText: isPro
                              ? 'Optional. Shows a live receive estimate and saves your preferred rate.'
                              : 'Use this for a quick receive estimate. Pro saves preferred rates to requests.',
                        ),
                      ),
                      if (_receivePreview != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You receive',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _receivePreview!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontFamily: AppFonts.heading,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              _submitting || (currencies?.length ?? 0) < 2 || !_isReadyToPublish
                  ? null
                  : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n?.needsPreviewBtn ?? 'Preview request',
                ),
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
