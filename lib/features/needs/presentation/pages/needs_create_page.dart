import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/localization_fallback.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/form_suggestion_strip.dart';
import '../../../../shared/widgets/kyc_gate_screen.dart';
import '../../../../shared/widgets/post_duration_info_card.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../marketplace/domain/models/marketplace_item.dart';
import '../../../settings/data/system_settings_repository.dart';
import '../../data/need_draft_exit_guard.dart';
import '../../data/need_draft_store.dart';
import '../../data/needs_repository.dart';
import '../../domain/models/need_category.dart';
import '../../domain/models/need_form_schema.dart';

class NeedsCreatePage extends StatefulWidget {
  const NeedsCreatePage({super.key, this.initialCategorySlug, this.draftId});

  final String? initialCategorySlug;
  final String? draftId;

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
  List<NeedsListing> _recentRequests = const [];
  String? _recentRequestsLoadError;

  String _categorySlug = 'machinery_equipment';
  String _categoryAtOpen = 'machinery_equipment';
  String _urgency = 'Within 30 days';
  String? _location;
  bool _locationTouched = false;
  bool _submitting = false;
  bool _savingDraft = false;
  bool _allowExit = false;
  String? _draftId;
  PlatformLimits _limits = PlatformLimits.defaults;

  static const _urgencies = [
    'Urgent',
    'Within 30 days',
    'This month',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
    _draftId = widget.draftId;
    if (NeedCategory.defaultCategories
        .any((category) => category.slug == widget.initialCategorySlug)) {
      _categorySlug = widget.initialCategorySlug!;
    }
    _categoryAtOpen = _categorySlug;
    _titleController.addListener(_refresh);
    _specificationController.addListener(_refresh);
    _budgetController.addListener(_refresh);
    _customLocationController.addListener(_refresh);
    _initCategoryControllers();
    NeedDraftExitGuard.register(
      this,
      hasChanges: () => _hasDraftContent,
      saveDraft: _saveDraft,
    );
    if (widget.draftId != null) _loadDraft();
    _loadCategories();
    _loadLimits();
    _loadRecentRequests();
  }

