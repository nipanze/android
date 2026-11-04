import 'package:flutter/material.dart';

import '../../domain/entities/provider_capability.dart';

/// A standalone service driven filter panel for provider listings.
///
/// Pass the provider's active service capabilities to build the tabs. The
/// options shown below the tabs are generated for the selected service family.
/// This is a new artifact and does not change the existing marketplace sheet.
class ProviderServiceFilterPanel extends StatefulWidget {
  const ProviderServiceFilterPanel({
    super.key,
    required this.services,
    this.onChanged,
  });

  final List<ProviderCapability> services;
  final ValueChanged<ProviderServiceFilterSelection>? onChanged;

  @override
  State<ProviderServiceFilterPanel> createState() =>
      _ProviderServiceFilterPanelState();
}

class ProviderServiceFilterSelection {
  const ProviderServiceFilterSelection({
    this.serviceSlug,
    this.options = const {},
  });

  final String? serviceSlug;
  final Map<String, String> options;
}

class _ProviderServiceFilterPanelState
    extends State<ProviderServiceFilterPanel> {
  int _selectedIndex = 0;
  final Map<String, String> _selectedOptions = {};

  List<ProviderCapability> get _services => widget.services
      .where((service) =>
          service.isService && service.isActive && !service.isPaused)
      .toList();

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services.isEmpty) {
      return const Center(child: Text('No provider services available'));
    }
    final index = _selectedIndex.clamp(0, services.length - 1);
    final service = services[index];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = i == index;
              return ChoiceChip(
                label: Text(_serviceName(services[i])),
                selected: selected,
                onSelected: (_) => setState(() => _selectedIndex = i),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ..._filterGroups(service).map((group) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _FilterGroup(
                title: group.title,
                hint: group.hint,
                options: group.options,
                selected: _selectedOptions[group.key],
                onSelected: (value) {
                  setState(() {
                    if (_selectedOptions[group.key] == value) {
                      _selectedOptions.remove(group.key);
                    } else {
                      _selectedOptions[group.key] = value;
                    }
                  });
                  widget.onChanged?.call(ProviderServiceFilterSelection(
                    serviceSlug: service.capabilitySlug,
                    options: Map.unmodifiable(_selectedOptions),
                  ));
                },
              ),
            )),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _selectedOptions['verified'] == 'true',
              onChanged: (value) {
                setState(() => _selectedOptions['verified'] = '$value');
                widget.onChanged?.call(ProviderServiceFilterSelection(
                  serviceSlug: service.capabilitySlug,
                  options: Map.unmodifiable(_selectedOptions),
                ));
              },
              title: const Text('Verified provider',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: const Text('Only approved provider profiles',
                  style: TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  String _serviceName(ProviderCapability service) =>
      service.capabilityName?.trim().isNotEmpty == true
          ? service.capabilityName!.trim()
          : service.categoryName?.trim().isNotEmpty == true
              ? service.categoryName!.trim()
              : service.capabilitySlug.replaceAll('_', ' ');

  List<_FilterGroupData> _filterGroups(ProviderCapability service) {
    final slug =
        '${service.capabilitySlug} ${service.categorySlug ?? ''}'.toLowerCase();
    if (slug.contains('cargo') ||
        slug.contains('transport') ||
        slug.contains('logistic')) {
      return const [
        _FilterGroupData(
            'budget',
            'Budget',
            'Brackets only. Exact amounts stay private',
            ['Under 500K', '500K–2M', '2M–10M', 'Over 10M']),
        _FilterGroupData('pickup', 'Pickup area', 'Where the load starts',
            ['Central', 'Eastern', 'Western', 'Northern', 'Kampala', 'More']),
        _FilterGroupData('when', 'When', 'How soon it is needed',
            ['Urgent', 'This week', 'Flexible']),
        _FilterGroupData('load', 'Load size', 'What you can carry',
            ['Parcels', 'Pallets', 'Half truck', 'Full truck']),
        _FilterGroupData('distance', 'Distance', 'How far the trip goes',
            ['Within town', 'Upcountry', 'Cross-border']),
      ];
    }
    if (slug.contains('equipment') || slug.contains('machinery')) {
      return const [
        _FilterGroupData('budget', 'Budget', 'Choose a service budget',
            ['Under 500K', '500K–2M', '2M–10M', 'Over 10M']),
        _FilterGroupData('equipment', 'Equipment type', 'What is available',
            ['Earthmoving', 'Lifting', 'Power', 'Farm equipment', 'Other']),
        _FilterGroupData('duration', 'Hire duration', 'How long it is needed',
            ['Hourly', 'Daily', 'Weekly', 'Monthly']),
        _FilterGroupData('delivery', 'Delivery', 'Equipment handover',
            ['Provider delivers', 'Customer collects']),
      ];
    }
    if (slug.contains('business') ||
        slug.contains('registration') ||
        slug.contains('legal')) {
      return const [
        _FilterGroupData('budget', 'Budget', 'Choose a service budget',
            ['Under 100K', '100K–500K', '500K–2M', 'Over 2M']),
        _FilterGroupData('service', 'Service type', 'What help is needed', [
          'Registration',
          'Licensing',
          'Tax setup',
          'Compliance',
          'Consultation'
        ]),
        _FilterGroupData('location', 'Location', 'Where support is needed',
            ['Central', 'Eastern', 'Western', 'Northern', 'Remote']),
        _FilterGroupData('when', 'When', 'How soon it is needed',
            ['Urgent', 'This week', 'Flexible']),
      ];
    }
    return const [
      _FilterGroupData('budget', 'Budget', 'Choose a service budget',
          ['Under 100K', '100K–500K', '500K–2M', 'Over 2M']),
      _FilterGroupData('location', 'Location', 'Where the service is needed',
          ['Central', 'Eastern', 'Western', 'Northern', 'Remote']),
      _FilterGroupData('when', 'When', 'How soon it is needed',
          ['Urgent', 'This week', 'Flexible']),
    ];
  }
}

class _FilterGroupData {
  const _FilterGroupData(this.key, this.title, this.hint, this.options);
  final String key;
  final String title;
  final String hint;
  final List<String> options;
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String hint;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(hint,
              style:
                  TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options
                .map((option) => ChoiceChip(
                      label: Text(option),
                      selected: selected == option,
                      onSelected: (_) => onSelected(option),
                    ))
                .toList(),
          ),
        ],
      );
}
