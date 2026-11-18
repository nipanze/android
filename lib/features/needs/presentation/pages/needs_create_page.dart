import 'dart:math';

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
import '../../../listings/presentation/widgets/listing_create_widgets.dart';
import '../../../marketplace/domain/models/marketplace_item.dart';
import '../../../settings/data/system_settings_repository.dart';
import '../../data/need_draft_exit_guard.dart';
import '../../data/need_draft_store.dart';
import '../../data/needs_repository.dart';
import '../../domain/models/need_category.dart';
import '../../domain/models/need_form_schema.dart';

const _providerStyleNeedCategoryLabels = <String, String>{
  'technology_digital': 'Technology & Digital',
  'marketing_promotion': 'Marketing & Promotion',
  'professional_services': 'Business & Professional Services',
  'education_training': 'Education & Training',
  'events_production': 'Events & Celebrations',
  'events_celebrations': 'Events & Celebrations',
  'weddings_celebrations': 'Events & Celebrations',
  'photo_video_music_talent': 'Photo, Video, Music & Talent',
  'photo_video_talent': 'Photo, Video & Talent',
  'music_video': 'Music & Video',
  'beauty_fashion_styling': 'Beauty, Fashion, Styling & Wellness',
  'construction_building': 'Construction & Building',
  'energy_utilities': 'Energy & Utilities',
  'transport_logistics': 'Transport & Logistics',
  'machinery_equipment': 'Machinery & Equipment',
  'agriculture_agribusiness': 'Agriculture & Agribusiness',
  'specialized_products': 'Specialized Products & Procurement',
  'travel_international': 'Travel & International',
  'domestic_household': 'Domestic & Household',
  'health_medical': 'Health & Medical',
  'business_investment': 'Business & Investment',
  'financial_services': 'Finance & Investments',
  'property_real_estate': 'Property & Real Estate',
  'traditional_cultural': 'Traditional & Cultural Services',
};

class NeedsCreatePage extends StatefulWidget {
  const NeedsCreatePage({
    super.key,
    this.initialCategorySlug,
    this.initialPresetLabel,
    this.draftId,
  });

  final String? initialCategorySlug;
  final String? initialPresetLabel;
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
  final Map<String, FocusNode> _compactChoiceFocusNodes = {
    'nationality': FocusNode(),
    'purpose': FocusNode(),
    'visa_type': FocusNode(),
    'agri_item': FocusNode(),
    'volume_or_acres': FocusNode(),
    'system_type': FocusNode(),
    'subject_or_skill': FocusNode(),
    'training_level': FocusNode(),
    'preferred_format': FocusNode(),
    'max_travel_distance': FocusNode(),
    'start_date': FocusNode(),
    'duration': FocusNode(),
    'schedule': FocusNode(),
  };

  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, bool> _dynamicBooleans = {};
  final Map<String, int> _presetTapCounts = {};
  List<NeedCategory> _categories = NeedCategory.defaultCategories;
  List<NeedsListing> _recentRequests = const [];
  String? _recentRequestsLoadError;

