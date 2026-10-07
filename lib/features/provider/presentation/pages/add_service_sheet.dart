// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';

const _marketingServicesSlug = 'marketing_services';
const _audienceCapabilitySlug = 'i_have_an_audience';
const _marketingCapabilitySlugs = {
  'social_media_marketing',
  'tiktok_promotion',
  'instagram_promotion',
  'youtube_promotion',
  'facebook_promotion',
  'influencer_marketing',
  'content_creation',
  'product_reviews',
  'event_promotion',
  'whatsapp_community_promotion',
  'affiliate_marketing',
  'advertising_campaigns',
  'brand_promotion',
  'other_marketing_services',
  _audienceCapabilitySlug,
};

const _financialCategorySlug = 'financial_services';
const _bankLoanAgentSlug = 'bank_loan_agent';
const _financialMetadataSlugs = {
  'bank_loan_agent',
  'loan_services',
  'forex_currency_exchange',
  'sacco_microfinance',
};

class ProviderCapabilitySelection {
  const ProviderCapabilitySelection({
    required this.slugs,
    this.metadataBySlug = const {},
  });

  final List<String> slugs;
  final Map<String, Map<String, dynamic>> metadataBySlug;
}

/// Bottom sheet for adding provider capabilities.
/// Returns selected slugs and metadata, or null if dismissed.
class AddServiceSheet extends StatefulWidget {
  const AddServiceSheet({
    super.key,
    required this.existingSlugs,
    this.existingAudienceMetadata,
    this.preselectedCategorySlug,
    required this.needsRepository,
  });

  final Set<String> existingSlugs;
  final Map<String, dynamic>? existingAudienceMetadata;
  final String? preselectedCategorySlug;
  final NeedsRepository needsRepository;

