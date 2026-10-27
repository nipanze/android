import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../account/domain/models/user_profile.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../../provider/domain/entities/provider_service_role.dart';
import '../../data/job_profile_repository.dart';
import '../../domain/models/job_profile.dart';

class WorkProfileSection extends StatefulWidget {
  const WorkProfileSection({
    super.key,
    required this.repository,
    required this.needsRepository,
    this.profile,
  });

  final JobProfileRepository repository;
  final NeedsRepository needsRepository;
  final UserProfile? profile;

  @override
  State<WorkProfileSection> createState() => _WorkProfileSectionState();
}

class _WorkProfileSectionState extends State<WorkProfileSection> {
  late Future<_WorkProfileLoad> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WorkProfileLoad> _load() async {
    final enabled = await widget.repository.jobProfilesEnabled();
    if (!enabled) return const _WorkProfileLoad(enabled: false);
    final profiles = await widget.repository.getMyProfiles();
    return _WorkProfileLoad(enabled: true, profiles: profiles);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bg = isDark ? AppColors.bg3Dark : AppColors.bg3Light;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    return FutureBuilder<_WorkProfileLoad>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _WorkProfileShell(
            border: border,
            bg: bg,
            title: l10n.workProfileTitle,
            subtitle: userFacingErrorMessage(snapshot.error!),
            actionLabel: l10n.retry,
            onAction: _refresh,
          );
        }
        if (data?.enabled != true) {
          return _WorkProfileShell(
            border: border,
            bg: bg,
            title: l10n.workProfileTitle,
            subtitle: l10n.workProfilesDisabled,
          );
        }

