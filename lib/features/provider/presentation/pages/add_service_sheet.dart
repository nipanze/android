// lib/features/provider/presentation/pages/add_service_sheet.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';

/// Bottom sheet for adding provider capabilities.
/// Returns `List<String>` of selected slugs, or null if dismissed.
class AddServiceSheet extends StatefulWidget {
  const AddServiceSheet({
    super.key,
    required this.existingSlugs,
    this.preselectedCategorySlug,
    required this.needsRepository,
  });

  final Set<String> existingSlugs;
  final String? preselectedCategorySlug;
  final NeedsRepository needsRepository;

  static Future<List<String>?> show(
    BuildContext context, {
    required Set<String> existingSlugs,
    required NeedsRepository needsRepository,
    String? preselectedCategorySlug,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddServiceSheet(
        existingSlugs: existingSlugs,
        preselectedCategorySlug: preselectedCategorySlug,
        needsRepository: needsRepository,
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
  List<NeedCapability> _capabilities = [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

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
      _loading = true;
    });
    final caps = await widget.needsRepository
        .getCapabilities(categorySlug: cat.slug);
    if (!mounted) return;
    setState(() {
      _capabilities = caps;
      _loading = false;
      _step = 1;
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
                        onTap: () => setState(() => _step = 0),
                        child: Icon(Icons.arrow_back_rounded,
                            color: text2, size: 22),
                      ),
                    if (_step == 1) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _step == 0
                            ? l10n.chooseCategory
                            : (_selectedCategory?.name ?? l10n.chooseCapabilities),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_step == 1 && _selected.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selected.toList()),
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
                        : _CapabilityList(
                            capabilities: _capabilities,
                            existingSlugs: widget.existingSlugs,
                            selected: _selected,
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
    required this.onToggle,
  });

  final List<NeedCapability> capabilities;
  final Set<String> existingSlugs;
  final Set<String> selected;
  final ScrollController scrollController;
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
