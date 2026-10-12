// test/features/provider/capabilities_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/core/di/injection.dart';
import 'package:nipanze/features/account/data/profile_repository.dart';
import 'package:nipanze/features/account/domain/models/user_profile.dart';
import 'package:nipanze/features/account/presentation/cubit/profile_cubit.dart';
import 'package:nipanze/features/needs/data/needs_repository.dart';
import 'package:nipanze/features/needs/domain/models/need_capability.dart';
import 'package:nipanze/features/needs/domain/models/need_category.dart';
import 'package:nipanze/features/provider/domain/entities/provider_capability.dart';
import 'package:nipanze/features/provider/domain/entities/provider_opportunity.dart';
import 'package:nipanze/features/provider/domain/repositories/provider_repository_interface.dart';
import 'package:nipanze/features/provider/presentation/cubit/capabilities_cubit.dart';
import 'package:nipanze/features/provider/presentation/cubit/capabilities_state.dart';
import 'package:nipanze/features/provider/presentation/pages/provider_services_page.dart';
import 'package:nipanze/features/provider/presentation/widgets/capability_badge.dart';
import 'package:nipanze/features/provider/presentation/widgets/provider_opportunities_section.dart';
import 'package:nipanze/features/provider/presentation/widgets/provider_verification_chip.dart';
import 'package:nipanze/l10n/app_localizations.dart';

class MockProviderRepository extends Mock implements IProviderRepository {}