        final profiles = data!.profiles;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_outline_rounded,
                      color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.workProfileTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showEditor,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addWorkProfile),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.workProfileSubtitle,
                style: TextStyle(color: text2, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (profiles.isEmpty)
                _EmptyWorkProfile(textColor: text2)
              else
                ...profiles.map(
                  (profile) => _WorkProfileCard(
                    profile: profile,
                    textColor: text2,
                    onEdit: () => _showEditor(existing: profile),
                    onDeactivate: profile.isActive
                        ? () => _confirmDeactivate(profile)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditor({JobProfile? existing}) async {
    final country = EastAfricaCountries.findByCode(
      widget.profile?.country ?? 'UG',
    );
    final saved = await WorkProfileEditorSheet.show(
      context,
      repository: widget.repository,
      needsRepository: widget.needsRepository,
      defaultCurrency: widget.profile?.incomeCurrency ?? country.currency,
      existing: existing,
    );
    if (saved == true) await _refresh();
  }

  Future<void> _confirmDeactivate(JobProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deactivateWorkProfile),
        content: Text(l10n.deactivateWorkProfileConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.deactivate,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deactivateProfile(profile.id);
    await _refresh();
  }
}

class _WorkProfileLoad {
  const _WorkProfileLoad({
    required this.enabled,
    this.profiles = const [],
  });

  final bool enabled;
  final List<JobProfile> profiles;
}

class _WorkProfileShell extends StatelessWidget {
  const _WorkProfileShell({
    required this.border,
    required this.bg,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final Color border;
  final Color bg;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _EmptyWorkProfile extends StatelessWidget {
  const _EmptyWorkProfile({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        l10n.noWorkProfilesYet,
        style: TextStyle(color: textColor),
      ),
    );
  }
}

class _WorkProfileCard extends StatelessWidget {
  const _WorkProfileCard({
    required this.profile,
    required this.textColor,
    required this.onEdit,
    this.onDeactivate,
  });

  final JobProfile profile;
  final Color textColor;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final pay = profile.expectedPayAmount == null
        ? l10n.payOpen
        : '${profile.preferredCurrency} ${profile.expectedPayAmount} / ${profile.expectedPayPeriod ?? l10n.perMonth}'
            .trim();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                profile.categoryIcon ?? '•',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.categoryName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profile.isActive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  profile.isActive ? 'Active' : l10n.inactive,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        profile.isActive ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'deactivate') onDeactivate?.call();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  if (onDeactivate != null)
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Text(l10n.deactivate),
                    ),
                ],
              ),
            ],
          ),
          if (profile.roles.any((role) => role.isActive)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final role in profile.roles.where((role) => role.isActive))
                  Chip(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      role.workTypes.isNotEmpty
                          ? '${role.roleName} (${role.workTypes.length})'
                          : role.roleName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
          if (profile.qualificationCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    size: 15, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  l10n.qualificationsDeclared(profile.qualificationCount),
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noMatchingJobOpportunities,
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkProfileEditorSheet extends StatefulWidget {
  const WorkProfileEditorSheet({
    super.key,
    required this.repository,
    required this.needsRepository,
    required this.defaultCurrency,
    this.existing,
    this.preselectedCategorySlug,
  });

  final JobProfileRepository repository;
  final NeedsRepository needsRepository;
  final String defaultCurrency;
  final JobProfile? existing;
  final String? preselectedCategorySlug;

  static Future<bool?> show(
    BuildContext context, {
    required JobProfileRepository repository,
    required NeedsRepository needsRepository,
    required String defaultCurrency,
    JobProfile? existing,
    String? preselectedCategorySlug,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkProfileEditorSheet(
        repository: repository,
        needsRepository: needsRepository,
        defaultCurrency: defaultCurrency,
        existing: existing,
        preselectedCategorySlug: preselectedCategorySlug,
      ),
    );
  }

  @override
  State<WorkProfileEditorSheet> createState() => _WorkProfileEditorSheetState();
}

class _WorkProfileEditorSheetState extends State<WorkProfileEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _payController = TextEditingController();
  final _summaryController = TextEditingController();
  final Set<String> _selectedLanguages = {'en'};
  final Set<String> _selectedRoleSlugs = {};
  final Map<String, String?> _yearsExpByRole = {};
  final Map<String, Set<String>> _workTypesByRole = {};
  final Map<String, Set<String>> _qualificationsByRole = {};

  List<NeedCategory> _categories = [];
  List<ProviderServiceRole> _roles = [];
  NeedCategory? _category;
  String? _availability;
  String _remotePreference = 'flexible';
  String? _payPeriod = 'month';
  String? _yearsExperience;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _availability = existing.availability;
      _remotePreference = existing.remotePreference;
      _payPeriod = existing.expectedPayPeriod ?? 'month';
      _locationController.text = existing.preferredLocation ?? '';
      _payController.text = existing.expectedPayAmount?.toString() ?? '';
      _summaryController.text = existing.summary ?? '';
      _selectedLanguages
        ..clear()
        ..addAll(
            existing.languages.isEmpty ? const ['en'] : existing.languages);
      for (final r in existing.roles) {
        _selectedRoleSlugs.add(r.roleSlug);
        _yearsExpByRole[r.roleSlug] = r.yearsExperience;
        _workTypesByRole[r.roleSlug] = r.workTypes.map((w) => w.slug).toSet();
        _qualificationsByRole[r.roleSlug] =
            r.qualifications.map((q) => q.slug).toSet();
      }
      _yearsExperience = existing.roles.firstOrNull?.yearsExperience;
    }
    _load();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _payController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final categories = await widget.needsRepository.getCategories();
    NeedCategory? selected;
    if (widget.existing != null) {
      selected = categories
          .where((item) => item.slug == widget.existing!.categorySlug)
          .firstOrNull;
    } else if (widget.preselectedCategorySlug != null) {
      selected = categories
          .where((item) => item.slug == widget.preselectedCategorySlug)
          .firstOrNull;
    }
    selected ??= categories.firstOrNull;
    final roles = selected == null
        ? const <ProviderServiceRole>[]
        : await widget.repository.getRoles(selected.slug);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _category = selected;
      _roles = roles;
      if (widget.existing == null && roles.isNotEmpty) {
        _selectedRoleSlugs.add(roles.first.slug);
      }
      _loading = false;
    });
  }

  Future<void> _changeCategory(NeedCategory? category) async {
    if (category == null) return;
    setState(() {
      _category = category;
      _selectedRoleSlugs.clear();
      _workTypesByRole.clear();
      _qualificationsByRole.clear();
      _yearsExpByRole.clear();
      _roles = const [];
      _loading = true;
    });
    final roles = await widget.repository.getRoles(category.slug);
    if (!mounted) return;
    setState(() {
      _roles = roles;
      if (roles.isNotEmpty) {
        _selectedRoleSlugs.add(roles.first.slug);
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _category == null) {
      return;
    }
    if (_selectedRoleSlugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectAtLeastOneRole)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final roleDrafts = _selectedRoleSlugs.map((slug) {
        return JobProfileRoleDraft(
          roleSlug: slug,
          yearsExperience: _yearsExpByRole[slug] ?? _yearsExperience,
          workTypeSlugs: _workTypesByRole[slug]?.toList() ?? const [],
          qualificationSlugs: _qualificationsByRole[slug]?.toList() ?? const [],
        );
      }).toList();

      await widget.repository.saveProfile(
        JobProfileDraft(
          categorySlug: _category!.slug,
          preferredCurrency: widget.defaultCurrency,
          availability: _availability,
          preferredLocation: _locationController.text.trim(),
          remotePreference: _remotePreference,
          expectedPayAmount: int.tryParse(_payController.text.trim()),
          expectedPayPeriod: _payPeriod,
          languages: _selectedLanguages.toList(),
          summary: _summaryController.text.trim(),
          roles: roleDrafts,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.workProfileTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(l10n.jobOpportunitiesUnavailable,
                        style: TextStyle(color: text2, fontSize: 13)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<NeedCategory>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.chooseCategory,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category.localizedName(localeCode)),
                          ),
                      ],
                      onChanged:
                          widget.existing == null ? _changeCategory : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.jobRole,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (_roles.isEmpty)
                      Text(
                        'No job roles defined for this category yet.',
                        style: TextStyle(color: text2, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final role in _roles)
                            FilterChip(
                              label: Text(role.name),
                              selected: _selectedRoleSlugs.contains(role.slug),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRoleSlugs.add(role.slug);
                                    _workTypesByRole.putIfAbsent(
                                        role.slug, () => {});
                                    _qualificationsByRole.putIfAbsent(
                                        role.slug, () => {});
                                  } else {
                                    _selectedRoleSlugs.remove(role.slug);
                                    _workTypesByRole.remove(role.slug);
                                    _qualificationsByRole.remove(role.slug);
                                    _yearsExpByRole.remove(role.slug);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    for (final roleSlug in _selectedRoleSlugs) ...[
                      (() {
                        final role =
                            _roles.where((r) => r.slug == roleSlug).firstOrNull;
                        if (role == null) return const SizedBox.shrink();
                        final roleWorkTypes =
                            _workTypesByRole.putIfAbsent(roleSlug, () => {});
                        final roleQualifications = _qualificationsByRole
                            .putIfAbsent(roleSlug, () => {});

                        return Container(
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.bg3Dark : AppColors.bg3Light,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    role.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              if (role.kinds.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  role.kindQuestion ?? l10n.workTypes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final kind in role.kinds)
                                      FilterChip(
                                        label: Text(kind.name,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        selected:
                                            roleWorkTypes.contains(kind.slug),
                                        onSelected: (_) => setState(() {
                                          if (!roleWorkTypes
                                              .remove(kind.slug)) {
                                            roleWorkTypes.add(kind.slug);
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                              ],
                              if (role.qualifications.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  l10n.qualifications,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final q in role.qualifications)
                                      FilterChip(
                                        label: Text(q.name,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        avatar: q.isEvidence
                                            ? const Icon(
                                                Icons.upload_file_rounded,
                                                size: 14)
                                            : null,
                                        selected:
                                            roleQualifications.contains(q.slug),
                                        onSelected: (_) => setState(() {
                                          if (!roleQualifications
                                              .remove(q.slug)) {
                                            roleQualifications.add(q.slug);
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      })(),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _yearsExperience,
                            decoration:
                                InputDecoration(labelText: l10n.experience),
                            items: const [
                              DropdownMenuItem(
                                  value: '<1', child: Text('<1 year')),
                              DropdownMenuItem(
                                  value: '1-2', child: Text('1-2 years')),
                              DropdownMenuItem(
                                  value: '3-5', child: Text('3-5 years')),
                              DropdownMenuItem(
                                  value: '6-10', child: Text('6-10 years')),
                              DropdownMenuItem(
                                  value: '10+', child: Text('10+ years')),
                            ],
                            onChanged: (value) =>
                                setState(() => _yearsExperience = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _availability,
                            decoration:
                                InputDecoration(labelText: l10n.availability),
                            items: [
                              DropdownMenuItem(
                                  value: 'full_time',
                                  child: Text(l10n.fullTime)),
                              DropdownMenuItem(
                                  value: 'part_time',
                                  child: Text(l10n.partTime)),
                              DropdownMenuItem(
                                  value: 'contract',
                                  child: Text(l10n.contract)),
                              DropdownMenuItem(
                                  value: 'weekends',
                                  child: Text(l10n.weekends)),
                            ],
                            onChanged: (value) =>
                                setState(() => _availability = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: l10n.preferredLocation,
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'flexible', label: Text(l10n.flexible)),
                        ButtonSegment(
                            value: 'onsite', label: Text(l10n.onsite)),
                        ButtonSegment(
                            value: 'remote', label: Text(l10n.remote)),
                        ButtonSegment(
                            value: 'hybrid', label: Text(l10n.hybrid)),
                      ],
                      selected: {_remotePreference},
                      onSelectionChanged: (values) =>
                          setState(() => _remotePreference = values.first),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _payController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  '${l10n.expectedPay} (${widget.defaultCurrency})',
                              prefixText: '${widget.defaultCurrency} ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<String>(
                            initialValue: _payPeriod ?? 'month',
                            decoration: InputDecoration(labelText: l10n.per),
                            items: [
                              DropdownMenuItem(
                                  value: 'hour', child: Text(l10n.perHour)),
                              DropdownMenuItem(
                                  value: 'day', child: Text(l10n.perDay)),
                              DropdownMenuItem(
                                  value: 'week', child: Text(l10n.perWeek)),
                              DropdownMenuItem(
                                  value: 'month', child: Text(l10n.perMonth)),
                              DropdownMenuItem(
                                  value: 'project',
                                  child: Text(l10n.perProject)),
                            ],
                            onChanged: (value) =>
                                setState(() => _payPeriod = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.languages,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final lang in const [
                          ('en', 'English'),
                          ('lg', 'Luganda'),
                          ('sw', 'Kiswahili'),
                          ('fr', 'Français'),
                          ('rw', 'Kinyarwanda'),
                          ('ar', 'العربية'),
                        ])
                          FilterChip(
                            label: Text(lang.$2),
                            selected: _selectedLanguages.contains(lang.$1),
                            onSelected: (_) => setState(() {
                              if (!_selectedLanguages.remove(lang.$1)) {
                                _selectedLanguages.add(lang.$1);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.profileSummary,
                        hintText: 'Brief summary of your skills and background',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.saveWorkProfile),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
