// lib/core/constants/country_constants.dart

class CountryInfo {
  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.currency,
    required this.regionsLabel,
    required this.regions,
    required this.lenderPriceFormatted,
    required this.proPriceFormatted,
  });

  final String code;                  // e.g. 'UG', 'KE'
  final String name;                  // e.g. 'Uganda', 'Kenya'
  final String flag;                  // e.g. '🇺🇬'
  final String dialCode;              // e.g. '+256'
  final String currency;              // e.g. 'UGX'
  final String regionsLabel;          // e.g. 'District', 'County'
  final List<String> regions;
  final String lenderPriceFormatted;  // Charm pricing, e.g. 'UGX 19,900'
  final String proPriceFormatted;     // Charm pricing, e.g. 'UGX 49,900'
}

class EastAfricaCountries {
  EastAfricaCountries._();

  static const CountryInfo uganda = CountryInfo(
    code: 'UG',
    name: 'Uganda',
    flag: '🇺🇬',
    dialCode: '+256',
    currency: 'UGX',
    regionsLabel: 'District',
    lenderPriceFormatted: 'UGX 19,900',
    proPriceFormatted: 'UGX 49,900',
    regions: [
      'Central',
      'Eastern',
      'Western',
      'Northern',
      'Kampala',
      'Wakiso',
      'Mukono',
      'Jinja',
      'Mbale',
      'Gulu',
      'Mbarara',
      'Masaka',
      'Lira',
      'Soroti',
      'Arua',
      'Fort Portal',
      'Kabale',
      'Other',
    ],
  );

  static const CountryInfo kenya = CountryInfo(
    code: 'KE',
    name: 'Kenya',
    flag: '🇰🇪',
    dialCode: '+254',
    currency: 'KES',
    regionsLabel: 'County',
    lenderPriceFormatted: 'KES 690',
    proPriceFormatted: 'KES 1,790',
    regions: [
      'Nairobi',
      'Mombasa',
      'Kisumu',
      'Nakuru',
      'Eldoret',
      'Kiambu',
      'Machakos',
      'Other',
    ],
  );

  static const CountryInfo tanzania = CountryInfo(
    code: 'TZ',
    name: 'Tanzania',
    flag: '🇹🇿',
    dialCode: '+255',
    currency: 'TZS',
    regionsLabel: 'Region',
    lenderPriceFormatted: 'TZS 12,900',
    proPriceFormatted: 'TZS 32,900',
    regions: [
      'Dar es Salaam',
      'Dodoma',
      'Arusha',
      'Mwanza',
      'Zanzibar',
      'Kilimanjaro',
      'Other',
    ],
  );

  static const CountryInfo rwanda = CountryInfo(
    code: 'RW',
    name: 'Rwanda',
    flag: '🇷🇼',
    dialCode: '+250',
    currency: 'RWF',
    regionsLabel: 'Province / District',
    lenderPriceFormatted: 'RWF 6,900',
    proPriceFormatted: 'RWF 17,900',
    regions: [
      'Kigali',
      'Northern Province',
      'Southern Province',
      'Eastern Province',
      'Western Province',
      'Other',
    ],
  );

  static const CountryInfo southSudan = CountryInfo(
    code: 'SS',
    name: 'South Sudan',
    flag: '🇸🇸',
    dialCode: '+211',
    currency: 'SSP',
    regionsLabel: 'State',
    lenderPriceFormatted: 'SSP 7,900',
    proPriceFormatted: 'SSP 19,900',
    regions: [
      'Juba (Central Equatoria)',
      'Upper Nile',
      'Jonglei',
      'Unity',
      'Western Equatoria',
      'Eastern Equatoria',
      'Other',
    ],
  );

  static const CountryInfo burundi = CountryInfo(
    code: 'BI',
    name: 'Burundi',
    flag: '🇧🇮',
    dialCode: '+257',
    currency: 'BIF',
    regionsLabel: 'Province',
    lenderPriceFormatted: 'BIF 15,900',
    proPriceFormatted: 'BIF 39,900',
    regions: [
      'Bujumbura',
      'Gitega',
      'Ngozi',
      'Rumonge',
      'Other',
    ],
  );

  static const List<CountryInfo> all = [
    uganda,
    kenya,
    tanzania,
    rwanda,
    southSudan,
    burundi,
  ];

  static CountryInfo get defaultCountry => uganda;

  /// Tries to match phone number prefix to country or defaults to Uganda.
  static CountryInfo findByPhone(String? phone) {
    if (phone == null || phone.isEmpty) return defaultCountry;
    final clean = phone.trim();
    for (final c in all) {
      if (clean.startsWith(c.dialCode)) return c;
    }
    return defaultCountry;
  }
}
