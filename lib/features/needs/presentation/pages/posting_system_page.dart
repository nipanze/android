import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../provider/domain/repositories/provider_repository_interface.dart';
import '../../data/need_draft_exit_guard.dart';
import '../../data/need_draft_store.dart';
import '../../data/needs_repository.dart';
import '../../domain/models/need_category.dart';
import '../../domain/models/need_form_schema.dart';

/// Prompt-led entry point for the request posting flow. Driving Permit is the
/// first fully wired prompt; other cards remain visible as the catalog grows.
class PostingSystemPage extends StatefulWidget {
  const PostingSystemPage({super.key, this.draftId});

  final String? draftId;

  @override
  State<PostingSystemPage> createState() => _PostingSystemPageState();
}

class _PostingSystemPageState extends State<PostingSystemPage> {
  late final List<_PostingPrompt> _popularPrompts;
  Timer? _searchHintTimer;
  int _searchHintOffset = 0;
  final _search = TextEditingController();
  final _pickerScroll = ScrollController();
  final _budget = TextEditingController();
  final _details = TextEditingController();
  final _customLocation = TextEditingController();
  String? _need;
  String? _where;
  String? _when;
  int _step = 0;
  bool _busy = false;
  bool _showAllDrafts = false;
  bool _showAllSearchResults = false;
  String? _requestId;
  List<Map<String, dynamic>> _drafts = const [];
  bool _allowExit = false;
  bool _locationSelected = false;
  String? _draftId;
  bool _providerFeatureEnabled = false;
  bool _providerLimitReached = false;
  int _providerMaxCapabilities = 30;
  bool _modalOpen = false;
  bool _edgeButtonTucked = false;
  Timer? _scrollIdleTimer;
  double _lastPickerOffset = 0;
  List<NeedCategory> _needCategories = const [];

