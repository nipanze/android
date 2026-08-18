part of 'blocked_users_cubit.dart';

sealed class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object?> get props => [];
}

final class BlockedUsersInitial extends BlockedUsersState {
  const BlockedUsersInitial();
}

final class BlockedUsersLoading extends BlockedUsersState {
  const BlockedUsersLoading();
}

final class BlockedUsersSaving extends BlockedUsersState {
  const BlockedUsersSaving();
}

final class BlockedUsersLoaded extends BlockedUsersState {
  const BlockedUsersLoaded(
    this.users, {
    this.justBlocked = false,
    this.justUnblocked = false,
  });

  final List<BlockedUser> users;
  final bool justBlocked;
  final bool justUnblocked;

  @override
  List<Object?> get props => [users, justBlocked, justUnblocked];
}

final class BlockedUsersError extends BlockedUsersState {
  const BlockedUsersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
