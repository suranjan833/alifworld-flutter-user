class CountryModel {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryModel({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  static const List<CountryModel> defaultCountries = [
    CountryModel(
      name: 'Bangladesh',
      code: 'BD',
      dialCode: '+880',
      flag: '🇧🇩',
    ),
    CountryModel(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryModel(
      name: 'United Arab Emirates',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
    ),
    CountryModel(
      name: 'Saudi Arabia',
      code: 'SA',
      dialCode: '+966',
      flag: '🇸🇦',
    ),
    CountryModel(
      name: 'United States',
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
    ),
    CountryModel(
      name: 'United Kingdom',
      code: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
    ),
    CountryModel(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    CountryModel(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
    CountryModel(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
    CountryModel(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
    CountryModel(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    CountryModel(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryModel(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryModel(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryModel(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  ];
}
