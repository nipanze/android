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
import '../../domain/models/need_category.dart';
import '../../domain/models/need_form_schema.dart';

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

  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, bool> _dynamicBooleans = {};
  List<NeedCategory> _categories = NeedCategory.defaultCategories;

  String _categorySlug = 'machinery_equipment';
  String _urgency = 'Within 30 days';
  String? _location;
  bool _submitting = false;

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
    _initCategoryControllers();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await getIt<NeedsRepository>().getCategories();
    if (!mounted || categories.isEmpty) return;

    setState(() {
      _categories = categories;
      if (!categories.any((category) => category.slug == _categorySlug)) {
        _categorySlug = categories.first.slug;
        _initCategoryControllers();
      }
    });
  }

  void _initCategoryControllers() {
    final fields = NeedFormSchema.fieldsForCategory(_categorySlug);
    for (final field in fields) {
      if (field.type == NeedFieldType.boolean) {
        _dynamicBooleans.putIfAbsent(field.key, () => false);
      } else {
        _dynamicControllers.putIfAbsent(
          field.key,
          () => TextEditingController()..addListener(_refresh),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specificationController.dispose();
    _budgetController.dispose();
    _customLocationController.dispose();
    for (final controller in _dynamicControllers.values) {
      controller.dispose();
    }
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

    if (title.length < 4 ||
        specification.length < 12 ||
        budget == null ||
        budget < 0 ||
        location.isEmpty) {
      return false;
    }

    // Verify required category fields
    final fields = NeedFormSchema.fieldsForCategory(_categorySlug);
    for (final f in fields) {
      if (f.isRequired && f.type != NeedFieldType.boolean) {
        final ctrl = _dynamicControllers[f.key];
        if (ctrl == null || ctrl.text.trim().isEmpty) {
          return false;
        }
      }
    }

    return true;
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

  String _categoryLocalizedName(AppLocalizations l10n, String slug) {
    final category = _categories.firstWhere(
      (item) => item.slug == slug,
      orElse: () => NeedCategory.findBySlug(slug),
    );
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        category.countryLabels
            .containsKey(authState.user.country.toUpperCase())) {
      return category.nameForCountry(authState.user.country);
    }
    return switch (slug) {
      'travel_international' => 'Travel & International',
      'machinery_equipment' => 'Machinery & Equipment',
      'professional_services' => 'Professional Services',
      'transport_logistics' => 'Transport & Logistics',
      _ => category.name,
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

  Map<String, dynamic> _collectDetails() {
    final map = <String, dynamic>{};
    final fields = NeedFormSchema.fieldsForCategory(_categorySlug);
    for (final field in fields) {
      if (field.type == NeedFieldType.boolean) {
        map[field.key] = _dynamicBooleans[field.key] ?? false;
      } else if (field.type == NeedFieldType.number) {
        final text = _dynamicControllers[field.key]?.text.trim() ?? '';
        map[field.key] = num.tryParse(text) ?? text;
      } else {
        map[field.key] = _dynamicControllers[field.key]?.text.trim() ?? '';
      }
    }
    return map;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final dynamicFields = NeedFormSchema.fieldsForCategory(_categorySlug);
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.needsPreviewTitle),
        scrollable: true,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _previewRow(
                l10n.needsCategoryLabel,
                _categoryLocalizedName(l10n, _categorySlug),
              ),
              _previewRow(l10n.needsTitleLabel, _titleController.text.trim()),
              _previewRow(
                _categorySlug == 'education_training'
                    ? 'Course / Subject / Skill'
                    : l10n.needsSpecificationLabel,
                _specificationController.text.trim(),
              ),
              for (final field in dynamicFields)
                _previewRow(
                  field.label,
                  field.type == NeedFieldType.boolean
                      ? ((_dynamicBooleans[field.key] ?? false) ? 'Yes' : 'No')
                      : _dynamicControllers[field.key]?.text.trim() ?? '',
                ),
              _previewRow(
                _categorySlug == 'education_training'
                    ? 'Maximum Budget (${_currency(authState)})'
                    : l10n.needsBudgetLabel(_currency(authState)),
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(_budgetValue()),
              ),
              _previewRow(
                _countryInfo(authState).regionsLabel,
                _effectiveLocation.trim(),
              ),
              _previewRow(
                l10n.needsUrgencyLabel,
                _urgencyLabel(l10n, _urgency),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.needsPreviewEdit),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.needsPublishBtn),
          ),
        ],
      ),
    );

    if (shouldPublish == true && mounted) await _publish();
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final country = EastAfricaCountries.findByCode(authState.user.country);
      final categoryObj = _categories.firstWhere(
        (category) => category.slug == _categorySlug,
        orElse: () => NeedCategory.findBySlug(_categorySlug),
      );
      final requestId = await getIt<NeedsRepository>().createRequest(
        title: _titleController.text,
        specification: _specificationController.text,
        categorySlug: _categorySlug,
        categoryName: categoryObj.name,
        details: _collectDetails(),
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
    final theme = Theme.of(context);

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

    final guidance = NeedFormSchema.categoryGuidance[_categorySlug];
    final dynamicFields = NeedFormSchema.fieldsForCategory(_categorySlug);

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
                Text(
                  'Choose Need Category',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categorySlug,
                  decoration: InputDecoration(
                    labelText: l10n.needsCategoryLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.slug,
                          child: Row(
                            children: [
                              Text(cat.icon,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(_categoryLocalizedName(l10n, cat.slug)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value != _categorySlug) {
                      setState(() {
                        _categorySlug = value;
                        _initCategoryControllers();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.needsTitleLabel,
                    hintText: guidance?.titleHint ?? l10n.needsTitleHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return l10n.validationTitleRequired;
                    if (text.length < 4) return l10n.validationTitleMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specificationController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _categorySlug == 'education_training'
                        ? 'Course / Subject / Skill'
                        : l10n.needsSpecificationLabel,
                    hintText: guidance?.specificationHint ??
                        l10n.needsSpecificationHint,
                    helperText: guidance?.specificationHelper,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
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
                if (dynamicFields.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Category Specifics',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final field in dynamicFields) ...[
                    if (field.type == NeedFieldType.boolean)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(field.label),
                        subtitle: field.helperText == null
                            ? null
                            : Text(field.helperText!),
                        value: _dynamicBooleans[field.key] ?? false,
                        onChanged: (val) {
                          setState(() {
                            _dynamicBooleans[field.key] = val;
                          });
                        },
                      )
                    else if (field.options != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _dynamicControllers[field.key]?.text.isEmpty ??
                                      true
                                  ? null
                                  : _dynamicControllers[field.key]?.text,
                          decoration: InputDecoration(
                            labelText: field.label,
                            hintText: field.hint,
                            helperText: field.helperText,
                            border: const OutlineInputBorder(),
                          ),
                          items: field.options!
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            _dynamicControllers[field.key]?.text = value ?? '';
                          },
                          validator: (value) {
                            if (field.isRequired &&
                                (value == null || value.isEmpty)) {
                              return 'Please fill in this requirement';
                            }
                            return null;
                          },
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _dynamicControllers[field.key],
                          keyboardType: field.type == NeedFieldType.number
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: field.label,
                            hintText: field.hint,
                            helperText: field.helperText,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (field.isRequired &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Please fill in this requirement';
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _categorySlug == 'education_training'
                        ? 'Maximum Budget ($currency)'
                        : l10n.needsBudgetLabel(currency),
                    hintText: l10n.needsBudgetHint,
                    helperText: l10n.needsBudgetHelper,
                    border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: country.regionsLabel,
                    border: const OutlineInputBorder(),
                  ),
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
                      border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: l10n.needsUrgencyLabel,
                    border: const OutlineInputBorder(),
                  ),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _submitting || !_isReadyToPublish ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.needsPreviewBtn),
        ),
      ),
    );
  }
}