  static Future<ProviderCapabilitySelection?> show(
    BuildContext context, {
    required Set<String> existingSlugs,
    Map<String, dynamic>? existingAudienceMetadata,
    required NeedsRepository needsRepository,
    String? preselectedCategorySlug,
  }) {
    return showModalBottomSheet<ProviderCapabilitySelection>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AddServiceSheet(
              existingSlugs: existingSlugs,
              existingAudienceMetadata: existingAudienceMetadata,
              preselectedCategorySlug: preselectedCategorySlug,
              needsRepository: needsRepository,
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  int _step = 0; // 0 = category, 1 = capability
  NeedCategory? _selectedCategory;
  List<NeedCategory> _categories = [];
  List<NeedCapability> _categoryCapabilities = [];
  List<NeedCapability> _marketingCapabilities = [];
  final Set<String> _selected = {};
  final Set<String> _audiencePlatforms = {};
  final _audienceCountController = TextEditingController();
  final _audienceLocationController = TextEditingController();
  final _audienceInterestController = TextEditingController();
  // Financial services metadata
  final _institutionController = TextEditingController();
  final _roleController = TextEditingController();
  bool _showProfessionalTag = true;
  bool _allowInstitutionMatching = false;
  bool _showMarketing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final audience = widget.existingAudienceMetadata;
    if (widget.existingSlugs.contains(_audienceCapabilitySlug)) {
      _selected.add(_audienceCapabilitySlug);
      _audiencePlatforms.addAll(
        (audience?['audience_platforms'] as List? ?? const [])
            .map((platform) => platform.toString()),
      );
      _audienceCountController.text =
          audience?['audience_followers_count']?.toString() ?? '';
      _audienceLocationController.text =
          audience?['audience_main_location']?.toString() ?? '';
      _audienceInterestController.text =
          audience?['audience_main_interest']?.toString() ?? '';
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _audienceCountController.dispose();
    _audienceLocationController.dispose();
    _audienceInterestController.dispose();
    _institutionController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  ProviderCapabilitySelection _selection() {
    final slugs = _selected.toList();
    final metadataBySlug = <String, Map<String, dynamic>>{};

    if (_selected.contains(_audienceCapabilitySlug)) {
      metadataBySlug[_audienceCapabilitySlug] = {
        'audience_platforms': _audiencePlatforms.toList(),
        'audience_followers_count': int.tryParse(
          _audienceCountController.text.trim(),
        ),
        'audience_main_location': _audienceLocationController.text.trim(),
        'audience_main_interest': _audienceInterestController.text.trim(),
      };
    }

    // Include financial metadata for each selected financial capability
    final financialSelected = _selected.intersection(_financialMetadataSlugs);
    if (financialSelected.isNotEmpty) {
      final institution = _institutionController.text.trim();
      final role = _roleController.text.trim();
      if (institution.isNotEmpty || role.isNotEmpty) {
        for (final slug in financialSelected) {
          metadataBySlug[slug] = {
            if (institution.isNotEmpty) 'institution': institution,
            if (role.isNotEmpty) 'role': role,
            'show_professional_tag': _showProfessionalTag,
            'allow_institution_matching': _allowInstitutionMatching,
          };
        }
      }
    }

    return ProviderCapabilitySelection(
      slugs: slugs,
      metadataBySlug: metadataBySlug,
    );
  }

  bool get _canSubmit =>
      _selected.isNotEmpty &&
      (!_selected.contains(_audienceCapabilitySlug) ||
          _audiencePlatforms.isNotEmpty);

  Future<void> _loadCategories() async {
    final cats = await widget.needsRepository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });

    // If preselected, skip to step 1
    if (widget.preselectedCategorySlug != null) {
      final cat = cats.firstWhere(
        (c) => c.slug == widget.preselectedCategorySlug,
        orElse: () => cats.first,
      );
      await _selectCategory(cat);
    }
  }

  Future<void> _selectCategory(NeedCategory cat) async {
    setState(() {
      _selectedCategory = cat;
      _showMarketing = false;
      _loading = true;
    });
    final caps =
        await widget.needsRepository.getCapabilities(categorySlug: cat.slug);
    if (!mounted) return;

    List<NeedCapability> filteredCaps;
    if (cat.slug == 'professional_services') {
      filteredCaps = caps
          .where((capability) =>
              !_marketingCapabilitySlugs.contains(capability.slug))
          .toList();
      if (!filteredCaps.any((c) => c.slug == _marketingServicesSlug)) {
        filteredCaps.add(
          const NeedCapability(
            slug: _marketingServicesSlug,
            categorySlug: 'professional_services',
            name: 'Marketing & Promotion',
          ),
        );
      }
    } else {
      filteredCaps = caps;
    }

    setState(() {
      _categoryCapabilities = filteredCaps;
      _loading = false;
      _step = 1;
    });
  }

  Future<void> _openMarketing() async {
    setState(() {
      _showMarketing = true;
      _loading = true;
    });
    final caps = await widget.needsRepository.getCapabilities(
      categorySlug: 'professional_services',
    );
    if (!mounted) return;
    setState(() {
      _marketingCapabilities = caps
          .where((capability) =>
              _marketingCapabilitySlugs.contains(capability.slug))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _loading = false;
    });
  }

  void _goBack() {
    setState(() {
      if (_showMarketing) {
        _showMarketing = false;
      } else {
        _step = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    if (_step == 1)
                      GestureDetector(
                        onTap: _goBack,
                        child: Icon(Icons.arrow_back_rounded,
                            color: text2, size: 22),
                      ),
                    if (_step == 1) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _step == 0
                            ? l10n.chooseCategory
                            : _showMarketing
                                ? l10n.marketingAndPromotion
                                : (_selectedCategory?.name ??
                                    l10n.chooseCapabilities),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_step == 1 && _canSubmit)
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selection()),
                        child: Text(
                          l10n.addSelected,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _step == 0
                        ? _CategoryList(
                            categories: _categories,
                            scrollController: scrollController,
                            onSelect: _selectCategory,
                          )
                        : _showMarketing
                            ? _MarketingCapabilityList(
                                capabilities: _marketingCapabilities,
                                existingSlugs: widget.existingSlugs,
                                selected: _selected,
                                audiencePlatforms: _audiencePlatforms,
                                audienceCountController:
                                    _audienceCountController,
                                audienceLocationController:
                                    _audienceLocationController,
                                audienceInterestController:
                                    _audienceInterestController,
                                scrollController: scrollController,
                                onToggle: (slug) => setState(() {
                                  if (_selected.contains(slug)) {
                                    _selected.remove(slug);
                                  } else {
                                    _selected.add(slug);
                                  }
                                }),
                                onPlatformToggle: (platform) => setState(() {
                                  if (_audiencePlatforms.contains(platform)) {
                                    _audiencePlatforms.remove(platform);
                                  } else {
                                    _audiencePlatforms.add(platform);
                                  }
                                }),
                              )
                            : _selectedCategory?.slug == _financialCategorySlug
                                ? _FinancialCapabilityList(
                                    capabilities: _categoryCapabilities,
                                    existingSlugs: widget.existingSlugs,
                                    selected: _selected,
                                    institutionController: _institutionController,
                                    roleController: _roleController,
                                    showProfessionalTag: _showProfessionalTag,
                                    allowInstitutionMatching:
                                        _allowInstitutionMatching,
                                    scrollController: scrollController,
                                    onToggle: (slug) {
                                      setState(() {
                                        if (_selected.contains(slug)) {
                                          _selected.remove(slug);
                                        } else {
                                          _selected.add(slug);
                                        }
                                      });
                                    },
                                    onProfessionalTagChanged: (v) =>
                                        setState(() => _showProfessionalTag = v),
                                    onInstitutionMatchingChanged: (v) =>
                                        setState(
                                            () => _allowInstitutionMatching = v),
                                  )
                                : _CapabilityList(
                                    capabilities: _categoryCapabilities,
                                    existingSlugs: widget.existingSlugs,
                                    selected: _selected,
                                    scrollController: scrollController,
                                    onMarketingTap: _openMarketing,
                                    onToggle: (slug) {
                                      setState(() {
                                        if (_selected.contains(slug)) {
                                          _selected.remove(slug);
                                        } else {
                                          _selected.add(slug);
                                        }
                                      });
                                    },
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.scrollController,
    required this.onSelect,
  });

  final List<NeedCategory> categories;
  final ScrollController scrollController;
  final void Function(NeedCategory) onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bg3 = isDark ? AppColors.bg3Dark : AppColors.bg3Light;

    return ListView.separated(
      controller: scrollController,
      itemCount: categories.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: border),
      itemBuilder: (_, i) {
        final cat = categories[i];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg3,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(cat.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: cat.description == null || cat.description!.isEmpty
              ? null
              : Text(
                  cat.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onSelect(cat),
        );
      },
    );
  }
}

class _CapabilityList extends StatelessWidget {
  const _CapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.scrollController,
    required this.onMarketingTap,
    required this.onToggle,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final ScrollController scrollController;
  final VoidCallback onMarketingTap;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return ListView.separated(
      controller: scrollController,
      itemCount: capabilities.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: border),
      itemBuilder: (_, i) {
        final cap = capabilities[i];
        if (cap.slug == _marketingServicesSlug) {
          return ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: Text(
              AppLocalizations.of(context)!.marketingAndPromotion,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onMarketingTap,
          );
        }
        final alreadyOwned = existingSlugs.contains(cap.slug);
        final isSelected = selected.contains(cap.slug);

        return ListTile(
          enabled: !alreadyOwned,
          leading: alreadyOwned
              ? const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22)
              : Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(cap.slug),
                  activeColor: AppColors.accent,
                ),
          title: Text(
            cap.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: alreadyOwned ? text2 : null,
            ),
          ),
          onTap: alreadyOwned ? null : () => onToggle(cap.slug),
        );
      },
    );
  }
}

