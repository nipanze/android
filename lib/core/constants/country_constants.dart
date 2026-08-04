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

  final String code; // e.g. 'UG', 'KE', 'NG'
  final String name; // e.g. 'Uganda', 'Kenya'
  final String flag; // e.g. '🇺🇬'
  final String dialCode; // e.g. '+256'
  final String currency; // e.g. 'UGX'
  final String regionsLabel; // e.g. 'District', 'County', 'State'
  final List<String> regions;
  final String lenderPriceFormatted; // Charm pricing, e.g. 'UGX 19,900'
  final String proPriceFormatted; // Charm pricing, e.g. 'UGX 49,900'
}

typedef EastAfricaCountry = CountryInfo;

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

  static const CountryInfo nigeria = CountryInfo(
    code: 'NG',
    name: 'Nigeria',
    flag: '🇳🇬',
    dialCode: '+234',
    currency: 'NGN',
    regionsLabel: 'State',
    lenderPriceFormatted: 'NGN 2,900',
    proPriceFormatted: 'NGN 7,900',
    regions: [
      'Lagos',
      'Abuja (FCT)',
      'Kano',
      'Ibadan',
      'Port Harcourt',
      'Enugu',
      'Kaduna',
      'Other',
    ],
  );

  static const CountryInfo southAfrica = CountryInfo(
    code: 'ZA',
    name: 'South Africa',
    flag: '🇿🇦',
    dialCode: '+27',
    currency: 'ZAR',
    regionsLabel: 'Province',
    lenderPriceFormatted: 'ZAR 99',
    proPriceFormatted: 'ZAR 249',
    regions: [
      'Gauteng',
      'Western Cape',
      'KwaZulu-Natal',
      'Eastern Cape',
      'Free State',
      'Mpumalanga',
      'Limpopo',
      'Other',
    ],
  );

  static const CountryInfo egypt = CountryInfo(
    code: 'EG',
    name: 'Egypt',
    flag: '🇪🇬',
    dialCode: '+20',
    currency: 'EGP',
    regionsLabel: 'Governorate',
    lenderPriceFormatted: 'EGP 199',
    proPriceFormatted: 'EGP 499',
    regions: [
      'Cairo',
      'Alexandria',
      'Giza',
      'Shubra El Kheima',
      'Port Said',
      'Suez',
      'Luxor',
      'Other',
    ],
  );

  /// Exactly the 7 supported countries: Uganda, Kenya, Tanzania, Rwanda, Nigeria, South Africa, Egypt
  static const List<CountryInfo> all = [
    uganda,
    kenya,
    tanzania,
    rwanda,
    nigeria,
    southAfrica,
    egypt,
  ];

  static CountryInfo get defaultCountry => uganda;

  static const Map<String, CountryInfo> legacyDecodable = {
    'BI': CountryInfo(
      code: 'BI',
      name: 'Burundi',
      flag: '🇧🇮',
      dialCode: '+257',
      currency: 'BIF',
      regionsLabel: 'Province',
      lenderPriceFormatted: 'BIF 0',
      proPriceFormatted: 'BIF 0',
      regions: ['Other'],
    ),
    'SS': CountryInfo(
      code: 'SS',
      name: 'South Sudan',
      flag: '🇸🇸',
      dialCode: '+211',
      currency: 'SSP',
      regionsLabel: 'State',
      lenderPriceFormatted: 'SSP 0',
      proPriceFormatted: 'SSP 0',
      regions: ['Other'],
    ),
    'CD': CountryInfo(
      code: 'CD',
      name: 'DR Congo',
      flag: '🇨🇩',
      dialCode: '+243',
      currency: 'CDF',
      regionsLabel: 'Province',
      lenderPriceFormatted: 'CDF 0',
      proPriceFormatted: 'CDF 0',
      regions: ['Other'],
    ),
    'SO': CountryInfo(
      code: 'SO',
      name: 'Somalia',
      flag: '🇸🇴',
      dialCode: '+252',
      currency: 'SOS',
      regionsLabel: 'Region',
      lenderPriceFormatted: 'SOS 0',
      proPriceFormatted: 'SOS 0',
      regions: ['Other'],
    ),
  };

  static CountryInfo findByCode(String? code) {
    if (code == null || code.isEmpty) return defaultCountry;
    for (final c in all) {
      if (c.code == code) return c;
    }
    return legacyDecodable[code] ?? defaultCountry;
  }

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
