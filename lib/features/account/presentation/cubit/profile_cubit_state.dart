// lib/features/account/presentation/cubit/profile_cubit_state.dart
part of 'profile_cubit.dart';

sealed class ProfileCubitState extends Equatable {
  const ProfileCubitState();

  @override
  List<Object?> get props => [];
}

final class ProfileCubitInitial extends ProfileCubitState {
  const ProfileCubitInitial();
}

final class ProfileCubitLoading extends ProfileCubitState {
  const ProfileCubitLoading();
}

final class ProfileCubitSaving extends ProfileCubitState {
  const ProfileCubitSaving();
}

/// Profile is always non-null here — the cubit emits ProfileCubitError
/// instead if the repository returns null.
final class ProfileCubitLoaded extends ProfileCubitState {
  const ProfileCubitLoaded(
    this.profile, {
    this.justSaved = false,
    this.emailConfirmationPending = false,
    this.pendingAvatarBytes,
    this.pendingAvatarRemoved = false,
  });

  final UserProfile profile; // non-null: guaranteed by cubit
  final bool justSaved;
  final bool emailConfirmationPending;

  /// Bytes of the newly selected avatar image (not yet uploaded/saved).
  final Uint8List? pendingAvatarBytes;

  /// True when the user explicitly chose to remove their current photo.
  final bool pendingAvatarRemoved;

  ProfileCubitLoaded copyWith({
    UserProfile? profile,
    bool? justSaved,
    bool? emailConfirmationPending,
    Object? pendingAvatarBytes = _sentinel,
    bool? pendingAvatarRemoved,
  }) {
    return ProfileCubitLoaded(
      profile ?? this.profile,
      justSaved: justSaved ?? this.justSaved,
      emailConfirmationPending:
          emailConfirmationPending ?? this.emailConfirmationPending,
      pendingAvatarBytes: pendingAvatarBytes == _sentinel
          ? this.pendingAvatarBytes
          : pendingAvatarBytes as Uint8List?,
      pendingAvatarRemoved: pendingAvatarRemoved ?? this.pendingAvatarRemoved,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        justSaved,
        emailConfirmationPending,
        pendingAvatarBytes,
        pendingAvatarRemoved,
      ];
}

final class ProfileCubitError extends ProfileCubitState {
  const ProfileCubitError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// Sentinel to distinguish "not provided" from "explicitly null"
const _sentinel = Object();