  Future<void> _loadDraft() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || widget.draftId == null) return;
    final draft = await NeedDraftStore.find(authState.user.id, widget.draftId!);
    if (!mounted || draft == null) return;
    setState(() {
      final slug = draft['category_slug']?.toString();
      if (slug != null &&
          NeedCategory.defaultCategories
              .any((category) => category.slug == slug)) {
        _categorySlug = slug;
        _initCategoryControllers();
      }
      _titleController.text = draft['title']?.toString() ?? '';
      _specificationController.text = draft['specification']?.toString() ?? '';
      _budgetController.text = draft['budget']?.toString() ?? '';
      _location = draft['location']?.toString();
      _customLocationController.text =
          draft['custom_location']?.toString() ?? '';
      final urgency = draft['urgency']?.toString();
      if (urgency != null && _urgencies.contains(urgency)) _urgency = urgency;
      final details = draft['details'];
      if (details is Map) {
        for (final entry in details.entries) {
          final field = _fieldByKey(entry.key.toString());
          if (field == null) continue;
          if (field.type == NeedFieldType.boolean) {
            _dynamicBooleans[field.key] =
                entry.value == true || entry.value.toString() == 'true';
          } else {
            _dynamicControllers[field.key]?.text = entry.value.toString();
          }
        }
      }
    });
  }

  Future<void> _loadRecentRequests() async {
    try {
      final requests =
          await getIt<NeedsRepository>().getMyRecentRequests(limit: 12);
      if (!mounted) return;
      setState(() {
        _recentRequests = requests;
        _recentRequestsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentRequestsLoadError = parseSupabaseError(e).message;
      });
    }
  }

  Future<void> _loadLimits() async {
    try {
      final limits = await getIt<SystemSettingsRepository>().getLimits();
      if (!mounted) return;
      setState(() => _limits = limits);
    } catch (_) {}
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
    NeedDraftExitGuard.unregister(this);
    _titleController.dispose();
    _specificationController.dispose();
    _budgetController.dispose();
    _customLocationController.dispose();
    for (final controller in _dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasDraftContent =>
      _draftId != null ||
      _categorySlug != _categoryAtOpen ||
      _titleController.text.trim().isNotEmpty ||
      _specificationController.text.trim().isNotEmpty ||
      _budgetController.text.trim().isNotEmpty ||
      _customLocationController.text.trim().isNotEmpty ||
      _locationTouched ||
      _urgency != 'Within 30 days' ||
      _dynamicControllers.values
          .any((controller) => controller.text.trim().isNotEmpty) ||
      _dynamicBooleans.values.any((value) => value);

  Future<void> _confirmAndPop() async {
    if (!await NeedDraftExitGuard.confirmExit(context) || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.needsCreate);
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _fieldLabel(String label, String _) {
    return Text(label);
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

  void _selectCategory(String slug) {
    if (slug == _categorySlug) return;
    setState(() {
      _categorySlug = slug;
      _initCategoryControllers();
    });
  }

  void _applyPreset(NeedFormPreset preset) {
    setState(() {
      _titleController.text = preset.title;
      _specificationController.text = preset.specification;
      if (preset.budget != null) {
        _budgetController.text = preset.budget.toString();
      }
      if (preset.urgency != null && _urgencies.contains(preset.urgency)) {
        _urgency = preset.urgency!;
      }
      for (final entry in preset.details.entries) {
        final field = _fieldByKey(entry.key);
        if (field == null) continue;
        if (field.type == NeedFieldType.boolean) {
          _dynamicBooleans[entry.key] = entry.value.toLowerCase() == 'true';
        } else {
          _dynamicControllers[entry.key]?.text = entry.value;
        }
      }
    });
  }

  List<NeedsListing> get _recentRequestsForCategory => _recentRequests
      .where((request) => request.categorySlug == _categorySlug)
      .toList();

  List<String> _recentValues(String Function(NeedsListing) select) {
    final values = <String>[];
    final seen = <String>{};
    for (final request in _recentRequestsForCategory) {
      final value = select(request).trim();
      if (value.isNotEmpty && seen.add(value)) {
        values.add(value);
        if (values.length == 4) break;
      }
    }
    return values;
  }

  List<String> _recentValuesAcrossCategories(
    String Function(NeedsListing) select,
  ) {
    final values = <String>[];
    final seen = <String>{};
    for (final request in _recentRequests) {
      final value = select(request).trim();
      if (value.isNotEmpty && seen.add(value)) {
        values.add(value);
        if (values.length == 4) break;
      }
    }
    return values;
  }

  void _applyRecentRequest(NeedsListing request) {
    setState(() {
      _titleController.text = request.title;
      _specificationController.text = request.specification;
      if (request.currency == _currency(context.read<AuthBloc>().state)) {
        _budgetController.text = request.budget.toString();
      }
      _urgency = _urgencies.contains(request.urgency)
          ? request.urgency
          : _urgencies.last;
      if (request.location == 'Other' ||
          _countryInfo(context.read<AuthBloc>().state)
              .regions
              .contains(request.location)) {
        _location = request.location;
        _customLocationController.clear();
      } else {
        _location = 'Other';
        _customLocationController.text = request.location;
      }
      for (final entry in request.details.entries) {
        final field = _fieldByKey(entry.key);
        if (field == null) continue;
        if (field.type == NeedFieldType.boolean) {
          _dynamicBooleans[entry.key] =
              entry.value == true || entry.value.toString() == 'true';
        } else {
          _dynamicControllers[entry.key]?.text = entry.value.toString();
        }
      }
    });
  }

  NeedFormField? _fieldByKey(String key) {
    for (final field in NeedFormSchema.fieldsForCategory(_categorySlug)) {
      if (field.key == key) return field;
    }
    return null;
  }

  void _setFieldValue(NeedFormField field, String value) {
    setState(() {
      if (field.type == NeedFieldType.boolean) {
        _dynamicBooleans[field.key] = value.toLowerCase() == 'true';
      } else {
        _dynamicControllers[field.key]?.text = value;
      }
    });
  }

  void _setBudgetPercent(double percent) {
    final current = _budgetValue();
    final base = current > 0 ? current : 100000;
    _budgetController.text = (base * percent).round().toString();
  }

  void _adjustBudget(int delta) {
    final current = _budgetValue();
    final next = (current + delta).clamp(0, 1000000000);
    _budgetController.text = next.toString();
  }

  void _adjustDynamicNumber(NeedFormField field, int delta) {
    final controller = _dynamicControllers[field.key];
    if (controller == null) return;
    final current = int.tryParse(controller.text.replaceAll(',', '')) ?? 0;
    final next = (current + delta).clamp(0, 1000000000);
    setState(() => controller.text = next.toString());
  }

  Widget _buildStarterPresets() {
    final presets = NeedFormSchema.presetsForCategory(_categorySlug);
    final recentRequests = _recentRequestsForCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSuggestionStrip(
          label: 'Start with',
          suggestions: [
            ...recentRequests.map((request) => 'Repeat: ${request.title}'),
            ...presets.map((preset) => preset.label),
          ],
          onSelected: (value) {
            final recent = recentRequests
                .where((request) => 'Repeat: ${request.title}' == value)
                .firstOrNull;
            if (recent != null) {
              _applyRecentRequest(recent);
              return;
            }
            final preset =
                presets.where((preset) => preset.label == value).firstOrNull;
            if (preset != null) _applyPreset(preset);
          },
        ),
      ],
    );
  }

  Widget _buildOptionPills(NeedFormField field) {
    return FormSuggestionStrip(
      label: 'Try',
      suggestions: _optionsForField(field),
      onSelected: (value) => _setFieldValue(field, value),
    );
  }

  List<String> _optionsForField(NeedFormField field) {
    final selected = _dynamicControllers[field.key]?.text;
    return {
      ...field.options!,
      ..._suggestionsForField(field),
      if (selected != null && selected.isNotEmpty) selected,
    }.toList();
  }

  Widget _buildBudgetShortcuts(String currency) {
    final recentAmounts = _recentValuesAcrossCategories(
      (request) => request.currency == currency && request.budget > 0
          ? '$currency ${request.budget}'
          : '',
    );
    return FormSuggestionStrip(
      label: 'Try',
      suggestions: [
        ...recentAmounts,
        'Lower 25%',
        'Fair target',
        'Add 25%',
        '+$currency 50k',
        '-$currency 50k',
      ],
      onSelected: (value) {
        if (value == 'Lower 25%') {
          _setBudgetPercent(0.75);
        } else if (value == 'Fair target') {
          _setBudgetPercent(1.0);
        } else if (value == 'Add 25%') {
          _setBudgetPercent(1.25);
        } else if (value.startsWith('+$currency')) {
          _adjustBudget(50000);
        } else if (value.startsWith('-$currency')) {
          _adjustBudget(-50000);
        } else {
          _budgetController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
        }
      },
    );
  }

  Widget _buildBudgetStepperSuffix() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => _adjustBudget(-50000),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => _adjustBudget(50000),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  List<String> _quickValuesForField(NeedFormField field) {
    final category = _categorySlug;
    return switch (field.key) {
      'destination_country' => const [
          'Saudi Arabia',
          'UAE',
          'Qatar',
          'Turkey',
          'India',
          'China',
          'United Kingdom',
          'USA',
        ],
      'destination_city' => const [
          'Makkah',
          'Madinah',
          'Dubai',
          'Doha',
          'Istanbul',
          'Mumbai',
          'London',
          'Guangzhou',
        ],
      'departure_city' => CountryLocations.localitiesFor(
          _countryInfo(context.read<AuthBloc>().state),
        ),
      'nationality' => CountryLocations.nationalitiesFor(
          _countryInfo(context.read<AuthBloc>().state),
        ),
      'purpose' => const [
          'Hajj',
          'Umrah',
          'Tourism',
          'Business',
          'Study',
          'Family visit',
          'Medical',
        ],
      'service_needed' => const [
          'Hajj package',
          'Umrah package',
          'Visa assistance',
          'Flight ticket',
          'Hotel booking',
          'Full travel package',
        ],
      'visa_type' => const [
          'Hajj visa',
          'Umrah visa',
          'Tourist visa',
          'Business visa',
          'Student visa',
          'Transit visa',
        ],
      'travel_date' || 'return_date' || 'event_date' || 'shoot_date' => const [
          'As soon as possible',
          'This month',
          'Next month',
          'December 2026',
          'Flexible',
        ],
      'duration_days' => const ['3', '7', '14', '30', '60'],
      'travellers' => const ['1', '2', '3', '4', '5'],
      'duration' => const ['2 weeks', '8 weeks', '3 months', '6 months'],
      'schedule' => const ['Full-time', 'Part-time', 'Weekends', 'Flexible'],
      'start_date' => const [
          'As soon as possible',
          'Next week',
          'Next month',
          'Flexible',
        ],
      'training_type' => const [
          'Tutoring',
          'Internship',
          'Vocational training',
          'Professional training',
        ],
      'training_level' => const [
          'Beginner',
          'Intermediate',
          'Advanced',
          'University',
        ],
      'preferred_location' => const [
          'Near campus',
          'At home',
          'Provider location',
          'Flexible',
        ],
      'deadline' || 'timeline' => const [
          '1 week',
          '2 weeks',
          '1 month',
          '6 weeks',
          'Flexible',
        ],
      'quantity' => const ['1 unit', '10 units', '50 units', '100 units'],
      'volume_or_acres' => const ['1 acre', '5 acres', '10 acres', '50 bags'],
      'event_type' when category == 'events_production' => const [
          'Catering',
          'Sound & stage',
          'Corporate event',
          'Birthday',
          'Graduation',
        ],
      'celebration_type' => const [
          'Wedding, 150 guests',
          'Introduction ceremony',
          'Birthday, 50 guests',
          'Graduation party',
        ],
      'venue_location' ||
      'location' ||
      'site_location' ||
      'farm_location' ||
      'delivery_location' ||
      'installation_site' ||
      'from_location' ||
      'to_location' =>
        CountryLocations.localitiesFor(
          _countryInfo(context.read<AuthBloc>().state),
        ),
      'equipment_type' => const [
          'Excavator',
          'Generator',
          'Truck',
          'Concrete mixer',
        ],
      'service_type' => const [
          'Accounting',
          'Legal support',
          'Tax filing',
          'Business registration',
          'Driving School & Driver Training',
        ],
      'project_type' => const ['Roofing', 'Plumbing', 'Electrical', 'Painting'],
      'agri_item' => const [
          'Seeds',
          'Fertilizer',
          'Harvester hire',
          'Irrigation equipment',
        ],
      'tech_requirement' => const [
          'Website',
          'Mobile app',
          'POS system',
          'CCTV setup',
        ],
      'production_type' => const [
          'Music video',
          'Live session',
          'Short film',
          'Event coverage',
        ],
      'system_type' => const [
          'Solar system',
          'Water pump',
          'Borehole pump',
          'Backup power',
        ],
      _ => const [],
    };
  }

  List<String> _suggestionsForField(NeedFormField field) => {
        ..._quickValuesForField(field),
        ..._recentValues(
          (request) => request.details[field.key]?.toString() ?? '',
        ),
      }.toList();

  Map<String, String> _localizedNationalities(AppLocalizations l10n) => {
        'Ugandan': l10n.nationalityUgandan,
        'Kenyan': l10n.nationalityKenyan,
        'Tanzanian': l10n.nationalityTanzanian,
        'Rwandan': l10n.nationalityRwandan,
        'Nigerian': l10n.nationalityNigerian,
        'South African': l10n.nationalitySouthAfrican,
        'Egyptian': l10n.nationalityEgyptian,
        'Congolese (DRC)': l10n.nationalityCongoleseDrc,
        'Burundian': l10n.nationalityBurundian,
        'South Sudanese': l10n.nationalitySouthSudanese,
        'Somali': l10n.nationalitySomali,
      };

  Widget _buildFieldQuickValues(NeedFormField field) {
    final values = _suggestionsForField(field);
    if (values.isEmpty) return const SizedBox.shrink();
    final localizedNationalities = field.key == 'nationality'
        ? _localizedNationalities(AppLocalizations.of(context)!)
        : const <String, String>{};
    return FormSuggestionStrip(
      label: 'Try',
      suggestions: values
          .map((value) => localizedNationalities[value] ?? value)
          .toList(),
      onSelected: (value) {
        final source = localizedNationalities.entries
            .where((entry) => entry.value == value)
            .map((entry) => entry.key)
            .firstOrNull;
        _setFieldValue(field, source ?? value);
      },
    );
  }

  Widget _buildStepperSuffix(NeedFormField field) {
    final step = field.key == 'travellers' ? 1 : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => _adjustDynamicNumber(field, -step),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => _adjustDynamicNumber(field, step),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  Widget _buildTextInputWithHelpers(NeedFormField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _dynamicControllers[field.key],
            keyboardType: field.type == NeedFieldType.number
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters: field.type == NeedFieldType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              label: _fieldLabel(field.label, field.guidance),
              hintText: field.hint,
              helperText: field.helperText,
              suffixIcon: field.type == NeedFieldType.number
                  ? _buildStepperSuffix(field)
                  : null,
              border: const OutlineInputBorder(),
            ),
            validator: (val) {
              if (field.isRequired && (val == null || val.trim().isEmpty)) {
                return 'Please fill in this requirement';
              }
              return null;
            },
          ),
          _buildFieldQuickValues(field),
        ],
      ),
    );
  }

  bool _isTransportLocationPairAt(List<NeedFormField> fields, int index) {
    return _categorySlug == 'transport_logistics' &&
        index + 1 < fields.length &&
        fields[index].key == 'from_location' &&
        fields[index + 1].key == 'to_location';
  }

  bool _isTransportLocationPairStart(
    List<NeedFormField> fields,
    NeedFormField field,
  ) =>
      _isTransportLocationPairAt(fields, fields.indexOf(field));

  bool _isTransportLocationPairEnd(
    List<NeedFormField> fields,
    NeedFormField field,
  ) {
    final index = fields.indexOf(field);
    return index > 0 && _isTransportLocationPairAt(fields, index - 1);
  }

  String _categoryLocalizedName(AppLocalizations l10n, String slug) {
    final category = _categories.firstWhere(
      (item) => item.slug == slug,
      orElse: () => NeedCategory.findBySlug(slug),
    );
    final localizedName = category.localizedName(
      Localizations.localeOf(context).languageCode,
    );
    if (localizedName != category.baseName && localizedName != category.name) {
      return localizedName;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        category.countryLabels
            .containsKey(authState.user.country.toUpperCase())) {
      return category.nameForCountry(authState.user.country);
    }
    return localizedName;
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
        final value = _dynamicControllers[field.key]?.text.trim() ?? '';
        if (field.key == 'nationality') {
          final l10n = AppLocalizations.of(context)!;
          final localizedNationalities = _localizedNationalities(l10n);
          map[field.key] = localizedNationalities.entries
              .firstWhere(
                (entry) => entry.value == value,
                orElse: () => MapEntry(value, value),
              )
              .key;
        } else {
          map[field.key] = value;
        }
      }
    }
    return map;
  }

  Future<void> _submit() async {
    if (!await ensureOnlineForAction(context) || !mounted) return;
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
                  intlLocaleName(Localizations.localeOf(context)),
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
              _previewRow(
                l10n.reviewDuration,
                l10n.postDurationActiveDays(
                  _limits.durationForNeedsCategory(_categorySlug),
                ),
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
      if (_draftId != null) {
        try {
          await NeedDraftStore.delete(authState.user.id, _draftId!);
        } catch (_) {
          // Publishing succeeded; a local cleanup issue must not hide it.
        }
      }
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

  Future<bool> _saveDraft() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return false;
    if (!_hasDraftContent) return false;
    setState(() => _savingDraft = true);
    try {
      final saved = await NeedDraftStore.save(
        authState.user.id,
        {
          'title': _titleController.text.trim(),
          'specification': _specificationController.text.trim(),
          'category_slug': _categorySlug,
          'details': _collectDetails(),
          'budget': _budgetController.text.trim(),
          'location': _location,
          'custom_location': _customLocationController.text.trim(),
          'urgency': _urgency,
        },
        id: _draftId,
      );
      if (!mounted) return false;
      setState(() {
        _draftId = saved['draft_id']?.toString();
        _savingDraft = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved on this device.')),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _savingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save draft: $error')),
      );
      return false;
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
    if (_location == null && country.regions.isNotEmpty) {
      _location = country.regions.first;
    }
    final selectedLocation = _location ?? country.regions.first;
    final formatter = NumberFormat.decimalPattern(
      intlLocaleName(Localizations.localeOf(context)),
    );

    final guidance = NeedFormSchema.guidanceForCategory(_categorySlug);
    final selectedCategory = _categories.firstWhere(
      (category) => category.slug == _categorySlug,
      orElse: () => NeedCategory.findBySlug(_categorySlug),
    );
    final countryCode =
        authState is AuthAuthenticated ? authState.user.country : null;
    final categoryDescription =
        selectedCategory.descriptionForCountry(countryCode)?.trim();
    final dynamicFields = NeedFormSchema.fieldsForCategory(_categorySlug);

    return PopScope<Object?>(
      canPop: !_hasDraftContent || _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _confirmAndPop,
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
                  if (_recentRequestsLoadError != null) ...[
                    Text(
                      'Previous Need suggestions unavailable: '
                      '$_recentRequestsLoadError',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Choose Need Category',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$_categorySlug'),
                    initialValue: _categorySlug,
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        l10n.needsCategoryLabel,
                        categoryDescription != null &&
                                categoryDescription.isNotEmpty
                            ? categoryDescription
                            : guidance.specificationHelper,
                      ),
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
                      if (value != null) _selectCategory(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        l10n.needsTitleLabel,
                        guidance.titleHint,
                      ),
                      hintText: guidance.titleHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return l10n.validationTitleRequired;
                      if (text.length < 4) return l10n.validationTitleMinLength;
                      return null;
                    },
                  ),
                  FormSuggestionStrip(
                    label: 'Recent',
                    suggestions: _recentValues((request) => request.title),
                    onSelected: (value) =>
                        setState(() => _titleController.text = value),
                  ),
                  const SizedBox(height: 8),
                  _buildStarterPresets(),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _specificationController,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        _categorySlug == 'education_training'
                            ? 'Course / Subject / Skill'
                            : l10n.needsSpecificationLabel,
                        guidance.specificationHelper,
                      ),
                      hintText: guidance.specificationHint,
                      helperText: guidance.specificationHelper,
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
                  FormSuggestionStrip(
                    label: 'Previous text',
                    suggestions:
                        _recentValues((request) => request.specification),
                    onSelected: (value) =>
                        setState(() => _specificationController.text = value),
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
                      if (_isTransportLocationPairStart(dynamicFields, field))
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextInputWithHelpers(field),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextInputWithHelpers(
                                dynamicFields[dynamicFields.indexOf(field) + 1],
                              ),
                            ),
                          ],
                        )
                      else if (_isTransportLocationPairEnd(
                          dynamicFields, field))
                        const SizedBox.shrink()
                      else if (field.type == NeedFieldType.boolean)
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOptionPills(field),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                key: ValueKey(
                                  '${field.key}-${_dynamicControllers[field.key]?.text ?? ''}',
                                ),
                                initialValue: _dynamicControllers[field.key]
                                            ?.text
                                            .isEmpty ??
                                        true
                                    ? null
                                    : _dynamicControllers[field.key]?.text,
                                decoration: InputDecoration(
                                  label:
                                      _fieldLabel(field.label, field.guidance),
                                  hintText: field.hint,
                                  helperText: field.helperText,
                                  border: const OutlineInputBorder(),
                                ),
                                items: _optionsForField(field)
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(option),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  _dynamicControllers[field.key]?.text =
                                      value ?? '';
                                },
                                validator: (value) {
                                  if (field.isRequired &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please fill in this requirement';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        _buildTextInputWithHelpers(field),
                    ],
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        _categorySlug == 'education_training'
                            ? 'Maximum Budget ($currency)'
                            : l10n.needsBudgetLabel(currency),
                        l10n.needsBudgetHelper,
                      ),
                      hintText: l10n.needsBudgetHint,
                      helperText: l10n.needsBudgetHelper,
                      suffixIcon: _buildBudgetStepperSuffix(),
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
                  FormSuggestionStrip(
                    label: 'Recent budget',
                    suggestions: _recentValues(
                      (request) =>
                          request.currency == currency && request.budget > 0
                              ? '$currency ${formatter.format(request.budget)}'
                              : '',
                    ),
                    onSelected: (value) => setState(() {
                      _budgetController.text =
                          value.replaceAll(RegExp(r'[^0-9]'), '');
                    }),
                  ),
                  const SizedBox(height: 4),
                  _buildBudgetShortcuts(currency),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey('location-$selectedLocation'),
                    initialValue: selectedLocation,
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        country.regionsLabel,
                        'Choose the area where you need the service or delivery.',
                      ),
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
                        _locationTouched = true;
                        if (_location != 'Other') {
                          _customLocationController.clear();
                        }
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.needsLocationRequired
                        : null,
                  ),
                  FormSuggestionStrip(
                    label: 'Recent',
                    suggestions: _recentValuesAcrossCategories(
                            (request) => request.location)
                        .where(country.regions.contains)
                        .toList(),
                    onSelected: (value) => setState(() {
                      _location = value;
                      _locationTouched = true;
                      _customLocationController.clear();
                    }),
                  ),
                  if (selectedLocation == 'Other') ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _customLocationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        label: _fieldLabel(
                          l10n.needsCustomLocationLabel,
                          l10n.needsCustomLocationHint,
                        ),
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
                    FormSuggestionStrip(
                      label: 'Recent',
                      suggestions: _recentValuesAcrossCategories(
                        (request) => request.location,
                      )
                          .where((value) => !country.regions.contains(value))
                          .toList(),
                      onSelected: (value) => setState(
                        () => _customLocationController.text = value,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey('urgency-$_urgency'),
                    initialValue: _urgency,
                    decoration: InputDecoration(
                      label: _fieldLabel(
                        l10n.needsUrgencyLabel,
                        'Choose when you need providers to respond or complete the work.',
                      ),
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
                  FormSuggestionStrip(
                    label: 'Recent',
                    suggestions: _recentValuesAcrossCategories(
                            (request) => request.urgency)
                        .where(
                          _urgencies.contains,
                        )
                        .toList(),
                    onSelected: (value) => setState(() => _urgency = value),
                  ),
                  const SizedBox(height: 4),
                  FormSuggestionStrip(
                    label: 'Try',
                    suggestions: _urgencies
                        .map((value) => _urgencyLabel(l10n, value))
                        .toList(),
                    onSelected: (value) => setState(() {
                      _urgency = _urgencies.firstWhere(
                        (urgency) => _urgencyLabel(l10n, urgency) == value,
                        orElse: () => _urgencies.last,
                      );
                    }),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PostDurationInfoCard(
                durationDays: _limits.durationForNeedsCategory(_categorySlug),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed:
                        _savingDraft || !_hasDraftContent ? null : _saveDraft,
                    icon: _savingDraft
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save draft'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _submitting || !_isReadyToPublish ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.needsPreviewBtn),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
