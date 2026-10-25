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
  testWidgets('company name can be entered before reviewing an identity switch',
      (tester) async {
    var companyName = '';
    var continued = false;
    await tester.pumpWidget(_localizedApp(
      ProviderTypeStep(
        selected: ProviderCategoryType.company,
        saving: false,
        error: null,
        onSelect: (_) {},
        onContinue: () => continued = true,
        initialDisplayName: '',
        companyPreviewName: '',
        categoryName: 'Transport & Logistics',
        currentType: ProviderCategoryType.individual,
        onCompanyNameChanged: (value) => companyName = value,
      ),
    ));
    await tester.enterText(
      find.byKey(const ValueKey('provider-company-display-name')),
      'Acme Services',
    );
    await tester.pump();

    expect(companyName, 'Acme Services');
    expect(find.text('Transport & Logistics'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    expect(continued, isTrue);
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
