import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/account/data/profile_repository.dart';
import 'package:nipanze/features/account/domain/models/user_profile.dart';
import 'package:nipanze/features/account/presentation/cubit/profile_cubit.dart';

class MockProfileRepository implements ProfileRepository {
  UserProfile? _profile;
  Object? _error;
  int updateCallCount = 0;

  void setProfile(UserProfile? profile) => _profile = profile;
  void setError(Object error) => _error = error;

  @override
  Future<UserProfile?> getProfile() async {
    if (_error != null) throw _error!;
    return _profile;
  }

  @override
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncome,
    String? incomeCurrency,
    List<String>? preferredEmploymentTypes,
    String? preferredIncomeBracket,
    bool? prefersSuggestedTerms,
    bool? prefersVerifiedOnly,
    String? preferredBank,
    String? institutionType,
    bool? isBankAgent,
    bool? showProfessionalTag,
  }) async {
    updateCallCount++;
    if (_error != null) throw _error!;
    return false;
  }

  @override
  Future<String> uploadAvatarBytes(List<int> bytes, String fileExt) async {
    if (_error != null) throw _error!;
    return 'https://storage.example.com/avatar.jpg';
  }

  @override
  Future<int> consumeFreeUnlock() async {
    if (_error != null) throw _error!;
    return 0;
  }
}

const _testProfile = UserProfile(
  id: 'u-1',
  email: 'user@test.com',
  fullName: 'James Okello',
  accountStatus: 'active',
  phone: '+256700000000',
  district: 'Kampala',
  kycStatus: 'approved',
);

