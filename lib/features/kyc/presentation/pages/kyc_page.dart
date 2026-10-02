import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../account/data/profile_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../provider/domain/entities/provider_capability.dart';
import '../../../provider/domain/repositories/provider_repository_interface.dart';
import '../../domain/models/kyc_verification.dart';
import '../cubit/kyc_cubit.dart';

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
          if (state is KycError) {
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

          final authState = context.watch<AuthBloc>().state;
          final user = authState is AuthAuthenticated ? authState.user : null;
          final hasProfilePhoto = user?.avatarUrl?.isNotEmpty == true;

          final isUploading = state is KycUploading;
          final isSubmitting = state is KycSubmitting;
          final uploadingDoc = isUploading ? state.docType : null;
          final canSubmit = !isSubmitting &&
              !isUploading &&
              kyc?.allDocsUploaded == true &&
              hasProfilePhoto;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status banner
              _ProfilePictureSection(
                onPick: () => _pickProfilePicture(context),
                onRemove: () => _removeProfilePicture(context),
              ),
              const SizedBox(height: 20),

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

              // Already approved — show expiry
              if (kyc?.isApproved == true) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.kycIdentityVerified,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                  fontSize: 13)),
                          if (kyc?.expiresAt != null)
                            Text(
                              l10n.kycExpires(_fmtDate(kyc!.expiresAt!)),
                              style: const TextStyle(fontSize: 11),
                            ),
                        ]),
                  ]),
                ),
                const SizedBox(height: 16),
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

              // Marketplace Access Section
              _MarketplaceAccessSection(isVerified: kyc?.isApproved == true),
              const SizedBox(height: 24),

              // Additional Verification Section
              _AdditionalVerificationSection(
                isIdentityVerified: kyc?.isApproved == true,
              ),
              const SizedBox(height: 24),

              // Document upload section
              if (kyc?.isApproved != true) ...[
                Text(l10n.kycRequiredDocs,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.kycRequiredDocsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),

                _DocUploadTile(
                  docType: 'national_id_front',
                  icon: Icons.badge_outlined,
                  title: l10n.kycDocNationalIdFront,
                  subtitle: l10n.kycDocNationalIdFrontSubtitle,
                  uploadedLabel: kyc?.isPending == true
                      ? l10n.kycDocUploadedUnderReview
                      : l10n.kycDocUploadedTapReplace,
                  uploadedUrl: kyc?.nationalIdFrontUrl,
                  isUploading: uploadingDoc == 'national_id_front',
                  enabled: !isSubmitting && kyc?.isPending != true,
                  onPick: () => _pickAndUpload(context, 'national_id_front'),
                ),

                _DocUploadTile(
                  docType: 'national_id_back',
                  icon: Icons.badge_outlined,
                  title: l10n.kycDocNationalIdBack,
                  subtitle: l10n.kycDocNationalIdBackSubtitle,
                  uploadedLabel: kyc?.isPending == true
                      ? l10n.kycDocUploadedUnderReview
                      : l10n.kycDocUploadedTapReplace,
                  uploadedUrl: kyc?.nationalIdBackUrl,
                  isUploading: uploadingDoc == 'national_id_back',
                  enabled: !isSubmitting && kyc?.isPending != true,
                  onPick: () => _pickAndUpload(context, 'national_id_back'),
                ),

                _DocUploadTile(
                  docType: 'selfie',
                  icon: Icons.face_outlined,
                  title: l10n.kycDocSelfie,
                  subtitle: l10n.kycDocSelfieSubtitle,
                  uploadedLabel: kyc?.isPending == true
                      ? l10n.kycDocUploadedUnderReview
                      : l10n.kycDocUploadedTapReplace,
                  uploadedUrl: kyc?.selfieUrl,
                  isUploading: uploadingDoc == 'selfie',
                  enabled: !isSubmitting && kyc?.isPending != true,
                  onPick: () =>
                      _pickAndUpload(context, 'selfie', preferCamera: true),
                ),

                const SizedBox(height: 20),

                // Privacy note
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
                        child: Text(
                      l10n.kycPrivacyNote,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.accent),
                    )),
                  ]),
                ),

                const SizedBox(height: 24),

                // Submit button — disabled until profile picture and all 3 docs uploaded
                if (kyc?.isPending != true)
                  ElevatedButton(
                    onPressed: canSubmit
                        ? () => context.read<KycCubit>().submit()
                        : null,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(l10n.kycSubmitForReview),
                  ),

                // Hint shown when docs or profile photo are incomplete
                if (!canSubmit && !isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.kycUploadAllDocs,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ]),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    String docType, {
    bool preferCamera = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => _SourcePicker(l10n: l10n),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    if (!context.mounted) return;
    await context.read<KycCubit>().uploadDocument(picked, docType);
  }

  Future<void> _pickProfilePicture(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => _SourcePicker(l10n: l10n),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !context.mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      final url = await getIt<ProfileRepository>().uploadAvatarBytes(
        bytes,
        picked.name.split('.').last,
      );
      await getIt<ProfileRepository>().updateProfile(avatarUrl: url);
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile picture: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _removeProfilePicture(BuildContext context) async {
    try {
      await getIt<ProfileRepository>().updateProfile(clearAvatar: true);
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove profile picture: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ProfilePictureSection extends StatelessWidget {
  const _ProfilePictureSection({
    required this.onPick,
    required this.onRemove,
  });

  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final hasPhoto = user?.avatarUrl?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto
              ? AppColors.success.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: hasPhoto ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: user?.avatarUrl,
            initials: user?.initials ?? 'U',
            radius: 34,
            showCameraBadge: true,
            onTap: onPick,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.profilePicture,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasPhoto
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasPhoto ? 'Uploaded' : 'Required',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              hasPhoto ? AppColors.success : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profilePictureKycNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile picture options',
            onSelected: (value) {
              if (value == 'pick') onPick();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pick',
                child: Text('Upload photo'),
              ),
              if (hasPhoto)
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove photo'),
                ),
            ],
          ),
        ],
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

