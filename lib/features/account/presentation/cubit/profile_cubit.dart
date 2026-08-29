// lib/features/account/presentation/cubit/profile_cubit.dart
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';

part 'profile_cubit_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileCubitState> {
  ProfileCubit(this._repository) : super(const ProfileCubitInitial());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(const ProfileCubitLoading());
    try {
      // getProfile() returns UserProfile? — treat null as "profile not found"
      final profile = await _repository.getProfile();
      if (profile == null) {
        emit(const ProfileCubitError(
            'Profile not found. Please contact support.'));
        return;
      }
      emit(ProfileCubitLoaded(profile));
    } catch (e) {
      emit(ProfileCubitError(userFacingErrorMessage(e)));
    }
  }

  Future<void> updateProfile({
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
    if (state is! ProfileCubitLoaded) return;
    final current = state as ProfileCubitLoaded;
    emit(const ProfileCubitSaving());
    try {
      final emailConfirmationPending = await _repository.updateProfile(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        clearAvatar: clearAvatar,
        phone: phone,
        district: district,
        employmentType: employmentType,
        employerName: employerName,
        monthlyIncome: monthlyIncome,
        incomeCurrency: incomeCurrency,
        preferredEmploymentTypes: preferredEmploymentTypes,
        preferredIncomeBracket: preferredIncomeBracket,
        prefersSuggestedTerms: prefersSuggestedTerms,
        prefersVerifiedOnly: prefersVerifiedOnly,
        preferredBank: preferredBank,
        institutionType: institutionType,
        isBankAgent: isBankAgent,
        showProfessionalTag: showProfessionalTag,
      );
      // Reload fresh from DB
      final updated = await _repository.getProfile();
      if (updated == null) {
        emit(current); // rollback to previous good state
        emit(const ProfileCubitError('Could not reload profile after save.'));
        return;
      }
      emit(ProfileCubitLoaded(
        updated,
        justSaved: true,
        emailConfirmationPending: emailConfirmationPending,
      ));
    } catch (e) {
      emit(current);
      emit(ProfileCubitError(userFacingErrorMessage(e)));
    }
  }

  Future<void> refresh() => load();

  /// Store avatar bytes in state so they survive widget rebuilds.
  void setPendingAvatar(Uint8List bytes) {
    if (state is! ProfileCubitLoaded) return;
    emit((state as ProfileCubitLoaded).copyWith(
      pendingAvatarBytes: bytes,
      pendingAvatarRemoved: false,
    ));
  }

  /// Mark avatar as removed in state (user tapped "Remove photo").
  void clearPendingAvatar({bool removeExisting = false}) {
    if (state is! ProfileCubitLoaded) return;
    emit((state as ProfileCubitLoaded).copyWith(
      pendingAvatarBytes: null,
      pendingAvatarRemoved: removeExisting,
    ));
  }
}
