import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../provider/presentation/widgets/additional_verification_section.dart';
import '../../domain/models/kyc_verification.dart';
import '../cubit/kyc_cubit.dart';
import '../widgets/kyc_required_documents_section.dart';

class KycPage extends StatelessWidget {
  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KycCubit>()..load(),
      child: const _KycView(),
    );
  }
}

class _KycView extends StatelessWidget {
  const _KycView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.kycPageTitle),
      ),
      body: BlocConsumer<KycCubit, KycState>(
        listener: (context, state) {
          if (state is KycLoaded && state.kyc != null) {
            context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
          }
        },
        builder: (context, state) {
          if (state is KycLoading || state is KycInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final kyc = switch (state) {
            KycLoaded() => state.kyc,
            KycUploading() => state.kyc,
            KycSubmitting() => state.kyc,
            KycError() => state.kyc,
            _ => null,
          };

          final authState = context.watch<AuthBloc>().state;
          final user = authState is AuthAuthenticated ? authState.user : null;
          final hasProfilePhoto = user?.avatarUrl?.isNotEmpty == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Verification details remain available through this legacy route.
              _StatusBanner(kyc: kyc),
              const SizedBox(height: 24),

              // Rejection reason
              if (kyc?.isRejected == true && kyc?.rejectionReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.kycRejectionReason,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger)),
                          const SizedBox(height: 2),
                          Text(kyc!.rejectionReason!,
                              style: const TextStyle(fontSize: 11)),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Pending notice
              if (kyc?.isPending == true) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(l10n.kycPendingNotice,
                            style: const TextStyle(fontSize: 12))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Additional Verification Section
              const AdditionalVerificationSection(),
              const SizedBox(height: 24),

              KycRequiredDocumentsSection(
                hasProfilePhoto: hasProfilePhoto,
              ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.kyc});
  final KycVerification? kyc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = kyc?.status ?? 'not_submitted';

    final (label, description, icon, color) = switch (status) {
      'approved' => (
          l10n.kycStatusApproved,
          l10n.kycStatusApprovedDesc,
          Icons.verified_rounded,
          AppColors.success
        ),
      'pending' => (
          l10n.kycStatusPending,
          l10n.kycStatusPendingDesc,
          Icons.hourglass_top_rounded,
          AppColors.warning
        ),
      'rejected' => (
          l10n.kycStatusRejected,
          l10n.kycStatusRejectedDesc,
          Icons.cancel_outlined,
          AppColors.danger
        ),
      'expired' => (
          l10n.kycStatusExpired,
          l10n.kycStatusExpiredDesc,
          Icons.timer_off_outlined,
          AppColors.warning
        ),
      _ => (
          l10n.kycStatusNotSubmitted,
          l10n.kycStatusNotSubmittedDesc,
          Icons.upload_file_outlined,
          AppColors.accent
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
            const SizedBox(height: 2),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        )),
      ]),
    );
  }
}
