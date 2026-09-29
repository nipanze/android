enum NeedFieldType { text, number, date, boolean }

class NeedFormField {
  const NeedFormField({
    required this.key,
    required this.label,
    required this.hint,
    this.type = NeedFieldType.text,
    this.isRequired = true,
  });

  const NeedFormField.text(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.text;

  const NeedFormField.number(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.number;

  const NeedFormField.date(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.date;

  const NeedFormField.boolean(
    this.key, {
    required this.label,
    this.hint = '',
    this.isRequired = false,
  }) : type = NeedFieldType.boolean;

  final String key;
  final String label;
  final String hint;
  final NeedFieldType type;
  final bool isRequired;
}

class NeedFormSchema {
  static const Map<String, List<NeedFormField>> categoryFields = {
    'travel_international': [
      NeedFormField.text(
        'destination',
        label: 'Destination country / city',
        hint: 'e.g. Dubai, UAE or London, UK',
      ),
      NeedFormField.text(
        'travel_date',
        label: 'Intended travel date or month',
        hint: 'e.g. December 2026',
      ),
      NeedFormField.number(
        'travellers',
        label: 'Number of travellers',
        hint: 'e.g. 1',
      ),
    ],
    'machinery_equipment': [
      NeedFormField.text(
        'equipment_type',
        label: 'Equipment model or type',
        hint: 'e.g. CAT 320 Excavator, 50kVA Generator',
      ),
      NeedFormField.number(
        'duration_days',
        label: 'Duration (days or months)',
        hint: 'e.g. 30',
      ),
      NeedFormField.boolean(
        'operator_needed',
        label: 'Machine operator required',
      ),
    ],
    'professional_services': [
      NeedFormField.text(
        'service_type',
        label: 'Specialist service required',
        hint: 'e.g. Company tax audit, Patent filing',
      ),
      NeedFormField.text(
        'deadline',
        label: 'Target deadline or timeline',
        hint: 'e.g. End of next month',
      ),
      NeedFormField.text(
        'deliverable',
        label: 'Expected output / deliverable',
        hint: 'e.g. Signed URA audit report',
      ),
    ],
    'transport_logistics': [
      NeedFormField.text(
        'from_location',
        label: 'Pickup location',
        hint: 'e.g. Kampala Industrial Area',
      ),
      NeedFormField.text(
        'to_location',
        label: 'Dropoff destination',
        hint: 'e.g. Gulu Town',
      ),
      NeedFormField.text(
        'load_description',
        label: 'Cargo / weight description',
        hint: 'e.g. 20 tonnes of bagged cement',
      ),
    ],
    'specialized_products': [
      NeedFormField.text(
        'product_name',
        label: 'Exact product / part name',
        hint: 'e.g. 50 Epson L3150 printers',
      ),
      NeedFormField.text(
        'quantity',
        label: 'Quantity or volume',
        hint: 'e.g. 50 units',
      ),
      NeedFormField.text(
        'delivery_location',
        label: 'Delivery destination',
        hint: 'e.g. Mbarara warehouse',
      ),
    ],
  };

  static List<NeedFormField> fieldsForCategory(String slug) {
    return categoryFields[slug] ??
        const [
          NeedFormField.text(
            'details_note',
            label: 'Additional specifics',
            hint: 'Describe any specific requirements',
            isRequired: false,
          ),
        ];
  }
}
