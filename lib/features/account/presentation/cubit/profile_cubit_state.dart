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
  const ProfileCubitLoaded(this.profile, {this.justSaved = false});
  final UserProfile profile; // non-null: guaranteed by cubit
  final bool justSaved;

  @override
  List<Object?> get props => [profile, justSaved];
}

final class ProfileCubitError extends ProfileCubitState {
  const ProfileCubitError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