  @override
  void initState() {
    super.initState();
    final rotatingPrompts = _prompts.skip(6).toList()..shuffle(Random());
    _popularPrompts = [
      ..._prompts.take(6),
      ...rotatingPrompts.take(4),
    ]..shuffle(Random());
    _searchHintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _search.text.isNotEmpty) return;
      setState(() => _searchHintOffset++);
    });
    _draftId = widget.draftId;
    _pickerScroll.addListener(_onPickerScroll);
    _budget.addListener(_refresh);
    _loadNeedCategories();
    _loadProviderButtonState();
    _loadDrafts();
    NeedDraftExitGuard.register(
      this,
      hasChanges: () => _hasDraftContent,
      saveDraft: _savePromptDraft,
    );
    if (widget.draftId != null) _loadPromptDraft();
  }

  Future<void> _loadProviderButtonState() async {
    try {
      final auth = context.read<AuthBloc>().state;
      final country = auth is AuthAuthenticated ? auth.user.country : null;
      final providerRepository = getIt<IProviderRepository>();
      if (!await providerRepository.capabilityProfilesEnabled()) return;
      if (!mounted) return;
      setState(() => _providerFeatureEnabled = true);
      final capabilities = await providerRepository.getProviderCapabilities();
      final settings = await supabase.Supabase.instance.client
          .from('system_settings')
          .select('country, setting_value')
          .eq('setting_key', 'max_provider_capabilities')
          .eq('is_public', true);
      final settingRows = (settings as List).whereType<Map>();
      final selectedSetting = settingRows.firstWhere(
        (row) => row['country']?.toString() == country,
        orElse: () => settingRows.firstWhere(
          (row) => row['country'] == null,
          orElse: () => const {},
        ),
      );
      final maxCapabilities =
          int.tryParse(selectedSetting['setting_value']?.toString() ?? '') ??
              30;
      if (!mounted) return;
      setState(() {
        _providerMaxCapabilities = maxCapabilities;
        _providerLimitReached = capabilities.length >= maxCapabilities;
      });
    } catch (_) {
      // Capability features remain unavailable when the flag cannot be read.
    }
  }

  void _onPickerScroll() {
    if (!_pickerScroll.hasClients) return;
    final offset = _pickerScroll.offset;
    if (offset > _lastPickerOffset + 3) {
      _lastPickerOffset = offset;
      _scrollIdleTimer?.cancel();
      if (!_edgeButtonTucked) setState(() => _edgeButtonTucked = true);
      _scrollIdleTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _edgeButtonTucked = false);
      });
    } else if (offset < _lastPickerOffset - 3) {
      _lastPickerOffset = offset;
      _scrollIdleTimer?.cancel();
      if (_edgeButtonTucked) setState(() => _edgeButtonTucked = false);
    }
  }

  void _openProviderServices() {
    if (_providerLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum limit of $_providerMaxCapabilities provider capabilities reached.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.push(AppRoutes.accountServices);
  }

  bool get _hasDraftContent =>
      _step > 0 &&
      (_need != null ||
          _when != null ||
          _locationSelected ||
          _budget.text.trim().isNotEmpty ||
          _details.text.trim().isNotEmpty);

  Future<void> _loadPromptDraft() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || widget.draftId == null) return;
    final draft = await NeedDraftStore.find(auth.user.id, widget.draftId!);
    if (!mounted || draft == null || draft['kind'] != 'driving_permit') return;
    setState(() {
      _need = draft['need']?.toString();
      _where = draft['where']?.toString();
      _locationSelected = draft['where'] != null;
      _when = draft['when']?.toString();
      _budget.text = draft['budget']?.toString() ?? '';
      _details.text = draft['details']?.toString() ?? '';
      _step = 1;
    });
  }

  Future<bool> _savePromptDraft() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || !_hasDraftContent) return false;
    try {
      final draft = await NeedDraftStore.save(
        auth.user.id,
        {
          'kind': 'driving_permit',
          'title': _need == null
              ? 'Driving permit request'
              : 'Driving permit: $_need',
          'category_slug': 'professional_services',
          'need': _need,
          'where': _where,
          'when': _when,
          'budget': _budget.text.trim(),
          'details': _details.text.trim(),
        },
        id: _draftId,
      );
      _draftId = draft['draft_id']?.toString();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmExit() async {
    if (!await NeedDraftExitGuard.confirmExit(context) || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.marketplace);
      }
    });
  }

  Future<void> _confirmReturnToPicker() async {
    if (!_hasDraftContent) {
      setState(() {
        _step = 0;
        _need = null;
        _where = null;
        _when = null;
        _locationSelected = false;
        _budget.clear();
        _details.clear();
        _customLocation.clear();
      });
      return;
    }
    setState(() => _modalOpen = true);
    final l10n = AppLocalizations.of(context)!;
    final choice = await NeedDraftExitGuard.showPrompt(
      context: context,
      title: l10n.unsavedRequestSaveTitle,
      message: l10n.unsavedRequestResumeMessage,
    );
    if (mounted) setState(() => _modalOpen = false);
    if (!mounted || choice == null || choice == 'stay') return;
    if (choice == 'save') {
      final saved = await _savePromptDraft();
      if (!saved || !mounted) return;
      await _loadDrafts();
    } else if (_draftId != null) {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        await NeedDraftStore.delete(auth.user.id, _draftId!);
      }
      _draftId = null;
      await _loadDrafts();
    }
    if (mounted) {
      setState(() {
        _step = 0;
        _need = null;
        _where = null;
        _when = null;
        _locationSelected = false;
        _budget.clear();
        _details.clear();
        _customLocation.clear();
      });
    }
  }

  Future<void> _loadDrafts() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final drafts = await NeedDraftStore.load(auth.user.id);
    if (mounted) setState(() => _drafts = drafts);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  static const _prompts = <_PostingPrompt>[
    _PostingPrompt(
        'Driving permit', 'Licence help', '🪪', 'Need', 'Matching people'),
    _PostingPrompt(
        'Visa', 'Verified only', '🛂', 'Need', 'Verified providers only'),
    _PostingPrompt('Loan', 'Ask lenders', '💰', 'Loan', 'Lenders only',
        searchTerms: 'loans personal business financing borrower'),
    _PostingPrompt('Currency', 'Buy or sell', '💱', 'Forex', 'Matching people',
        searchTerms: 'forex currency exchange rates buy sell'),
    _PostingPrompt('Equipment', 'Hire or buy', '🚜', 'Need', 'Everyone',
        category: 'machinery_equipment'),
    _PostingPrompt('Transport', 'Cargo, moving', '🚚', 'Need', 'Everyone',
        category: 'transport_logistics'),
    _PostingPrompt('Business', 'Legal, registration', '💼', 'Need', 'Everyone',
        category: 'professional_services'),
    _PostingPrompt('Energy', 'Solar, boreholes', '⚡', 'Need', 'Everyone',
        category: 'energy_utilities'),
    _PostingPrompt(
        'Construction', 'Builders, repairs', '🏗️', 'Need', 'Everyone',
        category: 'construction_building'),
    _PostingPrompt('Education', 'Tutors, courses', '🎓', 'Need', 'Everyone',
        category: 'education_training'),
    _PostingPrompt('Travel', 'Trips, visa help', '🛂', 'Need', 'Everyone',
        category: 'travel_international'),
    _PostingPrompt('Agriculture', 'Farm supplies', '🌱', 'Need', 'Everyone',
        category: 'agriculture_agribusiness'),
    _PostingPrompt('Technology', 'Apps, websites', '💻', 'Need', 'Everyone',
        category: 'technology_digital'),
    _PostingPrompt('Events', 'Planning, vendors', '🎉', 'Need', 'Everyone',
        category: 'events_production'),
  ];

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
    _searchHintTimer?.cancel();
    _pickerScroll
      ..removeListener(_onPickerScroll)
      ..dispose();
    NeedDraftExitGuard.unregister(this);
    _search.dispose();
    _budget.dispose();
    _details.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  String get _searchHint {
    final popularCategories = _popularPrompts
        .map((prompt) => prompt.category)
        .whereType<String>()
        .toSet();
    final presets = NeedFormSchema.categoryPresets.entries
        .where((entry) {
          final categorySlug = entry.key == 'photo_video_music_talent'
              ? 'photo_video_talent'
              : entry.key;
          return !popularCategories.contains(categorySlug);
        })
        .expand((entry) => entry.value.map((preset) => preset.label))
        .toList();
    if (presets.isEmpty) return 'Search for a service...';
    final start = _searchHintOffset % presets.length;
    final examples = List.generate(
      3,
      (index) => presets[(start + index) % presets.length],
    );
    return '${examples.join(', ')}...';
  }

  List<_PostingPrompt> get _visiblePrompts {
    if (_search.text.trim().isEmpty) return _popularPrompts;

    final results = _matchingPrompts;
    if (_showAllSearchResults || results.length <= 10) {
      return results;
    }
    return results.take(10).toList();
  }

  List<_PostingPrompt> get _matchingPrompts {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _prompts;

    final presetPrompts = <_PostingPrompt>[];
    final seenPresets = <String>{};
    for (final entry in NeedFormSchema.categoryPresets.entries) {
      final categorySlug = _searchRouteCategory(entry.key);
      final category = _categoryForSearch(categorySlug);
      for (final preset in entry.value) {
        final presetKey = '$categorySlug:${preset.label.trim().toLowerCase()}';
        if (!seenPresets.add(presetKey)) continue;
        presetPrompts.add(
          _PostingPrompt(
            preset.label,
            category.name,
            _presetIcon(preset.label, category.icon),
            'Need',
            'Everyone',
            category: categorySlug,
            presetLabel: preset.label,
            searchTerms: '${preset.title} ${category.name}',
          ),
        );
      }
    }
    return [
      ..._prompts,
      ...presetPrompts,
    ].where((prompt) {
      return '${prompt.title} ${prompt.subtitle} ${prompt.searchTerms ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  Future<void> _loadNeedCategories() async {
    try {
      final categories = await getIt<NeedsRepository>().getCategories();
      if (!mounted) return;
      setState(() => _needCategories = categories);
    } catch (_) {
      // Search remains usable with its local category fallbacks.
    }
  }

  String _searchRouteCategory(String slug) {
    if (slug == 'events_production' ||
        slug == 'events_celebrations' ||
        slug == 'weddings_celebrations') {
      for (final preferredSlug in const [
        'events_production',
        'events_celebrations',
      ]) {
        if (_needCategories.any((category) => category.slug == preferredSlug)) {
          return preferredSlug;
        }
      }
      return 'events_production';
    }
    if (slug == 'photo_video_music_talent') {
      for (final preferredSlug in const [
        'photo_video_music_talent',
        'photo_video_talent',
      ]) {
        if (_needCategories.any((category) => category.slug == preferredSlug)) {
          return preferredSlug;
        }
      }
      return 'photo_video_music_talent';
    }
    return slug;
  }

  NeedCategory _categoryForSearch(String slug) {
    for (final category in _needCategories) {
      if (category.slug == slug) return category;
    }
    final fallback = NeedCategory.findBySlug(slug);
    if (slug == 'events_production' && fallback.name == slug) {
      return NeedCategory(
        slug: slug,
        name: 'Events & Celebrations',
        icon: '🎉',
      );
    }
    return fallback;
  }

  String _presetIcon(String label, String categoryIcon) {
    final value = label.toLowerCase();
    if (value.contains('cake')) return '🎂';
    if (value.contains('barista')) return '☕';
    if (value.contains('baker') || value.contains('pastry')) return '🥐';
    if (value.contains('chef')) return '👨‍🍳';
    if (value.contains('kitchen assistant')) return '🥣';
    if (value.contains('food server')) return '🍽️';
    if (value.contains('van')) return '🚐';
    if (value.contains('eye')) return '👁️';
    if (value.contains('skin') || value.contains('facial')) return '✨';
    if (value.contains('tattoo')) return '🎨';
    if (value.contains('beauty') || value.contains('makeup')) return '💄';
    if (value.contains('hair') || value.contains('barber')) return '💇';
    if (value.contains('nail')) return '💅';
    if (value.contains('dental') || value.contains('braces')) return '🦷';
    if (value.contains('medical') ||
        value.contains('specialist') ||
        value.contains('consultation') ||
        value.contains('nursing')) {
      return '🩺';
    }
    if (value.contains('circumcision')) return '🩺';
    if (value.contains('photo') || value.contains('video')) return '📸';
    if (value.contains('music') || value.contains('song')) return '🎵';
    if (value.contains('influencer') || value.contains('creator')) return '📱';
    if (value.contains('event') || value.contains('wedding')) return '🎉';
    if (value.contains('tour') || value.contains('travel')) return '✈️';
    if (value.contains('farm') ||
        value.contains('crop') ||
        value.contains('soil')) {
      return '🌱';
    }
    if (value.contains('transport') || value.contains('truck')) return '🚚';
    if (value.contains('equipment') || value.contains('tractor')) return '🚜';
    if (value.contains('loan') || value.contains('finance')) return '💰';
    if (value.contains('repair') || value.contains('maintenance')) return '🔧';
    if (value.contains('energy') || value.contains('solar')) return '⚡';
    if (value.contains('construct') || value.contains('builder')) return '🏗️';
    if (value.contains('tutor') || value.contains('training')) return '🎓';
    if (value.contains('clean') || value.contains('household')) return '🏠';
    if (value.contains('legal') || value.contains('business')) return '💼';
    return categoryIcon;
  }

  void _select(_PostingPrompt prompt) {
    if (prompt.presetLabel != null && prompt.category != null) {
      final route = Uri(
        path: AppRoutes.needsCreateFull,
        queryParameters: {
          'category': prompt.category,
          'preset': prompt.presetLabel,
        },
      );
      context.go(route.toString());
      return;
    }
    if (prompt.title != 'Driving permit') {
      if (prompt.title == 'Loan') context.go(AppRoutes.listingCreate);
      if (prompt.type == 'Forex') context.go(AppRoutes.forexCreate);
      if (prompt.title == 'Visa') {
        context
            .go('${AppRoutes.needsCreateFull}?category=travel_international');
      }
      if (prompt.category != null) {
        context.go('${AppRoutes.needsCreateFull}?category=${prompt.category}');
      }
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _publish() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final budget = int.tryParse(_budget.text.replaceAll(',', ''));
    if (_need == null || _where == null || _when == null || budget == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final country = EastAfricaCountries.findByCode(auth.user.country);
      final category = NeedCategory.findBySlug('professional_services');
      final id = await getIt<NeedsRepository>().createRequest(
        title: 'Driving permit: $_need',
        specification: _details.text.trim().isEmpty
            ? 'I need help with a driving licence or permit.'
            : _details.text.trim(),
        categorySlug: 'professional_services',
        categoryName: category.name,
        details: {
          'service_type': 'Driving School & Driver Training',
          'permit_request_type': _need,
          'requested_location': _where,
          'audience': 'matching_people',
          'posting_prompt': 'driving_permit',
        },
        budget: budget,
        currency: auth.user.incomeCurrency.isNotEmpty
            ? auth.user.incomeCurrency
            : country.currency,
        location: _where == 'Other' ? _customLocation.text.trim() : _where!,
        urgency: _when!,
        country: country.code,
      );
      if (!mounted) return;
      setState(() {
        _requestId = id;
        _step = 3;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post request: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthBloc>().state;
    final country = auth is AuthAuthenticated
        ? EastAfricaCountries.findByCode(auth.user.country)
        : EastAfricaCountries.defaultCountry;
    final locations = country.regions;
    _where ??= locations.isEmpty ? country.name : locations.first;
    final currency =
        auth is AuthAuthenticated && auth.user.incomeCurrency.isNotEmpty
            ? auth.user.incomeCurrency
            : country.currency;

    if (_step == 3) return _confirmation(theme);
    return PopScope<Object?>(
      canPop: !_hasDraftContent || _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: _step == 0
            ? null
            : AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () {
                    if (_step == 2) {
                      setState(() => _step = 1);
                    } else {
                      _confirmReturnToPicker();
                    }
                  },
                ),
                title: const Text('Post a request'),
                titleTextStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
              ),
        body: SafeArea(
          child: _step == 0
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _promptPicker(theme),
                    if (!_modalOpen &&
                        MediaQuery.viewInsetsOf(context).bottom == 0)
                      _AddServiceEdgeButton(
                        tucked: _edgeButtonTucked,
                        onPressed: _openProviderServices,
                      ),
                  ],
                )
              : _permitForm(theme, locations, currency),
        ),
      ),
    );
  }

  Widget _promptPicker(ThemeData theme) => ListView(
        controller: _pickerScroll,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        children: [
          Text('What do you need?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 2),
          Text("Pick one and we'll open the right form.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() => _showAllSearchResults = false),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _showAllSearchResults = false);
                      },
                    ),
              hintText: _searchHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _sectionLabel('YOUR DRAFTS', theme)),
              TextButton(
                onPressed: () =>
                    setState(() => _showAllDrafts = !_showAllDrafts),
                child: Text(
                    _showAllDrafts ? 'Show less' : 'See all ${_drafts.length}'),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'Drafts are automatically deleted after 30 days.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final draft in (_showAllDrafts ? _drafts : _drafts.take(2)))
              _draftTile(draft),
          ],
          const SizedBox(height: 10),
          _sectionLabel(
            _search.text.trim().isEmpty ? 'POPULAR' : 'RESULTS',
            theme,
          ),
          const SizedBox(height: 7),
          if (_visiblePrompts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No matching requests. Try another search.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio:
                  ((MediaQuery.sizeOf(context).width - 44) / 2 / 68)
                      .clamp(2.0, 3.9)
                      .toDouble(),
              children: [
                for (final prompt in _visiblePrompts) _promptCard(prompt)
              ],
            ),
          if (_search.text.trim().isNotEmpty &&
              _matchingPrompts.length > _visiblePrompts.length)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() => _showAllSearchResults = true),
                child: Text('Show all ${_matchingPrompts.length} results'),
              ),
            ),
          const SizedBox(height: 9),
          _somethingElseCard(theme),
        ],
      );

  Widget _sectionLabel(String label, ThemeData theme) => Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.65,
          color: theme.colorScheme.onSurface,
          fontSize: 12,
        ),
      );

  Widget _draftTile(Map<String, dynamic> draft) {
    final draftId = draft['draft_id']?.toString() ?? '';
    final categorySlug = draft['category_slug']?.toString() ?? '';
    final category = NeedCategory.findBySlug(categorySlug);
    final title = draft['title']?.toString().trim();
    final location = (draft['location'] == 'Other'
            ? draft['custom_location']
            : draft['location'])
        ?.toString()
        .trim();
    final isLoanDraft = draft['kind'] == 'loan_request';
    final subtitleParts = [
      if (isLoanDraft)
        'Loan request'
      else if (category.name.isNotEmpty)
        category.name,
      if (location != null && location.isNotEmpty) location,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            final route = isLoanDraft
                ? '${AppRoutes.listingCreate}?draft=$draftId'
                : draft['kind'] == 'driving_permit'
                    ? '${AppRoutes.needsCreate}?draft=$draftId'
                    : '${AppRoutes.needsCreateFull}?draft=$draftId';
            context.go(route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(children: [
              _iconBox(isLoanDraft ? '💰' : category.icon, size: 42),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        title == null || title.isEmpty
                            ? 'Untitled request'
                            : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Resume',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
              IconButton(
                tooltip: 'Delete draft',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                onPressed: () => _deleteDraft(draftId),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDraft(String draftId) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    setState(() => _modalOpen = true);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: const Text('You will not be able to resume it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (mounted) setState(() => _modalOpen = false);
    if (shouldDelete != true || !mounted) return;
    try {
      await NeedDraftStore.delete(auth.user.id, draftId);
      await _loadDrafts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete draft: $error')),
      );
    }
  }

  Widget _somethingElseCard(ThemeData theme) => InkWell(
        onTap: () => context.go(AppRoutes.needsCreateFull),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _iconBox('➕', size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Something else',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('More categories, or describe it yourself',
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      );

  Widget _iconBox(String icon, {double size = 38}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.bg3Dark
              : AppColors.bg3Light,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(icon, style: TextStyle(fontSize: size * 0.56)),
      );

  Widget _promptCard(_PostingPrompt prompt) => InkWell(
        onTap: () => _select(prompt),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.22),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(children: [
            _iconBox(prompt.icon, size: 46),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.1,
                      )),
                  const SizedBox(height: 2),
                  Text(prompt.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w400,
                          )),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _permitForm(ThemeData theme, List<String> locations, String currency) {
    if (_step == 2) return _audience(theme);
    return Column(children: [
      Expanded(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Row(children: [
                const Text('🪪', style: TextStyle(fontSize: 27)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Driving permit',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF1D6),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Need',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF8A5700))))
                    ]))
              ]),
              const SizedBox(height: 12),
              Text('Get help with a driving licence or permit.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              _label('What do you need?'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in [
                  'New licence',
                  'Renew',
                  'Replace lost',
                  'Upgrade class',
                  'Learner permit'
                ])
                  _chip(item, _need == item, () => setState(() => _need = item))
              ]),
              const SizedBox(height: 20),
              _label('Where?'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in [...locations.take(3), 'Other'])
                  _chip(
                      item,
                      _where == item,
                      () => setState(() {
                            _where = item;
                            _locationSelected = true;
                          }))
              ]),
              if (_where == 'Other')
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                        controller: _customLocation,
                        decoration: const InputDecoration(
                            hintText: 'Town or area',
                            border: OutlineInputBorder()))),
              const SizedBox(height: 20),
              _label('When?'),
              Wrap(spacing: 8, children: [
                for (final item in ['Urgent', 'This week', 'Flexible'])
                  _chip(item, _when == item, () => setState(() => _when = item))
              ]),
              const SizedBox(height: 20),
              _label('Budget ($currency)'),
              TextField(
                  controller: _budget,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      hintText: 'e.g. 15,000', border: OutlineInputBorder())),
              const SizedBox(height: 18),
              _label('Anything else?'),
              TextField(
                  controller: _details,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Short details', border: OutlineInputBorder())),
            ]),
      ),
      SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
                onPressed: _need != null &&
                        _where != null &&
                        _when != null &&
                        int.tryParse(_budget.text) != null
                    ? () => setState(() => _step = 2)
                    : null,
                child: const Text('Next: who can see it'))),
      ),
    ]);
  }

  Widget _audience(ThemeData theme) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Who can see it?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Suggested for Driving permit'),
          const SizedBox(height: 16),
          const Card(
              child: ListTile(
                  leading: Icon(Icons.groups_2_outlined),
                  title: Text('Matching people'),
                  subtitle:
                      Text('People who can help with your permit request'),
                  trailing: Icon(Icons.check_circle, color: AppColors.accent))),
        ])),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                  onPressed: _busy ? null : _publish,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Text('Post request'))),
        ),
      ]);

  Widget _confirmation(ThemeData theme) => Scaffold(
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 60),
                    const SizedBox(height: 16),
                    Text('Your request is live',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('It can be seen by matching people.'),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: () =>
                                context.go('/marketplace/needs/$_requestId'),
                            child: const Text('View my request'))),
                    TextButton(
                        onPressed: () => setState(() {
                              _step = 0;
                              _need = null;
                              _when = null;
                              _budget.clear();
                              _details.clear();
                            }),
                        child: const Text('Post another')),
                  ])))));

  Widget _label(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)));

  Widget _chip(String text, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(text), selected: selected, onSelected: (_) => onTap());
}

class _PostingPrompt {
  const _PostingPrompt(
      this.title, this.subtitle, this.icon, this.type, this.audience,
      {this.category, this.presetLabel, this.searchTerms});
  final String title;
  final String subtitle;
  final String icon;
  final String type;
  final String audience;
  final String? category;
  final String? presetLabel;
  final String? searchTerms;
}

class _AddServiceEdgeButton extends StatelessWidget {
  const _AddServiceEdgeButton({
    required this.tucked,
    required this.onPressed,
  });

  final bool tucked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context)!;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 280);
    return AnimatedPositioned(
      duration: duration,
      curve: Curves.easeOut,
      right: tucked ? -22 : -10,
      bottom: 12,
      width: 64,
      height: 44,
      child: Semantics(
        button: true,
        label: l10n.addService,
        onTap: onPressed,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Transform.rotate(
                  angle: -0.15708,
                  child: Container(
                    width: 58,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B6BFF),
                          Color(0xFF6D4AFF),
                          Color(0xFF5937E8),
                        ],
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(17),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6D4AFF).withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 23),
                        Positioned(
                          top: 6,
                          right: 10,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white.withValues(alpha: 0.78),
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
