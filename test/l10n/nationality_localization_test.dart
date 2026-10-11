import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/l10n/app_localizations_ar.dart';
import 'package:nipanze/l10n/app_localizations_en.dart';
import 'package:nipanze/l10n/app_localizations_fr.dart';
import 'package:nipanze/l10n/app_localizations_rw.dart';
import 'package:nipanze/l10n/app_localizations_sw.dart';

void main() {
  test('traveler nationalities are translated for every supported locale', () {
    expect(AppLocalizationsEn().nationalityUgandan, 'Ugandan');
    expect(AppLocalizationsFr().nationalityUgandan, 'Ougandais');
    expect(AppLocalizationsSw().nationalityUgandan, 'Muganda');
    expect(AppLocalizationsRw().nationalityUgandan, 'Umunya-Uganda');
    expect(AppLocalizationsAr().nationalityUgandan, 'أوغندي');

    for (final l10n in [
      AppLocalizationsEn(),
      AppLocalizationsFr(),
      AppLocalizationsSw(),
      AppLocalizationsRw(),
      AppLocalizationsAr(),
    ]) {
      expect(l10n.nationalityCongoleseDrc, isNotEmpty);
      expect(l10n.nationalitySouthSudanese, isNotEmpty);
      expect(l10n.nationalitySouthAfrican, isNotEmpty);
    }
  });
}
