// test/features/provider/capabilities_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/provider/domain/entities/provider_capability.dart';
import 'package:nipanze/features/provider/domain/entities/provider_opportunity.dart';
import 'package:nipanze/features/provider/domain/repositories/provider_repository_interface.dart';
import 'package:nipanze/features/provider/presentation/cubit/capabilities_cubit.dart';
import 'package:nipanze/features/provider/presentation/cubit/capabilities_state.dart';
import 'package:nipanze/features/provider/presentation/widgets/capability_badge.dart';
import 'package:nipanze/features/provider/presentation/widgets/provider_opportunities_section.dart';
import 'package:nipanze/features/provider/presentation/widgets/provider_verification_chip.dart';
import 'package:nipanze/l10n/app_localizations.dart';

class MockProviderRepository extends Mock implements IProviderRepository {}

void main() {
  late MockProviderRepository mockRepo;

  setUp(() {
    mockRepo = MockProviderRepository();
  });

  group('ProviderCapability Entity', () {
    test('parses fromMap correctly for self-declared', () {
      final map = {
        'id': 'cap-1',
        'user_id': 'u-1',
        'capability_slug': 'excavator_hire',
        'verification_level': 'self_declared',
        'created_at': '2026-09-01T12:00:00Z',
        'capability_name': 'Excavator Hire',
        'category_slug': 'machinery_equipment',
        'category_name': 'Machinery & Equipment',
        'category_icon': '🚜',
      };
      final cap = ProviderCapability.fromMap(map);
      expect(cap.id, 'cap-1');
      expect(cap.userId, 'u-1');
      expect(cap.capabilitySlug, 'excavator_hire');
      expect(cap.verificationLevel, ProviderVerificationLevel.selfDeclared);
      expect(cap.isVerified, false);
      expect(cap.capabilityName, 'Excavator Hire');
      expect(cap.categoryName, 'Machinery & Equipment');
      expect(cap.categoryIcon, '🚜');
    });

    test('parses fromMap correctly for provider-verified', () {
      final map = {
        'id': 'cap-2',
        'user_id': 'u-1',
        'capability_slug': 'visa_assistance',
        'verification_level': 'provider_verified',
        'verified_by': 'admin-1',
        'verified_at': '2026-09-02T12:00:00Z',
        'created_at': '2026-09-01T12:00:00Z',
      };
      final cap = ProviderCapability.fromMap(map);
      expect(cap.verificationLevel, ProviderVerificationLevel.providerVerified);
      expect(cap.isVerified, true);
      expect(cap.verifiedBy, 'admin-1');
    });
  });

  group('ProviderOpportunity Entity', () {
    test('parses opportunityCount and open_needs_count correctly', () {
      final map1 = {
        'capability_slug': 'excavator_hire',
        'opportunity_count': 5,
        'capability_name': 'Excavator Hire',
      };
      final opp1 = ProviderOpportunity.fromMap(map1);
      expect(opp1.opportunityCount, 5);

      final map2 = {
        'capability_slug': 'heavy_haulage',
        'open_needs_count': 3,
      };
      final opp2 = ProviderOpportunity.fromMap(map2);
      expect(opp2.opportunityCount, 3);
    });
  });

  group('CapabilitiesCubit', () {
    final testCaps = [
      ProviderCapability(
        id: 'cap-1',
        userId: 'u-1',
        capabilitySlug: 'excavator_hire',
        verificationLevel: ProviderVerificationLevel.providerVerified,
        createdAt: DateTime.now(),
        capabilityName: 'Excavator Hire',
        categoryName: 'Machinery & Equipment',
        categoryIcon: '🚜',
      ),
    ];

    final testOpps = [
      const ProviderOpportunity(
        capabilitySlug: 'excavator_hire',
        opportunityCount: 3,
        capabilityName: 'Excavator Hire',
      ),
    ];

    blocTest<CapabilitiesCubit, CapabilitiesState>(
      'emits [CapabilitiesLoading, CapabilitiesLoaded] on load()',
      build: () {
        when(() => mockRepo.getProviderCapabilities())
            .thenAnswer((_) async => testCaps);
        return CapabilitiesCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CapabilitiesLoading>(),
        isA<CapabilitiesLoaded>().having((s) => s.capabilities.length, 'length', 1),
      ],
    );

    blocTest<CapabilitiesCubit, CapabilitiesState>(
      'emits [CapabilitiesLoading, CapabilitiesLoaded] with opportunities on loadWithOpportunities()',
      build: () {
        when(() => mockRepo.getProviderCapabilities())
            .thenAnswer((_) async => testCaps);
        when(() => mockRepo.getProviderOpportunities())
            .thenAnswer((_) async => testOpps);
        return CapabilitiesCubit(mockRepo);
      },
      act: (cubit) => cubit.loadWithOpportunities(),
      expect: () => [
        isA<CapabilitiesLoading>(),
        isA<CapabilitiesLoaded>()
            .having((s) => s.capabilities.length, 'capabilities', 1)
            .having((s) => s.opportunities.length, 'opportunities', 1),
      ],
    );

    blocTest<CapabilitiesCubit, CapabilitiesState>(
      'addCapabilities calls repo then reloads',
      build: () {
        when(() => mockRepo.addCapabilities(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getProviderCapabilities())
            .thenAnswer((_) async => testCaps);
        return CapabilitiesCubit(mockRepo);
      },
      act: (cubit) => cubit.addCapabilities(['excavator_hire']),
      verify: (_) {
        verify(() => mockRepo.addCapabilities(['excavator_hire'])).called(1);
      },
    );

    blocTest<CapabilitiesCubit, CapabilitiesState>(
      'removeCapability calls repo then reloads',
      build: () {
        when(() => mockRepo.removeCapability(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getProviderCapabilities())
            .thenAnswer((_) async => []);
        return CapabilitiesCubit(mockRepo);
      },
      act: (cubit) => cubit.removeCapability('excavator_hire'),
      verify: (_) {
        verify(() => mockRepo.removeCapability('excavator_hire')).called(1);
      },
    );
  });

  group('Provider Widgets', () {
    Widget createLocalizedWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    testWidgets('ProviderVerificationChip renders verified state', (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        const ProviderVerificationChip(
          level: ProviderVerificationLevel.providerVerified,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Provider Verified'), findsOneWidget);
    });

    testWidgets('ProviderVerificationChip renders self-declared state', (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        const ProviderVerificationChip(
          level: ProviderVerificationLevel.selfDeclared,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Self-declared'), findsOneWidget);
    });

    testWidgets('CapabilityBadge renders capability details and chip', (tester) async {
      final cap = ProviderCapability(
        id: 'cap-1',
        userId: 'u-1',
        capabilitySlug: 'excavator_hire',
        verificationLevel: ProviderVerificationLevel.providerVerified,
        createdAt: DateTime.now(),
        capabilityName: 'Excavator Hire',
        categoryName: 'Machinery & Equipment',
        categoryIcon: '🚜',
      );

      await tester.pumpWidget(createLocalizedWidget(
        CapabilityBadge(
          capability: cap,
          opportunityCount: 4,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Excavator Hire'), findsOneWidget);
      expect(find.text('Machinery & Equipment'), findsOneWidget);
      expect(find.text('🚜'), findsOneWidget);
      expect(find.text('Provider Verified'), findsOneWidget);
      expect(find.text('4 opportunities'), findsOneWidget);
    });

    testWidgets('ProviderOpportunitiesSection renders opportunities', (tester) async {
      final opps = [
        const ProviderOpportunity(
          capabilitySlug: 'excavator_hire',
          opportunityCount: 3,
          capabilityName: 'Excavator Hire',
          categoryIcon: '🚜',
        ),
        const ProviderOpportunity(
          capabilitySlug: 'heavy_haulage',
          opportunityCount: 2,
          capabilityName: 'Heavy Haulage',
          categoryIcon: '🚚',
        ),
      ];

      await tester.pumpWidget(createLocalizedWidget(
        ProviderOpportunitiesSection(opportunities: opps),
      ));
      await tester.pumpAndSettle();

      expect(find.text('People are looking for what you provide'), findsOneWidget);
      expect(find.text('Excavator Hire'), findsOneWidget);
      expect(find.text('3 opportunities'), findsOneWidget);
      expect(find.text('Heavy Haulage'), findsOneWidget);
      expect(find.text('2 opportunities'), findsOneWidget);
    });
  });
}