  String _categorySlug = 'machinery_equipment';
  String _categoryAtOpen = 'machinery_equipment';
  String _urgency = 'Within 30 days';
  String? _location;
  String? _selectedPresetLabel;
  bool _locationTouched = false;
  bool _durationCustomSelected = false;
  final Set<String> _customChoiceFields = {};
  final int _starterPresetSeed = Random().nextInt(1 << 30);
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
    final initialCategorySlug = widget.initialCategorySlug?.trim();
    if (initialCategorySlug != null && initialCategorySlug.isNotEmpty) {
      _categorySlug = initialCategorySlug;
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
    if (widget.initialPresetLabel != null && widget.draftId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final preset = NeedFormSchema.presetForCategory(
          _categorySlug,
          widget.initialPresetLabel!,
        );
        if (preset != null) _applyPreset(preset);
      });
    }
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
      final savedLocation = draft['location']?.toString();
      final customLocation = draft['custom_location']?.toString() ?? '';
      _location = savedLocation == 'Other'
          ? customLocation
          : savedLocation ?? customLocation;
      _customLocationController.text = _location ?? '';
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
            if (field.key == 'duration_days') {
              _durationCustomSelected = !const ['3', '7', '14', '30', '60']
                  .contains(entry.value.toString());
            }
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
        final isExplicitKnownCategory =
            widget.initialCategorySlug?.trim() == _categorySlug &&
                (NeedFormSchema.categoryPresets.containsKey(_categorySlug) ||
                    NeedFormSchema.categoryFields.containsKey(_categorySlug) ||
                    NeedCategory.defaultCategories
                        .any((category) => category.slug == _categorySlug));
        if (!isExplicitKnownCategory) {
          _categorySlug = categories.first.slug;
          _initCategoryControllers();
        }
      }
    });
  }

  void _initCategoryControllers() {
    final fields = NeedFormSchema.fieldsForCategory(_categorySlug);
    for (final field in fields) {
      if (field.type == NeedFieldType.boolean) {
        _dynamicBooleans.putIfAbsent(field.key, () => false);
      } else {
        final controller = _dynamicControllers.putIfAbsent(
          field.key,
          () => TextEditingController()..addListener(_refresh),
        );
        if (field.key == 'travel_scope' && controller.text.isEmpty) {
          controller.text = 'International trip';
        }
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
    for (final focusNode in _compactChoiceFocusNodes.values) {
      focusNode.dispose();
    }
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

  Widget? _clearSuffix(TextEditingController controller, {Widget? trailing}) {
    if (controller.text.isEmpty && trailing == null) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing != null) trailing,
        if (controller.text.isNotEmpty)
          IconButton(
            tooltip: AppLocalizations.of(context)!.clearInput,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: controller.clear,
          ),
      ],
    );
  }

  bool get _specificationIsOptional => true;

  int? _maxVisibleChoiceCount(int count) {
    if (count >= 6 && count <= 8) return 3;
    if (count > 8) return 5;
    return null;
  }

  bool get _titleHasUnfilledPrompt =>
      RegExp(r'\[[^\]]+\]').hasMatch(_titleController.text.trim());

  double _detailsFieldBottomPadding(NeedFormField field) {
    if (_categorySlug == 'specialized_products') {
      return field.key == 'delivery_location' ? 0 : 8;
    }
    if (_categorySlug == 'professional_services') {
      return field.key == 'deliverable' ? 0 : 8;
    }
    if (_categorySlug == 'machinery_equipment' ||
        _categorySlug == 'transport_logistics' ||
        (_categorySlug == 'construction_building' &&
            field.key == 'project_scope')) {
      return 0;
    }
    return 12;
  }

  bool get _isReadyToPublish {
    final title = _titleController.text.trim();
    final specification = _specificationController.text.trim();
    final budget = int.tryParse(_budgetController.text.replaceAll(',', ''));
    final location = _effectiveLocation.trim();

    if (title.length < 4 ||
        _titleHasUnfilledPrompt ||
        (!_specificationIsOptional && specification.length < 12) ||
        budget == null ||
        budget < 0 ||
        location.isEmpty) {
      return false;
    }

    // Verify required category fields
    final fields = NeedFormSchema.fieldsForCategory(_categorySlug);
    for (final f in fields.where((field) => !_isHiddenTravelField(field))) {
      if (_isFieldRequired(f) && f.type != NeedFieldType.boolean) {
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
    if (_categorySlug == 'travel_international') {
      final startingPoint =
          _dynamicControllers['departure_city']?.text.trim() ?? '';
      if (startingPoint.isNotEmpty || !_isLocalTour) return startingPoint;
      return _dynamicControllers['destination_city']?.text.trim() ?? '';
    }
    return _customLocationController.text.trim();
  }

  bool get _isLocalTour =>
      _categorySlug == 'travel_international' &&
      _dynamicControllers['travel_scope']?.text == 'Local tour';

  bool _isHiddenTravelField(NeedFormField field) =>
      _categorySlug == 'travel_international' &&
      (_isLocalTour &&
              const {'destination_country', 'visa_type', 'nationality'}
                  .contains(field.key) ||
          !_isLocalTour && field.key == 'tour_activities');

  bool _isFieldRequired(NeedFormField field) {
    if (_categorySlug == 'travel_international' &&
        field.key == 'departure_city') {
      return !_isLocalTour;
    }
    return field.isRequired;
  }

  List<NeedFormField> get _visibleCategoryFields =>
      NeedFormSchema.fieldsForCategory(_categorySlug)
          .where((field) => !_isHiddenTravelField(field))
          .toList();

  void _setTravelScope(String scope) {
    final controller = _dynamicControllers['travel_scope'];
    if (controller == null) return;
    setState(() {
      controller.text = scope;
      if (scope == 'Local tour') {
        _dynamicControllers['destination_country']?.clear();
        _dynamicControllers['visa_type']?.clear();
        _dynamicControllers['nationality']?.clear();
        _customChoiceFields.removeAll({'visa_type', 'nationality'});
        final purpose = _dynamicControllers['purpose'];
        if (purpose != null && purpose.text.isEmpty) purpose.text = 'Tourism';
      }
    });
  }

  int _budgetValue() {
    return int.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0;
  }

  void _selectCategory(String slug) {
    if (slug == _categorySlug) return;
    setState(() {
      _titleController.clear();
      _specificationController.clear();
      _budgetController.clear();
      _customLocationController.clear();
      _location = null;
      _locationTouched = false;
      _urgency = 'Within 30 days';
      _durationCustomSelected = false;
      _customChoiceFields.clear();
      _selectedPresetLabel = null;
      for (final controller in _dynamicControllers.values) {
        controller.clear();
      }
      _dynamicBooleans.updateAll((_, __) => false);
      _categorySlug = slug;
      _initCategoryControllers();
    });
  }

  Future<void> _openCategoryDrawer() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedSlug = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Material(
            color: theme.colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose Need Category',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 64,
                    ),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category.slug == _categorySlug;
                      return ListTile(
                        leading: Text(
                          category.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          _categoryLocalizedName(l10n, category.slug),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(sheetContext, category.slug),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (selectedSlug != null && mounted) _selectCategory(selectedSlug);
  }

  Future<void> _openUrgencyDrawer() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedUrgency = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Material(
          color: theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Response urgency',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(sheetContext)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var index = 0; index < _urgencies.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 64, endIndent: 16),
                Builder(
                  builder: (context) {
                    final urgency = _urgencies[index];
                    final isSelected = urgency == _urgency;
                    return ListTile(
                      leading: Icon(
                        urgency == 'Urgent'
                            ? Icons.priority_high_rounded
                            : Icons.schedule_rounded,
                        color: urgency == 'Urgent'
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      title: Text(
                        _urgencyLabel(l10n, urgency),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(sheetContext, urgency),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
    if (selectedUrgency != null && mounted) {
      setState(() => _urgency = selectedUrgency);
    }
  }

  void _applyPreset(NeedFormPreset preset) {
    setState(() {
      final presetKey = '$_categorySlug:${preset.label}';
      final tapCount = _presetTapCounts[presetKey] ?? 0;
      _presetTapCounts[presetKey] = tapCount + 1;
      _selectedPresetLabel = preset.label;
      _titleController.text = _presetTitleVariant(preset.title, tapCount);
      _specificationController.text = _presetSpecificationVariant(
        preset,
        tapCount,
      );
      _durationCustomSelected = false;
      _customChoiceFields.clear();
      for (final field in NeedFormSchema.fieldsForCategory(_categorySlug)) {
        if (field.type == NeedFieldType.boolean) {
          _dynamicBooleans[field.key] = false;
        } else {
          _dynamicControllers[field.key]?.clear();
        }
      }
      if (_categorySlug == 'travel_international') {
        _dynamicControllers['travel_scope']?.text = 'International trip';
      }
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

  String _presetSpecificationVariant(NeedFormPreset preset, int tapCount) {
    if (tapCount == 0 || preset.specificationVariants.isEmpty) {
      return preset.specification;
    }
    return preset.specificationVariants[
        (tapCount - 1) % preset.specificationVariants.length];
  }

  String _presetTitleVariant(String title, int tapCount) {
    late final String firstAlternative;
    late final String secondAlternative;
    late final String thirdAlternative;
    if (title.startsWith('Our school needs ')) {
      final request = title.substring('Our school needs '.length);
      firstAlternative = 'Our school wants $request';
      secondAlternative = 'We are looking for $request';
      thirdAlternative = 'Our school is looking for $request';
    } else if (title.startsWith('Our institution needs ')) {
      final request = title.substring('Our institution needs '.length);
      firstAlternative = 'Our institution wants $request';
      secondAlternative = 'We are looking for $request';
      thirdAlternative = 'Our institution is looking for $request';
    } else if (title.startsWith('Our clinic needs one ')) {
      final role = title.substring('Our clinic needs one '.length);
      firstAlternative = 'Our clinic is looking for one $role';
      secondAlternative = 'We need one $role at our clinic';
      thirdAlternative = 'Seeking one $role for our clinic';
    } else if (title.startsWith('I am looking for ')) {
      final request = title.substring('I am looking for '.length);
      firstAlternative = 'I need $request';
      secondAlternative = 'I am seeking $request';
      thirdAlternative = 'Looking for $request';
    } else if (title.startsWith('I am seeking ')) {
      final request = title.substring('I am seeking '.length);
      firstAlternative = 'I am looking for $request';
      secondAlternative = 'I need $request';
      thirdAlternative = 'Seeking $request';
    } else if (title.startsWith('I need to ')) {
      final request = title.substring('I need to '.length);
      firstAlternative = 'I want to $request';
      secondAlternative = 'Looking to $request';
      thirdAlternative = 'Need to $request';
    } else if (title.startsWith('I need ')) {
      final request = title.substring('I need '.length);
      firstAlternative = 'I want $request';
      secondAlternative = 'Looking for $request';
      thirdAlternative = 'Need $request';
    } else if (title.startsWith('I want to ')) {
      final request = title.substring('I want to '.length);
      firstAlternative = 'I need to $request';
      secondAlternative = 'Looking to $request';
      thirdAlternative = 'Need to $request';
    } else if (title.startsWith('I want ')) {
      final request = title.substring('I want '.length);
      firstAlternative = 'I need $request';
      secondAlternative = 'Looking for $request';
      thirdAlternative = 'Need $request';
    } else if (title.startsWith('Looking for ')) {
      final request = title.substring('Looking for '.length);
      firstAlternative = 'I need $request';
      secondAlternative = 'I want $request';
      thirdAlternative = 'Need $request';
    } else if (title.startsWith('Looking to ')) {
      final request = title.substring('Looking to '.length);
      firstAlternative = 'I want to $request';
      secondAlternative = 'I need to $request';
      thirdAlternative = 'Need to $request';
    } else if (title.startsWith('Need to ')) {
      final request = title.substring('Need to '.length);
      firstAlternative = 'I need to $request';
      secondAlternative = 'I want to $request';
      thirdAlternative = 'Looking to $request';
    } else if (title.startsWith('Need ')) {
      final request = title.substring('Need '.length);
      firstAlternative = 'I need $request';
      secondAlternative = 'I want $request';
      thirdAlternative = 'Looking for $request';
    } else if (title.startsWith('Planning to ')) {
      final request = title.substring('Planning to '.length);
      firstAlternative = 'I want to $request';
      secondAlternative = 'I need to $request';
      thirdAlternative = 'Looking to $request';
    } else if (title.startsWith('Planning a ')) {
      final request = title.substring('Planning a '.length);
      firstAlternative = 'I want to plan a $request';
      secondAlternative = 'Looking to plan a $request';
      thirdAlternative = 'I need help planning a $request';
    } else if (title.startsWith('Planning ')) {
      final request = title.substring('Planning '.length);
      firstAlternative = 'I want to plan $request';
      secondAlternative = 'Looking to plan $request';
      thirdAlternative = 'I need help planning $request';
    } else if (title.startsWith('Find ')) {
      final request = title.substring('Find '.length);
      firstAlternative = 'I need $request';
      secondAlternative = 'I want $request';
      thirdAlternative = 'Looking for $request';
    } else {
      return title;
    }

    return [
      title,
      firstAlternative,
      secondAlternative,
      thirdAlternative
    ][tapCount % 4];
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
      _customChoiceFields.clear();
      _selectedPresetLabel = null;
      if (_categorySlug == 'travel_international') {
        _dynamicControllers['travel_scope']?.text = 'International trip';
      }
      _titleController.text = request.title;
      _specificationController.text = request.specification;
      if (request.currency == _currency(context.read<AuthBloc>().state)) {
        _budgetController.text = request.budget.toString();
      }
      _urgency = _urgencies.contains(request.urgency)
          ? request.urgency
          : _urgencies.last;
      _location = request.location;
      _customLocationController.text = request.location;
      _locationTouched = true;
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
    final l10n = AppLocalizations.of(context)!;
    final recentSuggestions =
        recentRequests.take(2).map((request) => 'Repeat: ${request.title}');
    final presetOffset =
        presets.isEmpty ? 0 : _starterPresetSeed % presets.length;
    final rotatedPresets = [
      ...presets.skip(presetOffset),
      ...presets.take(presetOffset),
    ];
    final allSuggestions = [
      if (_categorySlug == 'financial_services') 'Loans',
      if (_categorySlug == 'financial_services') 'Forex',
      if (_categorySlug == 'travel_international')
        ...presets
            .where((preset) => preset.label == 'Guided tour')
            .map((preset) => preset.label),
      ...rotatedPresets
          .where((preset) =>
              _categorySlug != 'travel_international' ||
              preset.label != 'Guided tour')
          .map((preset) => preset.label),
      ...recentSuggestions,
    ];
    final moreDescriptions = {
      if (_categorySlug == 'financial_services')
        'Loans': 'Open the standalone loan request flow.',
      if (_categorySlug == 'financial_services')
        'Forex': 'Open the standalone currency exchange flow.',
      for (final preset in presets) preset.label: preset.specification,
      for (final request in recentRequests.take(2))
        'Repeat: ${request.title}': 'Reuse your previous request and edit it.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSuggestionStrip(
          label: 'Start with',
          suggestions: allSuggestions,
          moreLabel: l10n.showMore,
          maxVisibleChoices: 4,
          selectedValue: _selectedPresetLabel,
          moreSubtitle: 'Choose a starting point. You can edit it next.',
          moreDescriptions: moreDescriptions,
          onSelected: (value) {
            if (_categorySlug == 'financial_services' && value == 'Loans') {
              context.go(AppRoutes.listingCreate);
              return;
            }
            if (_categorySlug == 'financial_services' && value == 'Forex') {
              context.go(AppRoutes.forexCreate);
              return;
            }
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

  Widget _sectionCard({
    required String title,
    required bool isComplete,
    required Widget child,
  }) {
    return ListingFormPanel(
      title: title,
      isComplete: isComplete,
      children: [child],
    );
  }

  InputDecoration _detailsInputDecoration({
    Widget? label,
    String? hintText,
    String? helperText,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);
    final fill = theme.brightness == Brightness.dark
        ? AppColors.bg3Dark
        : AppColors.bg3Light;
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      label: label,
      hintText: hintText,
      helperText: helperText,
      helperMaxLines: 2,
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: theme.inputDecorationTheme.hintStyle
          ?.copyWith(fontWeight: FontWeight.w400),
      helperStyle: theme.inputDecorationTheme.helperStyle
          ?.copyWith(fontWeight: FontWeight.w400),
    );
  }

  Widget _buildOptionPills(NeedFormField field, {String label = 'Options'}) {
    final selected = _dynamicControllers[field.key]?.text.trim();
    return FormSuggestionStrip(
      label: label,
      topPadding: 0,
      suggestions: _optionsForField(field),
      maxVisibleChoices: _maxVisibleChoiceCount(_optionsForField(field).length),
      selectedValue: selected?.isEmpty == true ? null : selected,
      onSelected: (value) => _setFieldValue(field, value),
    );
  }

  Widget _buildTravelScopePicker() {
    return FormSuggestionStrip(
      label: 'Trip type',
      topPadding: 0,
      suggestions: const ['International trip', 'Local tour'],
      selectedValue: _dynamicControllers['travel_scope']?.text,
      onSelected: _setTravelScope,
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
      label: 'Budget shortcuts',
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
      'destination_city' => const [
          'Murchison Falls',
          'Queen Elizabeth National Park',
          'Jinja',
          'Sipi Falls',
          'Bwindi Impenetrable Forest',
          'Lake Bunyonyi',
          'Kampala city tour',
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
          'Tourism',
          'Business',
          'Study',
          'Family visit',
          'Hajj',
          'Umrah',
          'Medical',
        ],
      'visa_type' => const [
          'Tourist visa',
          'Business visa',
          'Transit visa',
          'Student visa',
          'Hajj visa',
          'Umrah visa',
        ],
      'travel_date' || 'return_date' || 'event_date' || 'shoot_date' => const [
          'As soon as possible',
          'This month',
          'Next month',
          'December 2026',
          'Flexible',
        ],
      'duration_days' => const ['3', '7', '14', '30', '60'],
      'duration' when category == 'education_training' => const [
          '2 months',
          '6 months',
          '1 year',
          'Flexible',
        ],
      'duration' => const ['2 weeks', '8 weeks', '3 months', '6 months'],
      'schedule' => const ['Full-time', 'Part-time', 'Weekends', 'Flexible'],
      'start_date' when category == 'education_training' => const [
          'As soon as possible',
          'Next month',
          'Flexible',
        ],
      'start_date' => const [
          'As soon as possible',
          'Next week',
          'Next month',
          'Flexible',
        ],
      'training_level' => const [
          'Kindergarten / Early childhood',
          'Primary school',
          'Secondary school',
          'Tertiary / University',
          'Vocational / Technical',
        ],
      'subject_or_skill' => const [
          'Mathematics',
          'English',
          'Science',
          'Languages',
          'Computer studies',
          'Coding',
          'Accounting',
          'Business studies',
          'Academic writing',
          'Vocational skill',
        ],
      'preferred_format' => const [
          'Online',
          'In-person',
          'Either',
        ],
      'max_travel_distance' => const [
          '2 km',
          '5 km',
          '10 km',
          '20 km',
          'Anywhere',
        ],
      'preferred_location' => const [
          'Near campus',
          'At home',
          'Provider location',
          'Flexible',
        ],
      'timeline'
          when category == 'technology_digital' ||
              category == 'marketing_promotion' =>
        const [
          '2 weeks',
          '4 weeks',
          '8 weeks',
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
      'celebration_type' => const [
          'Wedding, 150 guests',
          'Introduction ceremony',
          'Birthday, 50 guests',
          'Graduation party',
        ],
      'venue_location' ||
      'location' ||
      'site_location' ||
      'delivery_location' ||
      'from_location' ||
      'to_location' =>
        CountryLocations.localitiesFor(
          _countryInfo(context.read<AuthBloc>().state),
        ),
      'service_type' => const [
          'Accounting',
          'Legal support',
          'Tax filing',
          'Business registration',
          'Business consulting',
          'HR services',
          'Engineering consulting',
          'Architecture',
          'Business administration',
          'Project management',
        ],
      'project_type' => const ['Roofing', 'Plumbing', 'Electrical', 'Painting'],
      'agri_item' => const [
          'Soil testing',
          'Veterinary care',
          'Farm labour',
          'Seeds / fertilizer / chemicals',
          'Combine harvester hire',
          'Irrigation equipment',
          'Livestock feed',
          'Crop spraying / pest control',
          'Tractor / farm implement hire',
          'Buyer for farm produce',
          'Wholesale produce buyer',
          'Institutional produce supply',
          'Farmland lease',
          'Agriculture tours and expos',
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

  bool _isLocationField(NeedFormField field) {
    final key = field.key.toLowerCase();
    return key.contains('location') || key.contains('city');
  }

  bool _isCompactChoiceField(NeedFormField field) {
    if (_categorySlug == 'travel_international') {
      return const {'nationality', 'purpose', 'visa_type'}.contains(field.key);
    }
    return _categorySlug == 'agriculture_agribusiness' &&
            const {'agri_item', 'volume_or_acres'}.contains(field.key) ||
        (_categorySlug == 'energy_utilities' && field.key == 'system_type') ||
        ((_categorySlug == 'technology_digital' ||
                _categorySlug == 'marketing_promotion') &&
            field.key == 'timeline') ||
        (_categorySlug == 'education_training' &&
            const {
              'subject_or_skill',
              'training_level',
              'preferred_format',
              'max_travel_distance',
              'start_date',
              'duration',
              'schedule',
            }.contains(field.key));
  }

  Widget _buildFieldQuickValues(NeedFormField field) {
    if (_isCompactChoiceField(field)) {
      final values = field.key == 'nationality'
          ? CountryLocations.nationalitiesFor(
              _countryInfo(context.read<AuthBloc>().state),
            ).take(3).toList()
          : _quickValuesForField(field);
      final localizedNationalities =
          _localizedNationalities(AppLocalizations.of(context)!);
      final localizedValues = values
          .map((value) => field.key == 'nationality'
              ? localizedNationalities[value] ?? value
              : value)
          .toList();
      final currentValue = _dynamicControllers[field.key]?.text.trim() ?? '';
      final selectedValue = values.contains(currentValue)
          ? field.key == 'nationality'
              ? localizedNationalities[currentValue] ?? currentValue
              : currentValue
          : null;
      final maxVisibleChoices = _maxVisibleChoiceCount(values.length);

      return FormSuggestionStrip(
        label: field.label,
        suggestions: [
          ...localizedValues,
          'Custom',
        ],
        maxVisibleChoices: maxVisibleChoices,
        pinnedChoices: const {'Custom'},
        topPadding: 0,
        selectedValue:
            _customChoiceFields.contains(field.key) ? 'Custom' : selectedValue,
        onSelected: (value) {
          if (value == 'Custom') {
            final controller = _dynamicControllers[field.key]!;
            if (values.contains(controller.text.trim())) {
              controller.clear();
            }
            setState(() => _customChoiceFields.add(field.key));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _compactChoiceFocusNodes[field.key]?.requestFocus();
              }
            });
          } else {
            final selectedIndex = localizedValues.indexOf(value);
            final storedValue =
                selectedIndex >= 0 ? values[selectedIndex] : null;
            if (storedValue == null) return;
            setState(() {
              _customChoiceFields.remove(field.key);
              _dynamicControllers[field.key]?.text = storedValue;
            });
          }
        },
      );
    }
    if (_categorySlug == 'travel_international' &&
        const {
          'destination_country',
          'travel_date',
          'return_date',
          'travellers',
        }.contains(field.key)) {
      return const SizedBox.shrink();
    }
    final presets = NeedFormSchema.presetsForCategory(_categorySlug);
    final presetLabels =
        presets.map((preset) => preset.label.trim().toLowerCase()).toSet();
    final presetValues = presets
        .map((preset) => preset.details[field.key]?.trim().toLowerCase())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    final values = _suggestionsForField(field).where((value) {
      final normalized = value.trim().toLowerCase();
      return !presetLabels.contains(normalized) &&
          !presetValues.contains(normalized);
    }).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final localizedNationalities = field.key == 'nationality'
        ? _localizedNationalities(AppLocalizations.of(context)!)
        : const <String, String>{};
    final currentValue = _dynamicControllers[field.key]?.text.trim() ?? '';
    final localizedCurrentValue = localizedNationalities[currentValue] ??
        (currentValue.isEmpty ? null : currentValue);
    return FormSuggestionStrip(
      label: field.label,
      suggestions: values
          .map((value) => localizedNationalities[value] ?? value)
          .toList(),
      maxVisibleChoices: _maxVisibleChoiceCount(values.length),
      selectedValue: localizedCurrentValue,
      onSelected: (value) {
        final source = localizedNationalities.entries
            .where((entry) => entry.value == value)
            .map((entry) => entry.key)
            .firstOrNull;
        _setFieldValue(field, source ?? value);
      },
    );
  }

  Widget _buildCompactChoiceField(NeedFormField field) {
    final commonValues = field.key == 'nationality'
        ? CountryLocations.nationalitiesFor(
            _countryInfo(context.read<AuthBloc>().state),
          ).take(3).toSet()
        : _quickValuesForField(field).toSet();
    final currentValue = _dynamicControllers[field.key]?.text.trim() ?? '';
    final showInput = _customChoiceFields.contains(field.key) ||
        (currentValue.isNotEmpty && !commonValues.contains(currentValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldQuickValues(field),
        if (showInput) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _dynamicControllers[field.key],
            focusNode: _compactChoiceFocusNodes[field.key],
            textCapitalization: TextCapitalization.words,
            decoration: _detailsInputDecoration(
              label: const Text('Custom value'),
              hintText: 'Type your own option',
              suffixIcon: _clearSuffix(_dynamicControllers[field.key]!),
            ),
            validator: (value) {
              if (field.isRequired && (value == null || value.trim().isEmpty)) {
                return 'Please fill in this requirement';
              }
              return null;
            },
          ),
        ],
        if (!showInput && field.helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              field.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
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

  Widget _buildTextInputWithHelpers(
    NeedFormField field, {
    double bottomPadding = 12,
    String? helperTextOverride,
  }) {
    final controller = _dynamicControllers[field.key]!;
    final isDatePicker = field.type == NeedFieldType.date;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            focusNode: _compactChoiceFocusNodes[field.key],
            readOnly: isDatePicker,
            onTap: isDatePicker ? () => _pickDateForField(field) : null,
            keyboardType: field.type == NeedFieldType.number
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters: field.type == NeedFieldType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: _detailsInputDecoration(
              label: _fieldLabel(field.label, field.guidance),
              hintText: field.hint,
              helperText: helperTextOverride ?? field.helperText,
              suffixIcon: _clearSuffix(
                controller,
                trailing: isDatePicker
                    ? const Icon(Icons.calendar_today_outlined, size: 18)
                    : field.type == NeedFieldType.number
                        ? _buildStepperSuffix(field)
                        : null,
              ),
            ),
            validator: (val) {
              if (_isFieldRequired(field) &&
                  (val == null || val.trim().isEmpty)) {
                return 'Please fill in this requirement';
              }
              return null;
            },
          ),
          if (!_isLocationField(field)) _buildFieldQuickValues(field),
        ],
      ),
    );
  }

  Future<void> _pickDateForField(NeedFormField field) async {
    final controller = _dynamicControllers[field.key]!;
    final locale = Localizations.localeOf(context).toString();
    DateTime? initialDate;
    try {
      initialDate = DateFormat.yMMMd(locale).parseStrict(controller.text);
    } catch (_) {
      initialDate = DateTime.tryParse(controller.text);
    }
    final today = DateTime.now();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 15),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 12,
            shadowColor: colors.shadow.withValues(alpha: 0.18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(color: colors.outlineVariant),
            ),
            headerBackgroundColor: colors.primary.withValues(alpha: 0.10),
            headerForegroundColor: colors.onSurface,
            headerHeadlineStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            headerHelpStyle: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            weekdayStyle: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            dayStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return colors.onPrimary;
              if (states.contains(WidgetState.disabled)) {
                return colors.onSurface.withValues(alpha: 0.38);
              }
              return colors.onSurface;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return colors.primary;
              if (states.contains(WidgetState.hovered)) {
                return colors.primary.withValues(alpha: 0.10);
              }
              return null;
            }),
            todayForegroundColor: WidgetStatePropertyAll(colors.primary),
            todayBackgroundColor:
                WidgetStatePropertyAll(colors.primary.withValues(alpha: 0.08)),
            dividerColor: colors.outlineVariant,
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            confirmButtonStyle: FilledButton.styleFrom(
              foregroundColor: colors.onPrimary,
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    controller.text = DateFormat.yMMMd(locale).format(picked);
  }

  Widget _buildNeedDuration(NeedFormField field) {
    const durations = ['3', '7', '14', '30', '60'];
    final controller = _dynamicControllers[field.key]!;
    final selected =
        durations.contains(controller.text) ? controller.text : null;
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSuggestionStrip(
            label: 'How long do you need it?',
            topPadding: 0,
            suggestions: [
              ...durations.map((value) => '$value days'),
              'Custom',
            ],
            selectedValue: _durationCustomSelected
                ? 'Custom'
                : selected == null
                    ? null
                    : '$selected days',
            onSelected: (value) {
              setState(() {
                if (value == 'Custom') {
                  if (!_durationCustomSelected) controller.clear();
                  _durationCustomSelected = true;
                } else {
                  controller.text = value.split(' ').first;
                  _durationCustomSelected = false;
                }
              });
            },
          ),
          Visibility(
            visible: _durationCustomSelected,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Number of days',
                  suffixText: 'days',
                  suffixIcon: _clearSuffix(controller),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                validator: (value) =>
                    field.isRequired && (value == null || value.trim().isEmpty)
                        ? 'Please enter the number of days'
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanNeedField(NeedFormField field) {
    final theme = Theme.of(context);
    final isOperator = field.key == 'operator_needed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOperator ? 'I need a machine operator' : field.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOperator || field.helperText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      isOperator
                          ? 'Turn on if the machine needs a driver or operator.'
                          : field.helperText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: _dynamicBooleans[field.key] ?? false,
              onChanged: (value) => setState(() {
                _dynamicBooleans[field.key] = value;
              }),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTransportLocationPairAt(List<NeedFormField> fields, int index) {
    return _categorySlug == 'transport_logistics' &&
        index + 1 < fields.length &&
        fields[index].key == 'from_location' &&
        fields[index + 1].key == 'to_location';
  }

  bool _isTravelDatePairAt(List<NeedFormField> fields, int index) {
    return _categorySlug == 'travel_international' &&
        index + 1 < fields.length &&
        fields[index].key == 'travel_date' &&
        fields[index + 1].key == 'return_date';
  }

  bool _isTravelDatePairStart(
    List<NeedFormField> fields,
    NeedFormField field,
  ) =>
      _isTravelDatePairAt(fields, fields.indexOf(field));

  bool _isTravelDatePairEnd(
    List<NeedFormField> fields,
    NeedFormField field,
  ) {
    final index = fields.indexOf(field);
    return index > 0 && _isTravelDatePairAt(fields, index - 1);
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
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode.toLowerCase() == 'en') {
      final providerStyleName = _providerStyleNeedCategoryLabels[slug];
      if (providerStyleName != null) return providerStyleName;
    }
    final defaultCategory = NeedCategory.findBySlug(slug);
    if (localeCode.toLowerCase() == 'en' && defaultCategory.name != slug) {
      return defaultCategory.name;
    }
    final category = _categories.firstWhere(
      (item) => item.slug == slug,
      orElse: () => NeedCategory.findBySlug(slug),
    );
    final localizedName = category.localizedName(localeCode);
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
    final fields = _visibleCategoryFields;
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

    final dynamicFields = _visibleCategoryFields;
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
                l10n.needsSpecificationLabel,
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
                _categorySlug == 'travel_international'
                    ? _isLocalTour
                        ? 'Tour starting point'
                        : 'Departure city'
                    : 'Location',
                _effectiveLocation.trim(),
              ),
              _previewRow(
                'Response urgency',
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
      final requestId = await getIt<NeedsRepository>().createRequest(
        title: _titleController.text,
        specification: _specificationController.text,
        categorySlug: _categorySlug,
        categoryName: _categoryLocalizedName(l10n, _categorySlug),
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
          'location': _effectiveLocation,
          'custom_location': '',
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

    final currency = _currency(authState);
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
    final isTravelCategory = _categorySlug == 'travel_international';
    final categoryDescription =
        selectedCategory.descriptionForCountry(countryCode)?.trim();
    final categoryFields = NeedFormSchema.fieldsForCategory(_categorySlug);
    final durationField = categoryFields
        .where((field) => field.key == 'duration_days')
        .firstOrNull;
    final dynamicFields = categoryFields
        .where((field) =>
            field.key != 'duration_days' &&
            field.key != 'travel_scope' &&
            !_isHiddenTravelField(field) &&
            !(_categorySlug == 'machinery_equipment' &&
                field.type == NeedFieldType.boolean))
        .toList();

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  _sectionCard(
                    title: 'The basics',
                    isComplete: _titleController.text.trim().length >= 4 &&
                        !_titleHasUnfilledPrompt,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openCategoryDrawer,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              label: _fieldLabel(
                                l10n.needsCategoryLabel,
                                categoryDescription != null &&
                                        categoryDescription.isNotEmpty
                                    ? categoryDescription
                                    : guidance.specificationHelper,
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.expand_more_rounded),
                            ),
                            child: Row(
                              children: [
                                Text(selectedCategory.icon,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _categoryLocalizedName(l10n, _categorySlug),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            helperText: _titleHasUnfilledPrompt
                                ? l10n.needsTitleReplacePrompt
                                : null,
                            helperStyle: _titleHasUnfilledPrompt
                                ? theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  )
                                : null,
                            suffixIcon: _clearSuffix(_titleController),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty)
                              return l10n.validationTitleRequired;
                            if (text.length < 4)
                              return l10n.validationTitleMinLength;
                            if (_titleHasUnfilledPrompt) {
                              return l10n.needsTitleReplacePrompt;
                            }
                            return null;
                          },
                        ),
                        FormSuggestionStrip(
                          label: 'Recent',
                          suggestions:
                              _recentValues((request) => request.title),
                          onSelected: (value) =>
                              setState(() => _titleController.text = value),
                        ),
                        const SizedBox(height: 8),
                        _buildStarterPresets(),
                      ],
                    ),
                  ),
                  if (durationField != null) ...[
                    const SizedBox(height: 10),
                    _sectionCard(
                      title: 'The numbers',
                      isComplete: _dynamicControllers[durationField.key]
                              ?.text
                              .trim()
                              .isNotEmpty ==
                          true,
                      child: _buildNeedDuration(durationField),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _sectionCard(
                    title: 'Details',
                    isComplete: _specificationIsOptional ||
                        _specificationController.text.trim().length >= 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTravelCategory) ...[
                          _buildTravelScopePicker(),
                          const SizedBox(height: 10),
                        ],
                        if (_categorySlug == 'machinery_equipment') ...[
                          for (final field in categoryFields)
                            if (field.type == NeedFieldType.boolean)
                              _buildBooleanNeedField(field),
                        ],
                        if (dynamicFields.isNotEmpty) ...[
                          if (_categorySlug == 'machinery_equipment')
                            const SizedBox(height: 12),
                          for (final field in dynamicFields) ...[
                            if (_isTravelDatePairStart(dynamicFields, field))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTextInputWithHelpers(
                                        field,
                                        bottomPadding: 0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextInputWithHelpers(
                                        dynamicFields[
                                            dynamicFields.indexOf(field) + 1],
                                        bottomPadding: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_isTravelDatePairEnd(dynamicFields, field))
                              const SizedBox.shrink()
                            else if (_isCompactChoiceField(field))
                              _buildCompactChoiceField(field)
                            else if (_isTransportLocationPairStart(
                                dynamicFields, field))
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildTextInputWithHelpers(field),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextInputWithHelpers(
                                      dynamicFields[
                                          dynamicFields.indexOf(field) + 1],
                                    ),
                                  ),
                                ],
                              )
                            else if (_isTransportLocationPairEnd(
                                dynamicFields, field))
                              const SizedBox.shrink()
                            else if (field.type == NeedFieldType.boolean)
                              _buildBooleanNeedField(field)
                            else if (field.key == 'property_contact_preference')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOptionPills(
                                  field,
                                  label: field.label,
                                ),
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
                                      initialValue:
                                          _dynamicControllers[field.key]
                                                      ?.text
                                                      .isEmpty ??
                                                  true
                                              ? null
                                              : _dynamicControllers[field.key]
                                                  ?.text,
                                      decoration: _detailsInputDecoration(
                                        label: _fieldLabel(
                                            field.label, field.guidance),
                                        hintText: field.hint,
                                        helperText: field.helperText,
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
                            else if (field.key == 'duration_days')
                              _buildNeedDuration(field)
                            else
                              _buildTextInputWithHelpers(
                                field,
                                bottomPadding:
                                    _detailsFieldBottomPadding(field),
                                helperTextOverride: field.key ==
                                        'departure_city'
                                    ? _isLocalTour
                                        ? 'Optional pickup or starting point.'
                                        : 'Used to plan your departure route.'
                                    : null,
                              ),
                          ],
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Specification (optional)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _specificationController,
                          minLines: 3,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _detailsInputDecoration(
                            hintText: guidance.specificationHint,
                            helperText: guidance.specificationHelper,
                            suffixIcon: _clearSuffix(_specificationController),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (_specificationIsOptional) {
                              return null;
                            }
                            if (text.isEmpty) {
                              return l10n.needsSpecificationRequired;
                            }
                            if (text.length < 12) {
                              return l10n.needsSpecificationMinLength;
                            }
                            return null;
                          },
                        ),
                        if (_categorySlug != 'machinery_equipment' &&
                            _categorySlug != 'agriculture_agribusiness' &&
                            _categorySlug != 'energy_utilities' &&
                            _categorySlug != 'transport_logistics' &&
                            _categorySlug != 'construction_building' &&
                            _categorySlug != 'professional_services' &&
                            _categorySlug != 'technology_digital' &&
                            _categorySlug != 'marketing_promotion' &&
                            _categorySlug != 'education_training')
                          FormSuggestionStrip(
                            label: 'Previous text',
                            suggestions: _recentValues(
                                (request) => request.specification),
                            onSelected: (value) => setState(
                                () => _specificationController.text = value),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    title: 'Budget and location',
                    isComplete:
                        _budgetValue() > 0 && _effectiveLocation.isNotEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            label: _fieldLabel(
                              _categorySlug == 'education_training'
                                  ? 'Maximum Budget ($currency)'
                                  : l10n.needsBudgetLabel(currency),
                              l10n.needsBudgetHelper,
                            ),
                            hintText: l10n.needsBudgetHint,
                            helperText: l10n.needsBudgetHelper,
                            suffixIcon: _clearSuffix(
                              _budgetController,
                              trailing: _buildBudgetStepperSuffix(),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty)
                              return l10n.validationAmountRequired;
                            final amount =
                                int.tryParse(text.replaceAll(',', ''));
                            if (amount == null || amount < 0) {
                              return l10n.validationValidNumber;
                            }
                            return null;
                          },
                        ),
                        FormSuggestionStrip(
                          label: 'Recent budget',
                          suggestions: _recentValues(
                            (request) => request.currency == currency &&
                                    request.budget > 0
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
                        if (!isTravelCategory) ...[
                          TextFormField(
                            controller: _customLocationController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Town or neighborhood',
                              helperText:
                                  'Enter a town, neighborhood, or specific area.',
                              suffixIcon: _clearSuffix(
                                _customLocationController,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) => setState(() {
                              _location = value;
                              _locationTouched = true;
                            }),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? l10n.needsLocationRequired
                                : null,
                          ),
                        ],
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openUrgencyDrawer,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              label: _fieldLabel(
                                'Response urgency',
                                'How soon should providers contact you?',
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.expand_more_rounded),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _urgencyLabel(l10n, _urgency),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
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
