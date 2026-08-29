import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/referral_repository.dart';
import '../../domain/models/referral_dashboard.dart';

part 'referral_state.dart';

@injectable
class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit(this._repository) : super(const ReferralInitial());

  final ReferralRepository _repository;

  static String buildShareMessage(ReferralMarketer marketer) {
    final code = marketer.referralCode.trim();
    final link = marketer.referralLink.trim();
    final fallbackLink = link.isNotEmpty
        ? link
        : (code.isNotEmpty
            ? 'https://nipanze.app/r/$code'
            : 'https://nipanze.app');

    if (code.isEmpty) {
      return 'Join Nipanze and start earning rewards.\n$fallbackLink';
    }

    return 'Join Nipanze and use my referral code: $code\n$fallbackLink';
  }

  Future<void> load() async {
    emit(const ReferralLoading());
    try {
      final dashboard = await _repository.getDashboard();
      emit(ReferralLoaded(dashboard: dashboard));
    } catch (e) {
      emit(ReferralError(userFacingErrorMessage(e)));
    }
  }

  Future<void> refresh() => load();

  Future<void> copyCode() async {
    final current = state;
    if (current is! ReferralLoaded) return;
    await Clipboard.setData(
      ClipboardData(text: current.dashboard.marketer.referralCode),
    );
    emit(current.copyWith(lastAction: ReferralAction.codeCopied));
  }

  Future<void> shareReferral() async {
    final current = state;
    if (current is! ReferralLoaded) return;
    final marketer = current.dashboard.marketer;
    final shareText = buildShareMessage(marketer);
    if (shareText.isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Join Nipanze',
      ),
    );
  }

  Future<bool> attributeReferral(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;
    try {
      await _repository.attributeReferral(
        referralCode: cleanCode,
        source: 'user_input',
      );
      final updatedDashboard = await _repository.getDashboard();
      emit(ReferralLoaded(
        dashboard: updatedDashboard,
        lastAction: ReferralAction.codeApplied,
      ));
      return true;
    } catch (e) {
      emit(ReferralError(userFacingErrorMessage(e)));
      return false;
    }
  }

  Future<ReferralCodeValidationState> validateReferralCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      return const ReferralCodeValidationState();
    }

    try {
      final result = await _repository.validateReferralCode(cleanCode);
      return ReferralCodeValidationState(
        status: result.valid
            ? ReferralValidationStatus.valid
            : ReferralValidationStatus.invalid,
        message: result.message,
        reason: result.reason,
        referrerName: result.referrerName,
      );
    } catch (e) {
      return ReferralCodeValidationState(
        status: ReferralValidationStatus.error,
        message: userFacingErrorMessage(e),
      );
    }
  }
}
