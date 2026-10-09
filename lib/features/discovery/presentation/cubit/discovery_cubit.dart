import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/discovery_repository.dart';
import '../../domain/models/discovery_question_template.dart';
import '../../domain/models/user_discovery_plan.dart';

part 'discovery_state.dart';

@injectable
class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit(this._repository) : super(const DiscoveryInitial());

  final DiscoveryRepository _repository;

  Future<void> loadCard({required String country}) async {
    emit(const DiscoveryLoading());
    try {
      final template = await _repository.getNextTemplate(country: country);
      emit(DiscoveryCardLoaded(template));
    } catch (e) {
      emit(DiscoveryError(userFacingErrorMessage(e)));
    }
  }

  Future<void> loadPlans() async {
    emit(const DiscoveryLoading());
    try {
      final plans = await _repository.getPlans();
      emit(DiscoveryPlansLoaded(plans));
    } catch (e) {
      emit(DiscoveryError(userFacingErrorMessage(e)));
    }
  }

  Future<void> skipTemplate(String templateId) async {
    await _repository.recordInteraction(
      templateId: templateId,
      action: 'skip',
      dismissFor: const Duration(days: 7),
    );
    emit(const DiscoveryCardLoaded(null));
  }

  Future<void> dismissTemplate(String templateId) async {
    await _repository.recordInteraction(
      templateId: templateId,
      action: 'dismiss',
      dismissFor: const Duration(days: 30),
    );
    emit(const DiscoveryCardLoaded(null));
  }

  Future<void> muteTemplate(String templateId) async {
    await _repository.recordInteraction(
      templateId: templateId,
      action: 'mute',
      muteFor: const Duration(days: 365),
    );
    emit(const DiscoveryCardLoaded(null));
  }

  Future<void> answerTemplate({
    required String templateId,
    required Map<String, dynamic> answer,
  }) async {
    await _repository.recordInteraction(
      templateId: templateId,
      action: 'answer',
      answer: answer,
    );
    emit(const DiscoveryCardLoaded(null));
  }

  Future<void> createPlan(DiscoveryPlanDraft draft) async {
    try {
      await _repository.createPlan(draft);
      final plans = await _repository.getPlans();
      emit(DiscoveryPlansLoaded(plans));
    } catch (e) {
      emit(DiscoveryError(userFacingErrorMessage(e)));
    }
  }

  Future<void> updatePlan(
    String planId, {
    required String title,
    String? destination,
    String? preferredLocation,
    DateTime? expectedDate,
    String? timeframe,
    String reminderPreference = 'none',
  }) async {
    try {
      await _repository.updatePlan(
        planId,
        title: title,
        destination: destination,
        preferredLocation: preferredLocation,
        expectedDate: expectedDate,
        timeframe: timeframe,
        reminderPreference: reminderPreference,
      );
      final plans = await _repository.getPlans();
      emit(DiscoveryPlansLoaded(plans));
    } catch (e) {
      emit(DiscoveryError(userFacingErrorMessage(e)));
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _repository.deletePlan(planId);
      final plans = await _repository.getPlans();
      emit(DiscoveryPlansLoaded(plans));
    } catch (e) {
      emit(DiscoveryError(userFacingErrorMessage(e)));
    }
  }
}
