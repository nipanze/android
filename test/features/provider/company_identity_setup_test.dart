import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/provider/domain/entities/provider_category_type.dart';
import 'package:nipanze/features/provider/domain/entities/provider_company_profile.dart';
import 'package:nipanze/features/provider/domain/repositories/provider_repository_interface.dart';
import 'package:nipanze/features/provider/presentation/pages/add_service_sheet.dart';
import 'package:nipanze/features/provider/presentation/widgets/company_details_step.dart';
import 'package:nipanze/l10n/app_localizations.dart';

Widget _localizedApp(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 390, height: 820, child: child)),
    );

class _ProviderRepositoryStub implements IProviderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('company name is shown as a read-only identity preview',
      (tester) async {
    var continued = false;
    await tester.pumpWidget(_localizedApp(
      ProviderTypeStep(
        selected: ProviderCategoryType.company,
        saving: false,
        error: null,
        onSelect: (_) {},
        onContinue: () => continued = true,
        initialDisplayName: '',
        companyPreviewName: 'Acme Services',
        categoryName: 'Transport & Logistics',
        currentType: ProviderCategoryType.individual,
      ),
    ));

    expect(find.text('Acme Services'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Transport & Logistics'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    expect(continued, isTrue);
  });

  testWidgets('company details edits its required name and previews a rep',
      (tester) async {
    Map<String, dynamic>? presentation;
    Map<String, dynamic>? savedProfile;
    await tester.pumpWidget(_localizedApp(
      CompanyDetailsStep(
        categorySlug: 'transport_logistics',
        serviceCount: 2,
        roleCount: 1,
        initialProfile: const ProviderCompanyProfile(
          categorySlug: 'transport_logistics',
          companyName: 'Acme Services',
        ),
        companyName: '',
        presentation: const {},
        providerRepository: _ProviderRepositoryStub(),
        onDraftChanged: (_) {},
        onPresentationChanged: (value) => presentation = value,
        onSave: ({
          required profile,
          Uint8List? logoBytes,
          String? logoFileName,
        }) async {
          savedProfile = profile;
        },
      ),
    ));

    expect(find.byType(TextFormField), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField).first);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Acme Services',
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Acme Services Ltd',
    );
    await tester.pump();
    expect(presentation?['display_name'], 'Acme Services Ltd');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'Amina');
    await tester.pump();
    expect(presentation?['display_mode'], 'company_with_representative');
    expect(find.text('Represented by Amina'), findsOneWidget);
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save company profile'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save company profile'));
    await tester.pump();
    expect(savedProfile?['company_name'], 'Acme Services Ltd');
  });

  testWidgets(
      'IdentitySwitchConfirmStep matches redesigned layout with transition chips, Kept safe, and What changes',
      (tester) async {
    var continued = false;
    var cancelled = false;

    await tester.pumpWidget(_localizedApp(
      IdentitySwitchConfirmStep(
        categoryName: 'Construction & Building',
        from: ProviderCategoryType.individual,
        to: ProviderCategoryType.company,
        pendingOffers: 0,
        onContinue: () => continued = true,
        onCancel: () => cancelled = true,
      ),
    ));

    // Badge and title
    expect(find.text('SWITCHING IN THIS CATEGORY'), findsOneWidget);
    expect(find.text('Switch to Company / Organization?'), findsOneWidget);
    expect(
        find.text(
            'Only Construction & Building changes. Your other categories stay exactly as they are.'),
        findsOneWidget);

    // Visual Transition Chips
    expect(find.text('Individual'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    // Kept safe section
    expect(find.text('Kept safe'), findsOneWidget);
    expect(find.text('Your service information. Nothing is deleted.'),
        findsOneWidget);
    expect(find.text('Accepted deals, reviews and history.'), findsOneWidget);
    expect(find.text('Your personal job roles stay active.'), findsOneWidget);
    expect(find.byIcon(Icons.gpp_good_outlined), findsOneWidget);

    // What changes section
    expect(find.text('What changes'), findsOneWidget);
    expect(
        find.text(
            'Your Individual services here become inactive. You can restore them later.'),
        findsOneWidget);
    expect(find.text('New offers will use your Company identity.'),
        findsOneWidget);
    expect(
        find.text(
            'Verification may be asked again. It does not carry over between identities.'),
        findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);

    // Action buttons
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    expect(continued, isTrue);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets(
      'IdentitySwitchConfirmStep renders in dark theme without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 820,
            child: IdentitySwitchConfirmStep(
              categoryName: 'Construction & Building',
              from: ProviderCategoryType.individual,
              to: ProviderCategoryType.company,
              pendingOffers: 2,
              onContinue: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('SWITCHING IN THIS CATEGORY'), findsOneWidget);
    expect(find.text('Kept safe'), findsOneWidget);
    expect(find.text('What changes'), findsOneWidget);
    expect(
        find.text(
            'You have 2 pending offers. They stay as sent; you can withdraw them yourself.'),
        findsOneWidget);
  });

  testWidgets('IdentitySwitchConfirmStep renders in Swahili and Arabic',
      (tester) async {
    for (final locale in [const Locale('sw'), const Locale('ar')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 820,
              child: IdentitySwitchConfirmStep(
                categoryName: 'Construction & Building',
                from: ProviderCategoryType.individual,
                to: ProviderCategoryType.company,
                pendingOffers: 0,
                onContinue: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      if (locale.languageCode == 'sw') {
        expect(find.text('KUBADILISHA KATIKA KATEGORIA HII'), findsOneWidget);
        expect(find.text('Vilivyolindwa'), findsOneWidget);
        expect(find.text('Kinachobadilika'), findsOneWidget);
        expect(find.text('Kampuni'), findsOneWidget);
        expect(find.text('Mtu binafsi'), findsOneWidget);
      } else {
        expect(find.text('التبديل في هذا القسم'), findsOneWidget);
        expect(find.text('محفوظ بأمان'), findsOneWidget);
        expect(find.text('ما الذي يتغير'), findsOneWidget);
        expect(find.text('شركة'), findsOneWidget);
        expect(find.text('فرد'), findsOneWidget);
      }
    }
  });
}
