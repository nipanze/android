// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/data/profile_repository.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();
  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CountryInfo _selectedCountry = EastAfricaCountries.defaultCountry;
  String? _district;
  bool _populated = false;
  bool _hasChanges = false;

  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (_populated) setState(() => _hasChanges = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(ProfileCubitLoaded state) {
    if (_populated) return;
    final p = state.profile;
    _nameController.text = p.fullName ?? '';
    _emailController.text = p.email;
    _userInitials = p.initials;

    // Use the stored country code from the profile; fall back to phone
    // detection only if country is absent (legacy accounts without country field).
    final matchedCountry = p.country.isNotEmpty
        ? EastAfricaCountries.findByCode(p.country)
        : EastAfricaCountries.findByPhone(p.phone);
    _selectedCountry = matchedCountry;

    // Strip dial code for local phone field display
    final rawPhone = p.phone ?? '';
    if (rawPhone.startsWith(matchedCountry.dialCode)) {
      _phoneController.text =
          rawPhone.substring(matchedCountry.dialCode.length).trim();
    } else {
      _phoneController.text = rawPhone;
    }

    // Validate district against selected country's regions
    if (p.district != null && matchedCountry.regions.contains(p.district)) {
      _district = p.district;
    } else if (p.district != null &&
        EastAfricaCountries.uganda.regions.contains(p.district)) {
      _district = p.district;
    } else {
      _district = null;
    }

    _populated = true;
    _hasChanges = false;
  }

  void _markChanged() {
    if (_populated && !_hasChanges) setState(() => _hasChanges = true);
  }

  String _formatFullPhoneNumber() {
    final local = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (local.isEmpty) return '';
    if (local.startsWith('+')) return local;
    final dial = _selectedCountry.dialCode;
    final cleanLocal = local.startsWith('0') ? local.substring(1) : local;
    return '$dial$cleanLocal';
  }

  Future<void> _pickAvatar() async {
    final cubit = context.read<ProfileCubit>();
    final cubitState = cubit.state;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F101C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF9E9EB8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF181928) : const Color(0xFFF1F5F9);
    final cardBorder =
        isDark ? const Color(0xFF28293D) : const Color(0xFFE2E8F0);
    const purple = AppColors.accent;

    final loadedState = cubitState is ProfileCubitLoaded ? cubitState : null;
    final hasImage = (loadedState?.pendingAvatarBytes != null) ||
        (loadedState?.profile.avatarUrl?.isNotEmpty == true &&
            loadedState?.pendingAvatarRemoved == false);

    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2D2D42) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.choosePhoto ?? 'Choose photo',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.selectPhotoSource ??
                  'Select where to pick your profile photo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'camera'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: purple.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.takePhoto ?? 'Take a photo',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text(l10n?.useCamera ?? 'Use your camera',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: subtitleColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.accent, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'gallery'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.chooseFromGallery ?? 'Choose from gallery',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text(
                              l10n?.pickExistingPhoto ??
                                  'Pick an existing photo',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: subtitleColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: subtitleColor, size: 22),
                  ],
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.pop(ctx, 'remove'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n?.removePhoto ?? 'Remove photo',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger)),
                            Text(
                                l10n?.removePhotoSubtitle ??
                                    'Delete current profile picture',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: subtitleColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (option == null || !mounted) return;

    if (option == 'remove') {
      cubit.clearPendingAvatar(removeExisting: true);
      _markChanged();
      return;
    }

    final source =
        option == 'camera' ? ImageSource.camera : ImageSource.gallery;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      cubit.setPendingAvatar(bytes);
      _markChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.couldNotSelectImage(e.toString()) ??
                  'Could not select image: $e',
            ),
          ),
        );
      }
    }
  }

  bool get _isReadyToSave =>
      _hasChanges && _nameController.text.trim().isNotEmpty;

  Future<void> _saveProfile(
      BuildContext context, AppLocalizations? l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureOnlineForAction(context)) return;

    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ProfileCubit>();
    final currentCubitState = cubit.state;
    final loaded =
        currentCubitState is ProfileCubitLoaded ? currentCubitState : null;
    final pendingBytes = loaded?.pendingAvatarBytes;
    final clearAvatar = loaded?.pendingAvatarRemoved ?? false;
    String? finalAvatarUrl = clearAvatar ? null : loaded?.profile.avatarUrl;

    if (pendingBytes != null) {
      try {
        final repo = getIt<ProfileRepository>();
        finalAvatarUrl = await repo.uploadAvatarBytes(pendingBytes, 'jpg');
      } catch (uploadErr) {
        if (mounted) {
          final message = userFacingErrorMessage(uploadErr);
          if (isNetworkErrorMessage(message)) return;
          messenger.showSnackBar(SnackBar(
            content: Text(l10n?.avatarUploadFailed(message) ??
                'Avatar upload failed: $message'),
            backgroundColor: AppColors.danger,
          ));
        }
        return;
      }
    }

    final fullPhone = _formatFullPhoneNumber();

    if (!mounted) return;
    await cubit.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatarUrl: finalAvatarUrl,
      clearAvatar: clearAvatar,
      phone: fullPhone.isEmpty ? null : fullPhone,
      country: _selectedCountry.code,
      incomeCurrency: _selectedCountry.currency,
      district: _district ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n?.editProfile ?? 'Edit profile'),
      ),
      body: BlocConsumer<ProfileCubit, ProfileCubitState>(
        listener: (context, state) {
          if (state is ProfileCubitLoaded) {
            _populateIfNeeded(state);
            if (state.justSaved) {
              final emailUpdateError = state.emailUpdateError;
              if (emailUpdateError != null) {
                _emailController.text = state.profile.email;
                _hasChanges = false;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    emailUpdateError != null
                        ? 'Profile saved, but email was not changed. $emailUpdateError'
                        : state.emailConfirmationPending
                            ? 'Profile saved. Check your email to confirm the new address.'
                            : (l10n?.profileSaved ?? 'Profile saved.'),
                  ),
                ),
              );
              // Refresh AuthBloc so top bars update immediately
              try {
                context
                    .read<AuthBloc>()
                    .add(const AuthProfileRefreshRequested());
              } catch (_) {}
              if (emailUpdateError == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.pop();
                });
              }
            }
          }
        },
        builder: (context, state) {
          if (state is ProfileCubitLoading || state is ProfileCubitInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileCubitError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ProfileCubit>().load(),
            );
          }

          final loadedState = state is ProfileCubitLoaded ? state : null;
          final pendingBytes = loadedState?.pendingAvatarBytes;
          final isAvatarRemoved = loadedState?.pendingAvatarRemoved ?? false;
          final avatarUrl =
              isAvatarRemoved ? null : loadedState?.profile.avatarUrl;
          final kycStatus = loadedState?.profile.kycStatus;
          final isKycApproved = loadedState?.profile.isKycApproved ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar Picker Section ─────────────────────────────────
                  Center(
                    child: UserAvatar(
                      avatarUrl: avatarUrl,
                      newAvatarBytes: pendingBytes,
                      initials: _userInitials,
                      radius: 45,
                      showCameraBadge: true,
                      onTap: _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: _pickAvatar,
                      child: Text(
                        l10n?.changeProfilePicture ?? 'Change profile picture',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Identity Verification Card ─────────────────────────────
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.kyc),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.identityVerification ??
                                        'Identity Verification',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isKycApproved
                                        ? 'Your account identity is verified'
                                        : 'Upload ID document for full access',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.text2Dark
                                          : AppColors.text2Light,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildKycBadge(context, kycStatus),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.text3Dark
                                  : AppColors.text3Light,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Full Name ─────────────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n?.fullName ?? 'Full name',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (l10n?.enterFullName ?? 'Enter your full name')
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // ── WhatsApp-Style Merged Country & Phone Field ───────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n?.phoneNumberLabel ?? 'Phone number',
                      hintText: '7XX XXX XXX',
                      prefixIcon: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Registered country dial code (${_selectedCountry.dialCode}) is locked.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCountry.flag,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCountry.dialCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.text3Dark
                                    : AppColors.text3Light,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: 14),

                  // ── Regional / District Dropdown ──────────────────────────
                  DropdownButtonFormField<String>(
                    key: ValueKey('district_${_selectedCountry.code}'),
                    initialValue: _district,
                    decoration: InputDecoration(
                      labelText: _selectedCountry.regionsLabel,
                      prefixIcon:
                          const Icon(Icons.location_on_outlined, size: 20),
                    ),
                    hint: Text(
                      l10n?.selectRegionLabel(
                            _selectedCountry.regionsLabel.toLowerCase(),
                          ) ??
                          'Select ${_selectedCountry.regionsLabel.toLowerCase()}',
                    ),
                    items: _selectedCountry.regions
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _district = v);
                      _markChanged();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<ProfileCubit, ProfileCubitState>(
        builder: (context, state) {
          final isSaving = state is ProfileCubitSaving;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: ElevatedButton(
              onPressed: isSaving || !_isReadyToSave
                  ? null
                  : () => _saveProfile(context, l10n),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n?.saveChanges ?? 'Save changes'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKycBadge(BuildContext context, String? status) {
    if (status == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = switch (status) {
      'approved' => ('Verified', AppColors.accent),
      'pending' => ('Pending', AppColors.warning),
      'rejected' => ('Rejected', AppColors.danger),
      _ => (
          'Unverified',
          isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
