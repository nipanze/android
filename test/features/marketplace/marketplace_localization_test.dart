import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/l10n/app_localizations.dart';

void main() {
  test('marketplace labels are translated for every supported language',
      () async {
    for (final languageCode in ['rw', 'fr', 'sw', 'ar']) {
      final localizations =
          await AppLocalizations.delegate.load(Locale(languageCode));

      expect(localizations.termLabel, isNot('Term'), reason: languageCode);
      expect(localizations.loanTypeLabel, isNot('Loan type'),
          reason: languageCode);
      expect(localizations.aboutRequest, isNot('About the request'),
          reason: languageCode);
      expect(localizations.notSpecified, isNot('Not specified'),
          reason: languageCode);
      expect(localizations.forexHoldLabel, isNot('I hold'),
          reason: languageCode);
      expect(localizations.forexNeedLabel, isNot('I need'),
          reason: languageCode);
      expect(localizations.nearbyLabel, isNot('Nearby'),
          reason: languageCode);
      expect(localizations.offersCount(2), isNot('2 offers'),
          reason: languageCode);
    }
  });
}