class MockNeedsRepository extends Mock implements NeedsRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProviderRepository mockRepo;

  setUp(() {
    mockRepo = MockProviderRepository();
    when(() => mockRepo.capabilityProfilesEnabled())
        .thenAnswer((_) async => false);
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

    group('NeedCapability provider catalog fields', () {
      test('parses Provider Services v2 group and ordering metadata', () {
        final capability = NeedCapability.fromMap({
          'slug': 'software_development',
          'category_slug': 'technology_digital',
          'name': 'Software Development',
          'is_active': true,
          'ui_group_slug': 'technology_digital',
          'service_group_slug': 'build',
          'service_group_name': 'Build',
          'service_sort_order': 10,
        });

        expect(capability.uiGroupSlug, 'technology_digital');
        expect(capability.serviceGroupSlug, 'build');
        expect(capability.serviceGroupName, 'Build');
        expect(capability.serviceSortOrder, 10);
      });
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

    test('parses independently reviewed role qualifications', () {
      final cap = ProviderCapability.fromMap({
        'id': 'cap-3',
        'user_id': 'u-1',
        'capability_slug': 'software_development',
        'verification_level': 'self_declared',
        'created_at': '2026-09-01T12:00:00Z',
        'role_qualification_claims': [
          {
            'role_slug': 'developer',
            'qualification_slug': 'portfolio_or_github_link',
            'qualification_name': 'Portfolio or GitHub link',
            'status': 'verified',
            'has_evidence': true,
          },
          {
            'role_slug': 'developer',
            'qualification_slug': 'cloud_certification_aws_azure_gcp',
            'qualification_name': 'Cloud certification (AWS/Azure/GCP)',
            'status': 'pending_review',
            'has_evidence': true,
          },
        ],
      });

      expect(cap.status, ProviderCapabilityStatus.selfDeclared);
      expect(cap.isVerified, isFalse);
      expect(cap.roleQualificationClaims, hasLength(2));
      expect(cap.roleQualificationClaims.first['status'], 'verified');
      expect(cap.roleQualificationClaims.last['status'], 'pending_review');
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
        isA<CapabilitiesLoaded>()
            .having((s) => s.capabilities.length, 'length', 1),
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
      'keeps loaded services visible when refresh fails',
      build: () {
        var loadCount = 0;
        when(() => mockRepo.getProviderCapabilities()).thenAnswer((_) async {
          if (loadCount++ == 0) return testCaps;
          throw Exception('offline');
        });
        when(() => mockRepo.getProviderOpportunities())
            .thenAnswer((_) async => testOpps);
        return CapabilitiesCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.loadWithOpportunities();
        await cubit.loadWithOpportunities();
      },
      expect: () => [
        isA<CapabilitiesLoading>(),
        isA<CapabilitiesLoaded>()
            .having((s) => s.capabilities.length, 'capability count', 1),
      ],
    );

    blocTest<CapabilitiesCubit, CapabilitiesState>(
      'addCapabilities calls repo then reloads',
      build: () {
        when(() => mockRepo.addCapabilities(any())).thenAnswer((_) async {});
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
        when(() => mockRepo.removeCapability(any())).thenAnswer((_) async {});
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

  group('Provider Services flow', () {
    testWidgets('Offer Services tab shows categories inline', (tester) async {
      final mockProviderRepo = MockProviderRepository();
      final mockNeedsRepo = MockNeedsRepository();
      final mockProfileRepo = MockProfileRepository();

      getIt.registerSingleton<IProviderRepository>(mockProviderRepo);
      getIt.registerSingleton<NeedsRepository>(mockNeedsRepo);
      getIt.registerSingleton<CapabilitiesCubit>(
          CapabilitiesCubit(mockProviderRepo));
      getIt.registerSingleton<ProfileCubit>(ProfileCubit(mockProfileRepo));

      addTearDown(() {
        getIt.reset();
      });

      when(() => mockProviderRepo.getProviderCapabilities())
          .thenAnswer((_) async => const <ProviderCapability>[]);
      when(() => mockProviderRepo.getProviderOpportunities())
          .thenAnswer((_) async => const <ProviderOpportunity>[]);
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => const UserProfile(
                id: 'u-1',
                email: 'user@test.com',
                accountStatus: 'active',
              ));
      when(() => mockNeedsRepo.getCategories()).thenAnswer((_) async => const [
            NeedCategory(
              slug: 'machinery_equipment',
              name: 'Machinery & Equipment',
              icon: '🚜',
              sortOrder: 1,
              isActive: true,
            ),
          ]);
      when(() => mockNeedsRepo.getCapabilities(
              categorySlug: any(named: 'categorySlug')))
          .thenAnswer((_) async => const [
                NeedCapability(
                  slug: 'excavator_hire',
                  categorySlug: 'machinery_equipment',
                  name: 'Excavator Hire',
                  isActive: true,
                ),
              ]);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProviderServicesPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offer Services'), findsOneWidget);
      expect(find.text('Available for Jobs'), findsOneWidget);
      expect(find.text('Machinery & Equipment'), findsOneWidget);

      await tester.tap(find.text('Machinery & Equipment'));
      await tester.pumpAndSettle();

      expect(find.text('Excavator Hire'), findsOneWidget);
    });

    testWidgets(
        'Professional Services hides marketing capabilities without repetition',
        (tester) async {
      final mockProviderRepo = MockProviderRepository();
      final mockNeedsRepo = MockNeedsRepository();
      final mockProfileRepo = MockProfileRepository();

      getIt.registerSingleton<IProviderRepository>(mockProviderRepo);
      getIt.registerSingleton<NeedsRepository>(mockNeedsRepo);
      getIt.registerSingleton<CapabilitiesCubit>(
          CapabilitiesCubit(mockProviderRepo));
      getIt.registerSingleton<ProfileCubit>(ProfileCubit(mockProfileRepo));

      addTearDown(() {
        getIt.reset();
      });

      when(() => mockProviderRepo.getProviderCapabilities())
          .thenAnswer((_) async => const <ProviderCapability>[]);
      when(() => mockProviderRepo.getProviderOpportunities())
          .thenAnswer((_) async => const <ProviderOpportunity>[]);
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => const UserProfile(
                id: 'u-1',
                email: 'user@test.com',
                accountStatus: 'active',
              ));
      when(() => mockNeedsRepo.getCategories()).thenAnswer((_) async => const [
            NeedCategory(
              slug: 'professional_services',
              name: 'Professional & Business Services',
              icon: '🧑‍💼',
              sortOrder: 2,
              isActive: true,
            ),
          ]);
      when(() => mockNeedsRepo.getCapabilities(
              categorySlug: any(named: 'categorySlug')))
          .thenAnswer((_) async => const [
                NeedCapability(
                  slug: 'company_registration',
                  categorySlug: 'professional_services',
                  name: 'Company Registration',
                  isActive: true,
                  serviceGroupSlug: 'finance_legal',
                  serviceGroupName: 'Finance & Legal',
                ),
                NeedCapability(
                  slug: 'legal_services',
                  categorySlug: 'professional_services',
                  name: 'Legal Services',
                  isActive: true,
                  serviceGroupSlug: 'finance_legal',
                  serviceGroupName: 'Finance & Legal',
                ),
                NeedCapability(
                  slug: 'marketing_services',
                  categorySlug: 'professional_services',
                  name: 'Marketing & Promotion',
                  isActive: true,
                ),
                NeedCapability(
                  slug: 'advertising_campaigns',
                  categorySlug: 'professional_services',
                  name: 'Advertising Campaigns',
                  isActive: true,
                ),
                NeedCapability(
                  slug: 'tiktok_promotion',
                  categorySlug: 'professional_services',
                  name: 'TikTok Promotion',
                  isActive: true,
                ),
              ]);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProviderServicesPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Professional Services category
      await tester.tap(find.text('Professional & Business Services'));
      await tester.pumpAndSettle();

      // Should see professional capabilities only.
      expect(find.text('Company Registration'), findsOneWidget);
      expect(find.text('Legal Services'), findsOneWidget);
      expect(find.text('Finance & Legal'), findsOneWidget);
      expect(find.text('Marketing & Promotion'), findsNothing);

      // Should NOT see individual marketing sub-items directly in Professional.
      expect(find.text('Advertising Campaigns'), findsNothing);
      expect(find.text('TikTok Promotion'), findsNothing);
    });

    testWidgets(
        'Marketing & Promotion category filters out redundant marketing_services tile and opens audience editor',
        (tester) async {
      final mockProviderRepo = MockProviderRepository();
      final mockNeedsRepo = MockNeedsRepository();
      final mockProfileRepo = MockProfileRepository();

      getIt.registerSingleton<IProviderRepository>(mockProviderRepo);
      getIt.registerSingleton<NeedsRepository>(mockNeedsRepo);
      getIt.registerSingleton<CapabilitiesCubit>(
          CapabilitiesCubit(mockProviderRepo));
      getIt.registerSingleton<ProfileCubit>(ProfileCubit(mockProfileRepo));

      addTearDown(() {
        getIt.reset();
      });

      when(() => mockProviderRepo.getProviderCapabilities())
          .thenAnswer((_) async => const <ProviderCapability>[]);
      when(() => mockProviderRepo.getProviderOpportunities())
          .thenAnswer((_) async => const <ProviderOpportunity>[]);
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => const UserProfile(
                id: 'u-1',
                email: 'user@test.com',
                accountStatus: 'active',
              ));
      when(() => mockNeedsRepo.getCategories()).thenAnswer((_) async => const [
            NeedCategory(
              slug: 'marketing_promotion',
              name: 'Marketing & Promotion',
              icon: '📣',
              sortOrder: 2,
              isActive: true,
            ),
          ]);
      when(() => mockNeedsRepo.getCapabilities(
              categorySlug: any(named: 'categorySlug')))
          .thenAnswer((_) async => const [
                NeedCapability(
                  slug: 'advertising_campaigns',
                  categorySlug: 'marketing_promotion',
                  name: 'Advertising Campaigns',
                  isActive: true,
                ),
                NeedCapability(
                  slug: 'marketing_services',
                  categorySlug: 'marketing_promotion',
                  name: 'Marketing & Promotion',
                  isActive: true,
                ),
                NeedCapability(
                  slug: 'i_have_an_audience',
                  categorySlug: 'marketing_promotion',
                  name: 'I Have an Audience',
                  isActive: true,
                ),
              ]);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProviderServicesPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Marketing & Promotion category
      await tester.tap(find.text('Marketing & Promotion'));
      await tester.pumpAndSettle();

      // Should see Advertising Campaigns and I Have an Audience
      expect(find.text('Advertising Campaigns'), findsOneWidget);
      expect(find.text('I Have an Audience'), findsOneWidget);

      // The redundant marketing_services tile should not be shown.
      expect(find.text('Marketing & Promotion'), findsWidgets);

      // Tap "I Have an Audience" row to open audience editor
      await tester.tap(find.text('I Have an Audience'));
      await tester.pumpAndSettle();

      // Should show audience editor with platforms like WhatsApp, TikTok, etc.
      expect(find.text('Where is your audience?'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Tap TikTok and WhatsApp
      await tester.tap(find.text('TikTok'));
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      // Tap back arrow to return to Marketing & Promotion list
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Back on Marketing & Promotion list, subtitle reflects selected platforms
      expect(find.text('Advertising Campaigns'), findsOneWidget);
      expect(find.text('WhatsApp, TikTok'), findsOneWidget);
    });
  });

  group('Provider Widgets', () {
    Widget createLocalizedWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    testWidgets('ProviderVerificationChip renders verified state',
        (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        const ProviderVerificationChip(
          level: ProviderVerificationLevel.providerVerified,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Provider Verified'), findsOneWidget);
    });

    testWidgets('ProviderVerificationChip renders self-declared state',
        (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        const ProviderVerificationChip(
          level: ProviderVerificationLevel.selfDeclared,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Self-declared'), findsOneWidget);
    });

    testWidgets('ProviderVerificationChip keeps capability self-declared',
        (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        const ProviderVerificationChip(
          level: ProviderVerificationLevel.selfDeclared,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Self-declared'), findsOneWidget);
    });

    testWidgets('CapabilityBadge renders capability details and chip',
        (tester) async {
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

    testWidgets(
        'CapabilityBadge distinguishes claimed and reviewed '
        'qualifications', (tester) async {
      final cap = ProviderCapability(
        id: 'cap-qualification-1',
        userId: 'u-1',
        capabilitySlug: 'software_development',
        verificationLevel: ProviderVerificationLevel.selfDeclared,
        createdAt: DateTime.now(),
        capabilityName: 'Software Development',
        metadata: {
          'engagements': ['work'],
          'roles': [
            {
              'role_id': 'developer',
              'kind_ids': ['backend'],
              'qualification_ids': [
                'portfolio_or_github_link',
                'cloud_certification_aws_azure_gcp',
              ],
            },
          ],
        },
        roleQualificationClaims: const [
          {
            'role_slug': 'developer',
            'qualification_slug': 'portfolio_or_github_link',
            'qualification_name': 'Portfolio or GitHub link',
            'status': 'verified',
          },
          {
            'role_slug': 'developer',
            'qualification_slug': 'cloud_certification_aws_azure_gcp',
            'qualification_name': 'Cloud certification',
            'status': 'pending_review',
          },
        ],
      );

      await tester.pumpWidget(createLocalizedWidget(
        CapabilityBadge(
          capability: cap,
          showProfileDetails: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Self-declared'), findsOneWidget);
      expect(find.textContaining('Portfolio or GitHub link'), findsOneWidget);
      expect(find.textContaining('Nipanze verified'), findsOneWidget);
      expect(find.textContaining('Nipanze review pending'), findsOneWidget);
      expect(cap.isVerified, isFalse);
    });

    testWidgets('ProviderOpportunitiesSection renders opportunities',
        (tester) async {
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

      expect(
          find.text('People are looking for what you provide'), findsOneWidget);
      expect(find.text('Excavator Hire'), findsOneWidget);
      expect(find.text('3 opportunities'), findsOneWidget);
      expect(find.text('Heavy Haulage'), findsOneWidget);
      expect(find.text('2 opportunities'), findsOneWidget);
    });

    testWidgets(
        'CapabilityBadge renders Driving School under Professional Services',
        (tester) async {
      final cap = ProviderCapability(
        id: 'cap-driving-1',
        userId: 'u-1',
        capabilitySlug: 'driving_school',
        verificationLevel: ProviderVerificationLevel.providerVerified,
        createdAt: DateTime.now(),
        capabilityName: 'Driving School / Driver Training',
        categorySlug: 'professional_services',
        categoryName: 'Professional Services',
        categoryIcon: '🧑‍💼',
      );

      await tester.pumpWidget(createLocalizedWidget(
        CapabilityBadge(
          capability: cap,
          opportunityCount: 5,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Driving School / Driver Training'), findsOneWidget);
      expect(find.text('Professional Services'), findsOneWidget);
      expect(find.text('🧑‍💼'), findsOneWidget);
      expect(find.text('Provider Verified'), findsOneWidget);
      expect(find.text('5 opportunities'), findsOneWidget);
    });
  });
}