void main() {
  late MockProfileRepository repository;
  late ProfileCubit cubit;

  setUp(() {
    repository = MockProfileRepository();
    cubit = ProfileCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ProfileCubit Initial State', () {
    test('starts with ProfileCubitInitial', () {
      expect(cubit.state, isA<ProfileCubitInitial>());
    });
  });

  group('ProfileCubit.load()', () {
    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Loading then Loaded when profile exists',
      build: () {
        repository.setProfile(_testProfile);
        return ProfileCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProfileCubitLoading>(),
        isA<ProfileCubitLoaded>()
            .having((s) => s.profile.id, 'id', 'u-1')
            .having((s) => s.profile.fullName, 'fullName', 'James Okello'),
      ],
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Loading then Error when profile is null',
      build: () {
        repository.setProfile(null);
        return ProfileCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProfileCubitLoading>(),
        isA<ProfileCubitError>().having(
          (s) => s.message,
          'message',
          contains('Profile not found'),
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Loading then Error on repository exception',
      build: () {
        repository.setError(Exception('DB connection failed'));
        return ProfileCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProfileCubitLoading>(),
        isA<ProfileCubitError>().having(
          (s) => s.message,
          'message',
          isNotEmpty,
        ),
      ],
    );
  });

  group('ProfileCubit.updateProfile()', () {
    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Saving then Loaded with justSaved: true on success',
      build: () {
        repository.setProfile(_testProfile);
        return ProfileCubit(repository);
      },
      seed: () => const ProfileCubitLoaded(_testProfile),
      act: (cubit) => cubit.updateProfile(fullName: 'New Name'),
      expect: () => [
        isA<ProfileCubitSaving>(),
        isA<ProfileCubitLoaded>()
            .having((s) => s.justSaved, 'justSaved', isTrue),
      ],
      verify: (cubit) {
        expect(repository.updateCallCount, 1);
      },
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'does nothing when state is not Loaded',
      build: () => ProfileCubit(repository),
      act: (cubit) => cubit.updateProfile(fullName: 'New Name'),
      expect: () => <ProfileCubitState>[],
      verify: (cubit) {
        expect(repository.updateCallCount, 0);
      },
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Error then rolls back to previous state on repository failure',
      build: () {
        repository.setProfile(_testProfile);
        return ProfileCubit(repository);
      },
      seed: () => const ProfileCubitLoaded(_testProfile),
      act: (cubit) {
        repository.setError(Exception('Save failed'));
        return cubit.updateProfile(fullName: 'New Name');
      },
      expect: () => [
        isA<ProfileCubitSaving>(),
        isA<ProfileCubitLoaded>().having(
          (s) => s.profile.fullName,
          'fullName',
          'James Okello',
        ),
        isA<ProfileCubitError>().having(
          (s) => s.message,
          'message',
          isNotEmpty,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'emits Error when reload returns null after save',
      build: () {
        repository.setProfile(_testProfile);
        return ProfileCubit(repository);
      },
      seed: () => const ProfileCubitLoaded(_testProfile),
      act: (cubit) {
        repository.setProfile(null);
        return cubit.updateProfile(fullName: 'New Name');
      },
      expect: () => [
        isA<ProfileCubitSaving>(),
        isA<ProfileCubitLoaded>().having(
          (s) => s.profile.fullName,
          'fullName',
          'James Okello',
        ),
        isA<ProfileCubitError>().having(
          (s) => s.message,
          'message',
          contains('Could not reload'),
        ),
      ],
    );
  });

  group('ProfileCubit.refresh()', () {
    blocTest<ProfileCubit, ProfileCubitState>(
      'delegates to load()',
      build: () {
        repository.setProfile(_testProfile);
        return ProfileCubit(repository);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<ProfileCubitLoading>(),
        isA<ProfileCubitLoaded>(),
      ],
    );
  });

  group('ProfileCubit pending avatar methods', () {
    blocTest<ProfileCubit, ProfileCubitState>(
      'setPendingAvatar emits ProfileCubitLoaded with pendingAvatarBytes',
      build: () => ProfileCubit(repository),
      seed: () => const ProfileCubitLoaded(_testProfile),
      act: (cubit) => cubit.setPendingAvatar(Uint8List.fromList([1, 2, 3])),
      expect: () => [
        isA<ProfileCubitLoaded>()
            .having(
                (s) => s.pendingAvatarBytes, 'pendingAvatarBytes', isNotNull)
            .having(
                (s) => s.pendingAvatarRemoved, 'pendingAvatarRemoved', isFalse),
      ],
    );

    blocTest<ProfileCubit, ProfileCubitState>(
      'clearPendingAvatar emits ProfileCubitLoaded with pendingAvatarBytes null and pendingAvatarRemoved set',
      build: () => ProfileCubit(repository),
      seed: () => ProfileCubitLoaded(_testProfile,
          pendingAvatarBytes: Uint8List.fromList([1, 2, 3])),
      act: (cubit) => cubit.clearPendingAvatar(removeExisting: true),
      expect: () => [
        isA<ProfileCubitLoaded>()
            .having((s) => s.pendingAvatarBytes, 'pendingAvatarBytes', isNull)
            .having(
                (s) => s.pendingAvatarRemoved, 'pendingAvatarRemoved', isTrue),
      ],
    );
  });

  group('ProfileCubitState Equatable', () {
    test('ProfileCubitLoaded equality', () {
      const a = ProfileCubitLoaded(_testProfile);
      const b = ProfileCubitLoaded(_testProfile);
      expect(a, equals(b));
    });

    test('ProfileCubitLoaded inequality with justSaved', () {
      const a = ProfileCubitLoaded(_testProfile);
      const b = ProfileCubitLoaded(_testProfile, justSaved: true);
      expect(a, isNot(equals(b)));
    });

    test('ProfileCubitError equality', () {
      const a = ProfileCubitError('fail');
      const b = ProfileCubitError('fail');
      expect(a, equals(b));
    });

    test('ProfileCubitError inequality', () {
      const a = ProfileCubitError('fail1');
      const b = ProfileCubitError('fail2');
      expect(a, isNot(equals(b)));
    });
  });
}
