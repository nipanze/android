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
  testWidgets('company name is required and representative switch previews it',
      (tester) async {
    Map<String, dynamic>? presentation;
    await tester.pumpWidget(_localizedApp(
      ProviderTypeStep(
        selected: ProviderCategoryType.company,
        saving: false,
        error: null,
        onSelect: (_) {},
        onContinue: () {},
        initialDisplayName: '',
        initialRepresentativeName: '',
        categoryName: 'Transport & Logistics',
        initialDisplayMode: 'company',
        representativeAuthorized: false,
        isCurrent: false,
        onPresentationChanged: (value) => presentation = value,
      ),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();

    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);
    expect(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator).first)
          .decoration
          .helperText,
      'Required. Enter your company or business name.',
    );

    await tester.enterText(find.byType(TextFormField).first, 'Acme Services');
    await tester.pump();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(presentation?['display_mode'], 'company_with_representative');
    await tester.enterText(find.byType(TextFormField).last, 'Amina');
    await tester.pump();
    expect(find.text('Represented by Amina'), findsOneWidget);
    expect(find.text('Transport & Logistics'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Continue'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('company details shows name read-only and Edit returns to B2',
      (tester) async {
    var editTapped = false;
    await tester.pumpWidget(_localizedApp(
      CompanyDetailsStep(
        categorySlug: 'transport_logistics',
        serviceCount: 2,
        roleCount: 1,
        initialProfile: const ProviderCompanyProfile(
          categorySlug: 'transport_logistics',
          companyName: 'Acme Services',
        ),
        companyName: 'Acme Services',
        providerRepository: _ProviderRepositoryStub(),
        onDraftChanged: (_) {},
        onSave: ({required profile}) async {},
        onEditCompanyName: () => editTapped = true,
      ),
    ));

    expect(find.text('Acme Services'), findsOneWidget);
    expect(find.text('Company name from the previous step'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Acme Services'), findsNothing);
    await tester.tap(find.text('Edit'));
    expect(editTapped, isTrue);
  });
}
