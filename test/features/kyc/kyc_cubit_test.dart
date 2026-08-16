import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/kyc/data/kyc_repository.dart';
import 'package:nipanze/features/kyc/domain/models/kyc_verification.dart';
import 'package:nipanze/features/kyc/presentation/cubit/kyc_cubit.dart';

class MockKycRepository extends Mock implements KycRepository {}

KycVerification _kyc({bool withDocs = true}) {
  return KycVerification(
    id: 'kyc-1',
    userId: 'u-1',
    status: 'pending',
    nationalIdFrontUrl: withDocs ? 'https://cdn/f.png' : null,
    nationalIdBackUrl: withDocs ? 'https://cdn/b.png' : null,
    selfieUrl: withDocs ? 'https://cdn/s.png' : null,
  );
}

void main() {
  late MockKycRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(XFile('fallback.png'));
  });

  setUp(() {
    mockRepo = MockKycRepository();
  });

  group('KycCubit', () {
    blocTest<KycCubit, KycState>(
      'load emits Loading then Loaded',
      build: () {
        when(() => mockRepo.getMyKyc()).thenAnswer((_) async => _kyc());
        return KycCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<KycLoading>(),
        isA<KycLoaded>().having((s) => s.kyc?.status, 'status', 'pending'),
      ],
    );

    blocTest<KycCubit, KycState>(
      'load emits Error on failure',
      build: () {
        when(() => mockRepo.getMyKyc()).thenThrow(Exception('failed'));
        return KycCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<KycLoading>(),
        isA<KycError>(),
      ],
    );

    blocTest<KycCubit, KycState>(
      'uploadDocument saves url and emits updated Loaded',
      build: () {
        when(() => mockRepo.getMyKyc()).thenAnswer((_) async => _kyc());
        when(() => mockRepo.uploadDocument(any(), any()))
            .thenAnswer((_) async => 'https://cdn/new.png');
        when(() => mockRepo.saveDocumentUrl(
              docType: any(named: 'docType'),
              url: any(named: 'url'),
            )).thenAnswer((_) async => _kyc());
        return KycCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.uploadDocument(XFile('selfie.png'), 'selfie');
      },
      skip: 2,
      expect: () => [
        isA<KycUploading>(),
        isA<KycLoaded>(),
      ],
    );

    blocTest<KycCubit, KycState>(
      'submit with all docs emits Submitting then Loaded',
      build: () {
        when(() => mockRepo.getMyKyc()).thenAnswer((_) async => _kyc());
        when(() => mockRepo.submitForReview())
            .thenAnswer((_) async => _kyc());
        return KycCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.submit();
      },
      skip: 2,
      expect: () => [
        isA<KycSubmitting>(),
        isA<KycLoaded>(),
      ],
    );

    blocTest<KycCubit, KycState>(
      'submit with missing docs emits Error without calling repository',
      build: () {
        when(() => mockRepo.getMyKyc())
            .thenAnswer((_) async => _kyc(withDocs: false));
        return KycCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.submit();
      },
      skip: 2,
      expect: () => [
        isA<KycError>(),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.submitForReview());
      },
    );

    test('clearError restores Loaded state', () async {
      when(() => mockRepo.getMyKyc()).thenAnswer((_) async => _kyc());
      final cubit = KycCubit(mockRepo);

      await cubit.load();
      cubit.clearError();
      expect(cubit.state, isA<KycLoaded>());

      await cubit.close();
    });
  });
}
