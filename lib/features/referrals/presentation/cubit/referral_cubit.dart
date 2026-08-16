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
    if (marketer.referralCode.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Join Nipanze and use my referral code: ${marketer.referralCode}\n${marketer.referralLink}',
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
}
