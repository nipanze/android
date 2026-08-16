// lib/features/auth/presentation/pages/register/country_sheet.dart

import 'package:flutter/material.dart';


import '../../../../../core/constants/country_constants.dart';
import '../../../../../core/theme/app_theme.dart';

class CountrySheet extends StatefulWidget {
  const CountrySheet({super.key});

  @override
  State<CountrySheet> createState() => CountrySheetState();
}

class CountrySheetState extends State<CountrySheet> {
  String _query = '';

  List<CountryInfo> get _filtered => EastAfricaCountries.all
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.dialCode.contains(_query) ||
          c.code.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Select Country',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search country…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    return ListTile(
                      leading:
                          Text(c.flag, style: const TextStyle(fontSize: 26)),
                      title: Text(c.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      subtitle:
                          Text(c.dialCode, style: theme.textTheme.bodySmall),
                      trailing: Text(c.currency,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.of(context).pop(c),
                    );
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
