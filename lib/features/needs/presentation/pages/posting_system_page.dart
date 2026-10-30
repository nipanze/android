import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/need_draft_exit_guard.dart';
import '../../data/need_draft_store.dart';
import '../../data/needs_repository.dart';
import '../../domain/models/need_category.dart';

/// Prompt-led entry point for the request posting flow. Driving Permit is the
/// first fully wired prompt; other cards remain visible as the catalog grows.
class PostingSystemPage extends StatefulWidget {
  const PostingSystemPage({super.key, this.draftId});

  final String? draftId;

  @override
  State<PostingSystemPage> createState() => _PostingSystemPageState();
}

class _PostingSystemPageState extends State<PostingSystemPage> {
  final _search = TextEditingController();
  final _budget = TextEditingController();
  final _details = TextEditingController();
  final _customLocation = TextEditingController();
  String? _need;
  String? _where;
  String? _when;
  int _step = 0;
  bool _busy = false;
  bool _showAllDrafts = false;
  String? _requestId;
  List<Map<String, dynamic>> _drafts = const [];
  bool _allowExit = false;
  bool _locationSelected = false;
  String? _draftId;

  @override
  void initState() {
    super.initState();
    _draftId = widget.draftId;
    _budget.addListener(_refresh);
    _loadDrafts();
    NeedDraftExitGuard.register(
      this,
      hasChanges: () => _hasDraftContent,
      saveDraft: _savePromptDraft,
    );
    if (widget.draftId != null) _loadPromptDraft();
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
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save this request as a draft?'),
        content: const Text(
          'You can resume it later from Your drafts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
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
    _PostingPrompt('Loan', 'Ask lenders', '💰', 'Loan', 'Lenders only'),
    _PostingPrompt('Currency', 'Buy or sell', '💱', 'Forex', 'Matching people'),
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
    NeedDraftExitGuard.unregister(this);
    _search.dispose();
    _budget.dispose();
    _details.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  List<_PostingPrompt> get _visiblePrompts => _prompts
      .where((prompt) => '${prompt.title} ${prompt.subtitle}'
          .toLowerCase()
          .contains(_search.text.trim().toLowerCase()))
      .toList();

  void _select(_PostingPrompt prompt) {
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
              ? _promptPicker(theme)
              : _permitForm(theme, locations, currency),
        ),
      ),
    );
  }

  Widget _promptPicker(ThemeData theme) => ListView(
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
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search: permit, visa, truck, loan...',
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
          _sectionLabel('POPULAR', theme),
          const SizedBox(height: 7),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: ((MediaQuery.sizeOf(context).width - 44) / 2 / 62)
                .clamp(2.4, 3.9)
                .toDouble(),
            children: [
              for (final prompt in _visiblePrompts) _promptCard(prompt)
            ],
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
    final subtitleParts = [
      if (category.name.isNotEmpty) category.name,
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
            final route = draft['kind'] == 'driving_permit'
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
              _iconBox(category.icon, size: 42),
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

  Widget _iconBox(String icon, {double size = 38}) {
    final style = _illustrationStyle(icon);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.$2, style.$3],
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: [
          BoxShadow(
            color: style.$3.withValues(alpha: 0.22),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: Icon(style.$1, color: Colors.white, size: size * 0.58),
    );
  }

  (IconData, Color, Color) _illustrationStyle(String emoji) => switch (emoji) {
        '🪪' => (
            Icons.badge_rounded,
            const Color(0xFF63B5FF),
            const Color(0xFF2563EB)
          ),
        '🛂' => (
            Icons.flight_takeoff_rounded,
            const Color(0xFF4588FF),
            const Color(0xFF2349D8)
          ),
        '💰' => (
            Icons.savings_rounded,
            const Color(0xFFFFC247),
            const Color(0xFFF28A00)
          ),
        '💱' => (
            Icons.currency_exchange_rounded,
            const Color(0xFF45D6B0),
            const Color(0xFF079879)
          ),
        '🚜' => (
            Icons.agriculture_rounded,
            const Color(0xFF73D77A),
            const Color(0xFF219653)
          ),
        '🚚' => (
            Icons.local_shipping_rounded,
            const Color(0xFFFFA45B),
            const Color(0xFFE65332)
          ),
        '💼' => (
            Icons.business_center_rounded,
            const Color(0xFFB88CFF),
            const Color(0xFF7543D6)
          ),
        '⚡' => (
            Icons.bolt_rounded,
            const Color(0xFFFFD447),
            const Color(0xFFEF8C00)
          ),
        '🏗️' => (
            Icons.construction_rounded,
            const Color(0xFFFFA34D),
            const Color(0xFFE56820)
          ),
        '🎓' => (
            Icons.school_rounded,
            const Color(0xFF9B8AFF),
            const Color(0xFF5A43D6)
          ),
        '🌱' => (
            Icons.grass_rounded,
            const Color(0xFF73D77A),
            const Color(0xFF168A58)
          ),
        '💻' => (
            Icons.laptop_mac_rounded,
            const Color(0xFF70C8FF),
            const Color(0xFF3267D5)
          ),
        '🎉' => (
            Icons.celebration_rounded,
            const Color(0xFFFF76B8),
            const Color(0xFFCA35B3)
          ),
        '➕' => (
            Icons.add_rounded,
            const Color(0xFF76ABFF),
            const Color(0xFF356FE0)
          ),
        _ => (
            Icons.category_rounded,
            const Color(0xFF7FB8FF),
            const Color(0xFF4669D8)
          ),
      };

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
            _iconBox(prompt.icon, size: 52),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(prompt.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
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
      {this.category});
  final String title;
  final String subtitle;
  final String icon;
  final String type;
  final String audience;
  final String? category;
}
