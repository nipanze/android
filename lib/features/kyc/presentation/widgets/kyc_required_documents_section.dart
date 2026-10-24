import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/kyc_cubit.dart';

class KycRequiredDocumentsSection extends StatelessWidget {
  const KycRequiredDocumentsSection({
    super.key,
    required this.hasProfilePhoto,
    this.showRejectionReason = true,
  });

  final bool hasProfilePhoto;
  final bool showRejectionReason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<KycCubit, KycState>(
      listener: (context, state) {
        if (state is KycError && !isNetworkErrorMessage(state.message)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: l10n.kycDismiss,
              textColor: Colors.white,
              onPressed: () => context.read<KycCubit>().clearError(),
            ),
          ));
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
        if (kyc?.isApproved == true) return const SizedBox.shrink();
        final uploading = state is KycUploading;
        final submitting = state is KycSubmitting;
        final uploadingDoc = uploading ? state.docType : null;
        final canSubmit = !submitting &&
            !uploading &&
            kyc?.allDocsUploaded == true &&
            hasProfilePhoto;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.kycRequiredDocs,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.kycRequiredDocsSubtitle,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            if (showRejectionReason &&
                kyc?.isRejected == true &&
                kyc?.rejectionReason?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.kycRejectionReason,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        )),
                    const SizedBox(height: 3),
                    Text(kyc!.rejectionReason!,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
            _DocumentTile(
              icon: Icons.badge_outlined,
              title: l10n.kycDocNationalIdFront,
              subtitle: l10n.kycDocNationalIdFrontSubtitle,
              uploadedLabel: kyc?.isPending == true
                  ? l10n.kycDocUploadedUnderReview
                  : l10n.kycDocUploadedTapReplace,
              uploadedUrl: kyc?.nationalIdFrontUrl,
              isUploading: uploadingDoc == 'national_id_front',
              enabled: !submitting && kyc?.isPending != true,
              onPick: () => _pickAndUpload(context, 'national_id_front'),
            ),
            _DocumentTile(
              icon: Icons.badge_outlined,
              title: l10n.kycDocNationalIdBack,
              subtitle: l10n.kycDocNationalIdBackSubtitle,
              uploadedLabel: kyc?.isPending == true
                  ? l10n.kycDocUploadedUnderReview
                  : l10n.kycDocUploadedTapReplace,
              uploadedUrl: kyc?.nationalIdBackUrl,
              isUploading: uploadingDoc == 'national_id_back',
              enabled: !submitting && kyc?.isPending != true,
              onPick: () => _pickAndUpload(context, 'national_id_back'),
            ),
            _DocumentTile(
              icon: Icons.face_outlined,
              title: l10n.kycDocSelfie,
              subtitle: l10n.kycDocSelfieSubtitle,
              uploadedLabel: kyc?.isPending == true
                  ? l10n.kycDocUploadedUnderReview
                  : l10n.kycDocUploadedTapReplace,
              uploadedUrl: kyc?.selfieUrl,
              isUploading: uploadingDoc == 'selfie',
              enabled: !submitting && kyc?.isPending != true,
              onPick: () =>
                  _pickAndUpload(context, 'selfie', preferCamera: true),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.kycPrivacyNote,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.accent)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (kyc?.isPending != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () => context.read<KycCubit>().submit()
                      : null,
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.kycSubmitForReview),
                ),
              ),
            if (!canSubmit && !uploading && kyc?.isPending != true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.kycUploadAllDocs,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    String docType, {
    bool preferCamera = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => KycImageSourcePicker(l10n: l10n),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: preferCamera ? ImageSource.camera : source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null || !context.mounted) return;
    await context.read<KycCubit>().uploadDocument(picked, docType);
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploadedLabel,
    required this.uploadedUrl,
    required this.isUploading,
    required this.enabled,
    required this.onPick,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String uploadedLabel;
  final String? uploadedUrl;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final uploaded = uploadedUrl != null;
    final interactive = enabled && !isUploading;
    return Opacity(
      opacity: interactive ? 1 : 0.5,
      child: GestureDetector(
        onTap: interactive ? onPick : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploaded
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor,
              width: uploaded ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(uploaded ? Icons.check_circle_rounded : icon,
                      size: 20,
                      color: uploaded ? AppColors.success : AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    uploaded ? uploadedLabel : subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: uploaded ? AppColors.success : null),
                  ),
                ],
              ),
            ),
            if (!isUploading)
              Icon(
                uploaded ? Icons.check_circle_rounded : Icons.upload_rounded,
                size: 22,
                color: uploaded
                    ? AppColors.success
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ]),
        ),
      ),
    );
  }
}

class KycImageSourcePicker extends StatelessWidget {
  const KycImageSourcePicker({super.key, required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.kycChooseSource,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.kycSourceCamera),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.kycSourceLibrary),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      );
}
