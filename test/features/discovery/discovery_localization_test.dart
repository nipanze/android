import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/l10n/app_localizations.dart';

void main() {
  test('discovery and saved-plan copy follows each supported locale', () async {
    final localizedQuestions = <String, String>{
      'en':
          'Do you need equipment, logistics, procurement, or business services soon?',
      'fr':
          "Avez-vous bientôt besoin d'équipement, de logistique, d'approvisionnement ou de services aux entreprises ?",
      'sw':
          'Je, utahitaji vifaa, usafirishaji, manunuzi au huduma za biashara hivi karibuni?',
      'rw':
          "Ese vuba aha uzakenera ibikoresho, ubwikorezi, kugura ibicuruzwa cyangwa serivisi z'ubucuruzi?",
      'ar':
          'هل ستحتاج قريبًا إلى معدات أو خدمات لوجستية أو مشتريات أو خدمات للأعمال؟',
    };
    final localizedEmptyStates = <String, String>{
      'en': 'No saved plans yet',
      'fr': 'Aucun projet enregistré',
      'sw': 'Bado hakuna mipango iliyohifadhiwa',
      'rw': 'Nta migambi wabika',
      'ar': 'لا توجد خطط محفوظة بعد',
    };

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.discoveryBusinessQuestion,
          localizedQuestions[locale.languageCode]);
      expect(
          l10n.savedPlansEmptyTitle, localizedEmptyStates[locale.languageCode]);
    }
  });
}
