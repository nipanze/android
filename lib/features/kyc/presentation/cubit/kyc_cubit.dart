// lib/features/kyc/presentation/cubit/kyc_cubit.dart
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/kyc_repository.dart';
import '../../domain/models/kyc_verification.dart';

part 'kyc_state.dart';

@injectable
class KycCubit extends Cubit<KycState> {
  KycCubit(this._repository) : super(const KycInitial());

  final KycRepository _repository;

  Future<void> load() async {
    emit(const KycLoading());
    try {
      final kyc = await _repository.getMyKyc();
      emit(KycLoaded(kyc));
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }

  /// Upload a file for a given doc type and save the URL to the DB.
  Future<void> uploadDocument(File file, String docType) async {
    final current = state;
    emit(KycUploading(
        docType: docType, kyc: current is KycLoaded ? current.kyc : null));
    try {
      final url = await _repository.uploadDocument(file, docType);
      final updated =
          await _repository.saveDocumentUrl(docType: docType, url: url);
      emit(KycLoaded(updated));
    } catch (e) {
      // Restore previous state with error
      final kyc = current is KycLoaded ? current.kyc : null;
      emit(KycError(e.toString(), kyc: kyc));
    }
  }

  /// Submit all uploaded docs for admin review.
  Future<void> submit() async {
    final current = state;
    if (current is! KycLoaded || current.kyc == null) return;
    if (!current.kyc!.allDocsUploaded) {
      emit(KycError('Please upload all three documents before submitting.',
          kyc: current.kyc));
      return;
    }
    emit(KycSubmitting(current.kyc!));
    try {
      final updated = await _repository.submitForReview();
      emit(KycLoaded(updated));
    } catch (e) {
      emit(KycError(e.toString(), kyc: current.kyc));
    }
  }

  void clearError() {
    final current = state;
    if (current is KycError) {
      emit(KycLoaded(current.kyc));
    }
  }
}
