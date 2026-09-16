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
import '../../../../shared/widgets/kyc_gate_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/needs_repository.dart';

class NeedsCreatePage extends StatefulWidget {
  const NeedsCreatePage({super.key});

  @override
  State<NeedsCreatePage> createState() => _NeedsCreatePageState();
}

class _NeedsCreatePageState extends State<NeedsCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _specificationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _customLocationController = TextEditingController();

  String _category = 'Business Equipment';
  String _urgency = 'Within 30 days';
  String? _location;
  bool _submitting = false;

  static const _categories = [
    'Business Equipment',
    'Inventory',
    'Agriculture',
    'Education',
    'Health',
    'Home & Energy',
    'Community',
    'Technology',
    'Transport',
    'Other',
  ];

  static const _urgencies = [
    'Urgent',
    'Within 30 days',
    'This month',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refresh);
    _specificationController.addListener(_refresh);
    _budgetController.addListener(_refresh);
    _customLocationController.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specificationController.dispose();
    _budgetController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isReadyToPublish {
    final title = _titleController.text.trim();
    final specification = _specificationController.text.trim();
    final budget = int.tryParse(_budgetController.text.replaceAll(',', ''));
    final location = _effectiveLocation.trim();
    return title.length >= 4 &&
        specification.length >= 12 &&
        budget != null &&
        budget >= 0 &&
        location.isNotEmpty;
  }

  CountryInfo _countryInfo(AuthState authState) {
    if (authState is! AuthAuthenticated) {
      return EastAfricaCountries.defaultCountry;
    }
    return EastAfricaCountries.findByCode(authState.user.country);
  }

  String _currency(AuthState authState) {
    if (authState is! AuthAuthenticated) {
      return EastAfricaCountries.defaultCountry.currency;
    }
    if (authState.user.incomeCurrency.isNotEmpty) {
      return authState.user.incomeCurrency;
    }
    return EastAfricaCountries.findByCode(authState.user.country).currency;
  }

  String get _effectiveLocation {
    if (_location == 'Other') return _customLocationController.text;
    return _location ?? '';
  }

  int _budgetValue() {
    return int.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0;
  }

  String _categoryLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'Business Equipment' => l10n.needsCategoryBusinessEquipment,
      'Inventory' => l10n.needsCategoryInventory,
      'Agriculture' => l10n.needsCategoryAgriculture,
      'Education' => l10n.needsCategoryEducation,
      'Health' => l10n.needsCategoryHealth,
      'Home & Energy' => l10n.needsCategoryHomeEnergy,
      'Community' => l10n.needsCategoryCommunity,
      'Technology' => l10n.needsCategoryTechnology,
      'Transport' => l10n.needsCategoryTransport,
      _ => l10n.purposeOther,
    };
  }

  String _urgencyLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'Urgent' => l10n.needsUrgencyUrgent,
      'Within 30 days' => l10n.needsUrgencyWithin30Days,
      'This month' => l10n.needsUrgencyThisMonth,
      _ => l10n.needsUrgencyFlexible,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final country = EastAfricaCountries.findByCode(authState.user.country);
      final requestId = await getIt<NeedsRepository>().createRequest(
        title: _titleController.text,
        specification: _specificationController.text,
        category: _category,
        budget: _budgetValue(),
        currency: _currency(authState),
        location: _effectiveLocation,
        urgency: _urgency,
        country: country.code,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.requestSubmittedTitle),
          content: Text(l10n.needsRequestSubmittedContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
      if (dialogResult == true && mounted) {
        context.go('/marketplace/needs/$requestId');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : l10n.couldNotPublishRequest,
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      if (!authState.user.kycApproved) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n.createNeedsRequestTitle,
        );
      }
      if (!authState.user.canBorrow) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n.createNeedsRequestTitle,
          reason: l10n.notAllowedListing,
        );
      }
    }

    final country = _countryInfo(authState);
    final currency = _currency(authState);
    final selectedLocation = _location ?? country.regions.first;
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.marketplace),
        ),
        title: Text(l10n.createNeedsRequestTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.needsTitleLabel,
                    hintText: l10n.needsTitleHint,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return l10n.validationTitleRequired;
                    if (text.length < 4) return l10n.validationTitleMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration:
                      InputDecoration(labelText: l10n.needsCategoryLabel),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabel(l10n, category)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _category = value ?? _categories.first,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specificationController,
                  minLines: 4,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.needsSpecificationLabel,
                    hintText: l10n.needsSpecificationHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return l10n.needsSpecificationRequired;
                    }
                    if (text.length < 12) {
                      return l10n.needsSpecificationMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.needsBudgetLabel(currency),
                    hintText: l10n.needsBudgetHint,
                    helperText: l10n.needsBudgetHelper,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return l10n.validationAmountRequired;
                    final amount = int.tryParse(text.replaceAll(',', ''));
                    if (amount == null || amount < 0) {
                      return l10n.validationValidNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedLocation,
                  decoration: InputDecoration(labelText: country.regionsLabel),
                  items: country.regions
                      .map(
                        (region) => DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _location = value ?? country.regions.first;
                      if (_location != 'Other') {
                        _customLocationController.clear();
                      }
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.needsLocationRequired
                      : null,
                ),
                if (selectedLocation == 'Other') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _customLocationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.needsCustomLocationLabel,
                      hintText: l10n.needsCustomLocationHint,
                    ),
                    validator: (value) {
                      if (selectedLocation != 'Other') return null;
                      if ((value ?? '').trim().isEmpty) {
                        return l10n.needsLocationRequired;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _urgency,
                  decoration:
                      InputDecoration(labelText: l10n.needsUrgencyLabel),
                  items: _urgencies
                      .map(
                        (urgency) => DropdownMenuItem(
                          value: urgency,
                          child: Text(_urgencyLabel(l10n, urgency)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _urgency = value ?? _urgencies.first,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.needsBudgetPreview(
                    currency,
                    formatter.format(_budgetValue()),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _submitting || !_isReadyToPublish ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.needsPublishBtn),
        ),
      ),
    );
  }
}
