// lib/features/kyc/presentation/cubit/kyc_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
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

  KycVerification? get _currentKyc {
    final s = state;
    return switch (s) {
      KycLoaded() => s.kyc,
      KycUploading() => s.kyc,
      KycSubmitting() => s.kyc,
      KycError() => s.kyc,
      _ => null,
    };
  }

  /// Upload a file for a given doc type and save the URL to the DB.
  Future<void> uploadDocument(XFile file, String docType) async {
    final kyc = _currentKyc;
    emit(KycUploading(docType: docType, kyc: kyc));
    try {
      final url = await _repository.uploadDocument(file, docType);
      final updated =
          await _repository.saveDocumentUrl(docType: docType, url: url);
      emit(KycLoaded(updated));
    } catch (e, st) {
      // ignore: avoid_print
      print('[KycCubit] uploadDocument error: $e\n$st');
      final msg = e is AppException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      emit(KycError(msg, kyc: kyc));
    }
  }

  /// Submit all uploaded docs for admin review.
  Future<void> submit() async {
    final kyc = _currentKyc;
    if (kyc == null) return;
    if (!kyc.allDocsUploaded) {
      emit(KycError('Please upload all three documents before submitting.',
          kyc: kyc));
      return;
    }
    emit(KycSubmitting(kyc));
    try {
      final updated = await _repository.submitForReview();
      emit(KycLoaded(updated));
    } catch (e) {
      final msg = e is AppException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      emit(KycError(msg, kyc: kyc));
    }
  }

  void clearError() {
    final kyc = _currentKyc;
    emit(KycLoaded(kyc));
  }
}