class _FinancialCapabilityList extends StatelessWidget {
  const _FinancialCapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.institutionController,
    required this.roleController,
    required this.showProfessionalTag,
    required this.allowInstitutionMatching,
    required this.scrollController,
    required this.onToggle,
    required this.onProfessionalTagChanged,
    required this.onInstitutionMatchingChanged,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final TextEditingController institutionController;
  final TextEditingController roleController;
  final bool showProfessionalTag;
  final bool allowInstitutionMatching;
  final ScrollController scrollController;
  final void Function(String) onToggle;
  final void Function(bool) onProfessionalTagChanged;
  final void Function(bool) onInstitutionMatchingChanged;

  bool get _hasFinancialSelected =>
      selected.intersection(_financialMetadataSlugs).isNotEmpty ||
      existingSlugs.intersection(_financialMetadataSlugs).isNotEmpty;

  bool get _hasBankAgent =>
      selected.contains(_bankLoanAgentSlug) ||
      existingSlugs.contains(_bankLoanAgentSlug);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return ListView(
      controller: scrollController,
      children: [
        for (final cap in capabilities)
          Builder(builder: (context) {
            final alreadyOwned = existingSlugs.contains(cap.slug);
            final isSelected = selected.contains(cap.slug);
            return Column(
              children: [
                ListTile(
                  enabled: !alreadyOwned,
                  leading: alreadyOwned
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggle(cap.slug),
                          activeColor: AppColors.accent,
                        ),
                  title: Text(
                    cap.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: alreadyOwned ? text2 : null,
                    ),
                  ),
                  onTap: alreadyOwned ? null : () => onToggle(cap.slug),
                ),
                Divider(height: 1, color: border),
              ],
            );
          }),
        // Contextual fields shown when any financial capability is selected
        if (_hasFinancialSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Organisation (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your institution and role so requesters know who you represent.',
                  style: TextStyle(fontSize: 12, color: text2),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: institutionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Institution / Bank / Organisation',
                    hintText: 'e.g. Equity Bank, Hans Finance, ABC Forex',
                    prefixIcon:
                        Icon(Icons.account_balance_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your Role (optional)',
                    hintText: 'e.g. Independent Loan Provider, Bank Agent',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                if (_hasBankAgent)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow institution matching'),
                    subtitle: Text(
                      'Let borrowers from your institution find your offers.',
                      style: TextStyle(fontSize: 12, color: text2),
                    ),
                    value: allowInstitutionMatching,
                    onChanged: onInstitutionMatchingChanged,
                  ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show professional tag'),
                  subtitle: Text(
                    'Display your institution and role label on offers.',
                    style: TextStyle(fontSize: 12, color: text2),
                  ),
                  value: showProfessionalTag,
                  onChanged: onProfessionalTagChanged,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _MarketingCapabilityList extends StatelessWidget {
  const _MarketingCapabilityList({
    required this.capabilities,
    required this.existingSlugs,
    required this.selected,
    required this.audiencePlatforms,
    required this.audienceCountController,
    required this.audienceLocationController,
    required this.audienceInterestController,
    required this.scrollController,
    required this.onToggle,
    required this.onPlatformToggle,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final Set<String> audiencePlatforms;
  final TextEditingController audienceCountController;
  final TextEditingController audienceLocationController;
  final TextEditingController audienceInterestController;
  final ScrollController scrollController;
  final void Function(String) onToggle;
  final void Function(String) onPlatformToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final audienceSelected = selected.contains(_audienceCapabilitySlug) ||
        existingSlugs.contains(_audienceCapabilitySlug);
    final platforms = <(String, String)>[
      ('tiktok', l10n.audiencePlatformTikTok),
      ('instagram', l10n.audiencePlatformInstagram),
      ('youtube', l10n.audiencePlatformYouTube),
      ('facebook', l10n.audiencePlatformFacebook),
      ('whatsapp', l10n.audiencePlatformWhatsApp),
      ('other', l10n.audiencePlatformOther),
    ];

    return ListView(
      controller: scrollController,
      children: [
        for (final capability in capabilities)
          Builder(builder: (context) {
            final alreadyOwned = existingSlugs.contains(capability.slug);
            final isSelected = selected.contains(capability.slug);
            final name = _marketingCapabilityName(capability.slug, l10n);
            return Column(
              children: [
                ListTile(
                  enabled: !alreadyOwned,
                  leading: alreadyOwned
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggle(capability.slug),
                          activeColor: AppColors.accent,
                        ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: alreadyOwned ? text2 : null,
                    ),
                  ),
                  onTap: alreadyOwned ? null : () => onToggle(capability.slug),
                ),
                Divider(height: 1, color: border),
              ],
            );
          }),
        if (audienceSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whereIsYourAudience,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.selectAudiencePlatforms,
                  style: TextStyle(fontSize: 12, color: text2),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: [
                    for (final (slug, label) in platforms)
                      FilterChip(
                        label: Text(label),
                        selected: audiencePlatforms.contains(slug),
                        onSelected: (_) => onPlatformToggle(slug),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tellBusinessesAboutYourAudience,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.audienceFollowersMembersCount,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceLocationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.audienceMainLocation,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceInterestController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.audienceMainInterest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _marketingCapabilityName(String slug, AppLocalizations l10n) =>
      switch (slug) {
        'social_media_marketing' => l10n.socialMediaMarketing,
        'tiktok_promotion' => l10n.tiktokPromotion,
        'instagram_promotion' => l10n.instagramPromotion,
        'youtube_promotion' => l10n.youtubePromotion,
        'facebook_promotion' => l10n.facebookPromotion,
        'influencer_marketing' => l10n.influencerMarketing,
        'content_creation' => l10n.contentCreation,
        'product_reviews' => l10n.productReviews,
        'event_promotion' => l10n.eventPromotion,
        'whatsapp_community_promotion' => l10n.whatsAppCommunityPromotion,
        'affiliate_marketing' => l10n.affiliateMarketing,
        'advertising_campaigns' => l10n.advertisingCampaigns,
        'brand_promotion' => l10n.brandPromotion,
        'other_marketing_services' => l10n.otherMarketingServices,
        _audienceCapabilitySlug => l10n.iHaveAnAudience,
        _ => slug,
      };
}