// ─── Document Upload Tile ─────────────────────────────────────────────────────

class _DocUploadTile extends StatelessWidget {
  const _DocUploadTile({
    required this.docType,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploadedLabel,
    required this.uploadedUrl,
    required this.isUploading,
    required this.enabled,
    required this.onPick,
  });

  final String docType;
  final IconData icon;
  final String title;
  final String subtitle;
  final String uploadedLabel;
  final String? uploadedUrl;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onPick;

  bool get isUploaded => uploadedUrl != null;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !isUploading;

    return Opacity(
      // Visual disabled state: dim tile when blocked (e.g. while submitting)
      opacity: interactive ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: interactive ? onPick : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUploaded
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor,
              width: isUploaded ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // Doc icon or uploaded indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isUploaded ? Icons.check_circle_rounded : icon,
                      size: 20,
                      color: isUploaded ? AppColors.success : AppColors.accent),
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
                  isUploaded ? uploadedLabel : subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: isUploaded ? AppColors.success : null),
                ),
              ],
            )),

            // Action icon
            if (!isUploading)
              Icon(
                isUploaded ? Icons.check_circle_rounded : Icons.upload_rounded,
                size: 22,
                color: isUploaded
                    ? AppColors.success
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── Image source picker ──────────────────────────────────────────────────────

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2))),
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
}

// ─── Marketplace Access Section ───────────────────────────────────────────────

class _MarketplaceAccessSection extends StatelessWidget {
  const _MarketplaceAccessSection({required this.isVerified});
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activities = [
      {'title': 'Loan Requests', 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'Forex Requests', 'icon': Icons.currency_exchange_rounded},
      {'title': 'Need Requests', 'icon': Icons.search_rounded},
      {'title': 'Make Offers', 'icon': Icons.handshake_outlined},
      {'title': 'Offer a Service', 'icon': Icons.business_center_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.verified_user_rounded
                    : Icons.lock_outline_rounded,
                size: 20,
                color: isVerified ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Marketplace Access',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isVerified ? 'All Active' : 'Restricted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isVerified
                ? 'Your verified identity grants access to participate in all marketplace activities.'
                : 'Identity verification is required to post requests, make offers, and provide services.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...activities.map(
            (act) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: isVerified
                        ? AppColors.success
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    act['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isVerified
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isVerified ? 'Unlocked' : 'Requires KYC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isVerified
                          ? AppColors.success
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Additional Verification Section ──────────────────────────────────────────

class _AdditionalVerificationSection extends StatefulWidget {
  const _AdditionalVerificationSection({required this.isIdentityVerified});
  final bool isIdentityVerified;

  @override
  State<_AdditionalVerificationSection> createState() =>
      _AdditionalVerificationSectionState();
}

class _AdditionalVerificationSectionState
    extends State<_AdditionalVerificationSection> {
  List<ProviderCapability> _capabilities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final repo = getIt<IProviderRepository>();
      final caps = await repo.getProviderCapabilities();
      if (mounted) {
        setState(() {
          _capabilities = caps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Verification',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Some categories require additional verification before you can offer them.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_capabilities.isNotEmpty) ...[
            ..._capabilities.map((cap) {
              final isVerified = cap.verificationLevel ==
                  ProviderVerificationLevel.providerVerified;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Text(cap.categoryIcon ?? '💼',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cap.capabilityName ?? cap.capabilitySlug,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isVerified ? 'Provider Verified' : 'Self-declared',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No specialized provider capabilities declared yet.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.business_center_outlined, size: 16),
              label: const Text('Manage Provider Capabilities'),
              onPressed: () => context.push(AppRoutes.accountServices),
            ),
          ),
        ],
      ),
    );
  }
}
