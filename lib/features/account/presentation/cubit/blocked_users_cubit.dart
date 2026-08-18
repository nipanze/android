import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/privacy_repository.dart';
import '../../domain/models/blocked_user.dart';

part 'blocked_users_state.dart';

@injectable
class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit(this._repository) : super(const BlockedUsersInitial());

  final PrivacyRepository _repository;

  Future<void> load() async {
    emit(const BlockedUsersLoading());
    try {
      final users = await _repository.getBlockedUsers();
      emit(BlockedUsersLoaded(users));
    } catch (e) {
      emit(BlockedUsersError(userFacingErrorMessage(e)));
    }
  }

  Future<void> blockUser(String userId) async {
    final previous = state;
    emit(const BlockedUsersSaving());
    try {
      await _repository.blockUser(userId);
      final users = await _repository.getBlockedUsers();
      emit(BlockedUsersLoaded(users, justBlocked: true));
    } catch (e) {
      emit(previous);
      emit(BlockedUsersError(userFacingErrorMessage(e)));
    }
  }

  Future<void> unblockUser(String userId) async {
    final previous = state;
    if (previous is BlockedUsersLoaded) {
      emit(BlockedUsersLoaded(
        previous.users.where((user) => user.blockedId != userId).toList(),
        justUnblocked: true,
      ));
    } else {
      emit(const BlockedUsersSaving());
    }

    try {
      await _repository.unblockUser(userId);
      final users = await _repository.getBlockedUsers();
      emit(BlockedUsersLoaded(users, justUnblocked: true));
    } catch (e) {
      emit(previous);
      emit(BlockedUsersError(userFacingErrorMessage(e)));
    }
  }
}
