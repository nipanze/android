// lib/features/kyc/presentation/cubit/kyc_state.dart
part of 'kyc_cubit.dart';

abstract class KycState extends Equatable {
  const KycState();
  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {
  const KycInitial();
}

class KycLoading extends KycState {
  const KycLoading();
}

class KycLoaded extends KycState {
  const KycLoaded(this.kyc);
  final KycVerification? kyc; // null = no record yet
  @override
  List<Object?> get props => [kyc];
}

class KycUploading extends KycState {
  const KycUploading({required this.docType, this.kyc});
  final String docType; // which doc is uploading
  final KycVerification? kyc;
  @override
  List<Object?> get props => [docType, kyc];
}

class KycSubmitting extends KycState {
  const KycSubmitting(this.kyc);
  final KycVerification kyc;
  @override
  List<Object?> get props => [kyc];
}

class KycError extends KycState {
  const KycError(this.message, {this.kyc});
  final String message;
  final KycVerification? kyc; // preserve existing data on error
  @override
  List<Object?> get props => [message, kyc];
}
