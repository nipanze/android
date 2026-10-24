// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/data/profile_repository.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../kyc/presentation/cubit/kyc_cubit.dart';
import '../../../kyc/presentation/widgets/kyc_required_documents_section.dart';
import '../../../provider/domain/repositories/provider_repository_interface.dart';
import '../../../provider/presentation/widgets/additional_verification_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(),
      child: BlocProvider(
        create: (_) => getIt<KycCubit>()..load(),
        child: const _ProfileView(),
      ),
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
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CountryInfo _selectedCountry = EastAfricaCountries.defaultCountry;
  String? _district;
  bool _populated = false;
  bool _hasChanges = false;
  bool _providerProfilesEnabled = false;
  bool _avatarUploading = false;
  String? _initialName;
  String? _initialDistrict;

  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refreshChanges);
    _loadProviderAccess();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(ProfileCubitLoaded state) {
    if (_populated) return;
    final p = state.profile;
    _nameController.text = p.fullName ?? '';
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
    _initialName = _nameController.text.trim();
    _initialDistrict = _district;
    _hasChanges = false;
  }

  Future<void> _loadProviderAccess() async {
    try {
      final enabled =
          await getIt<IProviderRepository>().capabilityProfilesEnabled();
      if (mounted) setState(() => _providerProfilesEnabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _providerProfilesEnabled = false);
    }
  }

  bool get _hasPendingAvatarChange {
    final state = context.read<ProfileCubit>().state;
    return state is ProfileCubitLoaded &&
        (state.pendingAvatarBytes != null || state.pendingAvatarRemoved);
  }

  void _refreshChanges() {
    if (!_populated) return;
    final changed = _nameController.text.trim() != _initialName ||
        _district != _initialDistrict ||
        _hasPendingAvatarChange;
    if (_hasChanges != changed) setState(() => _hasChanges = changed);
  }

  void _markChanged() {
    _refreshChanges();
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
      if (bytes.isEmpty || bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw StateError(l10n?.avatarImageTooLarge ??
            'Choose an image that is 5 MB or smaller.');
      }
      final pickedExtension = picked.name.split('.').last.toLowerCase();
      final mime = picked.mimeType?.toLowerCase();
      final extension = switch (mime) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/jpeg' => 'jpg',
        _ => switch (pickedExtension) {
            'png' => 'png',
            'webp' => 'webp',
            'jpg' || 'jpeg' => 'jpg',
            _ => '',
          },
      };
      if (extension.isEmpty) {
        throw StateError(l10n?.avatarImageUnsupported ??
            'Choose a JPG, PNG, or WebP image.');
      }
      cubit.setPendingAvatar(bytes, extension: extension);
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
      _hasChanges &&
      !_avatarUploading &&
      _nameController.text.trim().isNotEmpty;

  Future<void> _saveProfile(
      BuildContext context, AppLocalizations? l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ProfileCubit>();
    if (!await ensureOnlineForAction(context)) return;

    final currentCubitState = cubit.state;
    final loaded =
        currentCubitState is ProfileCubitLoaded ? currentCubitState : null;
    final pendingBytes = loaded?.pendingAvatarBytes;
    final pendingExtension = loaded?.pendingAvatarExtension ?? 'jpg';
    final clearAvatar = loaded?.pendingAvatarRemoved ?? false;
    String? finalAvatarUrl = clearAvatar ? null : loaded?.profile.avatarUrl;

    if (pendingBytes != null) {
      setState(() => _avatarUploading = true);
      try {
        final repo = getIt<ProfileRepository>();
        finalAvatarUrl = await repo.uploadAvatarBytes(
          pendingBytes,
          pendingExtension,
        );
      } catch (uploadErr) {
        if (mounted) {
          final message = userFacingErrorMessage(uploadErr);
          messenger.showSnackBar(SnackBar(
            content: Text(l10n?.avatarUploadFailed(message) ??
                'Avatar upload failed: $message'),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: l10n?.retry ?? 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveProfile(context, l10n),
            ),
          ));
        }
        return;
      } finally {
        if (mounted) setState(() => _avatarUploading = false);
      }
    }

    if (!mounted) return;
    await cubit.updateProfile(
      fullName: _nameController.text.trim(),
      avatarUrl: finalAvatarUrl,
      clearAvatar: clearAvatar,
      district: _district ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<KycCubit, KycState>(
      listener: (context, state) {
        if (state is KycLoaded) {
          context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
          title:
              Text(l10n?.profileVerificationTitle ?? 'Profile & Verification'),
        ),
        body: BlocConsumer<ProfileCubit, ProfileCubitState>(
          listener: (context, state) {
            if (state is ProfileCubitLoaded) {
              _populateIfNeeded(state);
              if (state.justSaved) {
                _initialName = state.profile.fullName?.trim() ?? '';
                _initialDistrict = state.profile.district;
                _hasChanges = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.profileSaved ?? 'Profile saved.',
                    ),
                  ),
                );
                // Refresh AuthBloc so top bars update immediately
                try {
                  context
                      .read<AuthBloc>()
                      .add(const AuthProfileRefreshRequested());
                } catch (_) {}
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.pop();
                });
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
            final kycState = context.watch<KycCubit>().state;
            final kyc = switch (kycState) {
              KycLoaded() => kycState.kyc,
              KycUploading() => kycState.kyc,
              KycSubmitting() => kycState.kyc,
              KycError() => kycState.kyc,
              _ => null,
            };
            final kycStatus = kyc?.status ??
                loadedState?.profile.kycStatus ??
                'not_submitted';
            final expiry = kyc?.expiresAt ?? loadedState?.profile.kycExpiresAt;
            final daysUntilExpiry = expiry?.difference(DateTime.now()).inDays;
            final showExpiry = kycStatus == 'approved' &&
                daysUntilExpiry != null &&
                daysUntilExpiry >= 0 &&
                daysUntilExpiry <= 30;
            final authState = context.watch<AuthBloc>().state;
            final authUser =
                authState is AuthAuthenticated ? authState.user : null;
            final isKycApproved = kycStatus == 'approved';
            final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          l10n?.changeProfilePicture ??
                              'Change profile picture',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_avatarUploading) ...[
                      const SizedBox(height: 4),
                      Semantics(
                        label: l10n?.profilePhotoUploading ??
                            'Uploading profile picture',
                        child: const LinearProgressIndicator(minHeight: 3),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ── KYC Approval Status ───────────────────────────────────
                    Card(
                      key: const ValueKey('kyc_access_card'),
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: isKycApproved
                          ? (isDark
                              ? const Color(0xFF103D32)
                              : const Color(0xFFE8F7EF))
                          : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isKycApproved
                              ? (isDark
                                  ? const Color(0xFF167A5A)
                                  : const Color(0xFF69C58D))
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _kycStatusIcon(kycStatus),
                                  color: _kycStatusColor(kycStatus, isDark),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _kycStatusLabel(l10n, kycStatus),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _kycStatusDescription(l10n, kycStatus),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isKycApproved
                                              ? (isDark
                                                  ? const Color(0xFFB5D8C8)
                                                  : const Color(0xFF53665D))
                                              : (isDark
                                                  ? AppColors.text2Dark
                                                  : AppColors.text2Light),
                                        ),
                                      ),
                                      if (kycStatus == 'rejected' &&
                                          kyc?.rejectionReason?.isNotEmpty ==
                                              true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          kyc!.rejectionReason!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ],
                                      if (showExpiry && expiry != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            l10n?.kycExpires(DateFormat(
                                                  'dd/MM/yyyy',
                                                  Localizations.localeOf(
                                                          context)
                                                      .languageCode,
                                                ).format(expiry)) ??
                                                'Expires ${DateFormat('dd/MM/yyyy').format(expiry)}',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _buildKycBadge(context, kycStatus),
                              ],
                            ),
                            if (!isKycApproved && loadedState != null) ...[
                              const SizedBox(height: 12),
                              KycRequiredDocumentsSection(
                                hasProfilePhoto: avatarUrl?.isNotEmpty == true,
                                showRejectionReason: false,
                              ),
                            ],
                            const SizedBox(height: 14),
                          MarketplaceAccessSummary(
                              isKycApproved: isKycApproved,
                              canBorrow: authUser?.canBorrow == true,
                              canLend: authUser?.canLend == true,
                              canOfferService: _providerProfilesEnabled,
                            ),
                          ],
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
                      readOnly: true,
                      showCursor: false,
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
                        suffixIcon: const Icon(Icons.lock_outline_rounded),
                      ),
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
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _district = v);
                        _markChanged();
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_providerProfilesEnabled)
                      const AdditionalVerificationSection(),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<ProfileCubit, ProfileCubitState>(
          builder: (context, state) {
            final isSaving = state is ProfileCubitSaving || _avatarUploading;
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
      ),
    );
  }

  Widget _buildKycBadge(BuildContext context, String? status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = switch (status) {
      'approved' => (
          AppLocalizations.of(context)!.kycStatusApproved,
          isDark ? const Color(0xFF4ADE80) : const Color(0xFF16834B),
        ),
      'pending' => (
          AppLocalizations.of(context)!.kycStatusPending,
          AppColors.warning
        ),
      'rejected' => (
          AppLocalizations.of(context)!.kycStatusRejected,
          AppColors.danger
        ),
      'expired' => (
          AppLocalizations.of(context)!.kycStatusExpired,
          AppColors.danger
        ),
      _ => (
          AppLocalizations.of(context)!.kycStatusNotStarted,
          isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_kycStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  IconData _kycStatusIcon(String? status) => switch (status) {
        'approved' => Icons.verified_rounded,
        'pending' => Icons.hourglass_top_rounded,
        'rejected' || 'expired' => Icons.error_outline_rounded,
        _ => Icons.info_outline_rounded,
      };

  Color _kycStatusColor(String? status, bool isDark) => switch (status) {
        'approved' =>
          isDark ? const Color(0xFF4ADE80) : const Color(0xFF16834B),
        'pending' => AppColors.warning,
        'rejected' || 'expired' => AppColors.danger,
        _ => isDark ? AppColors.text2Dark : AppColors.text2Light,
      };

  String _kycStatusLabel(AppLocalizations? l10n, String? status) =>
      switch (status) {
        'approved' => l10n?.kycStatusApproved ?? 'KYC Approved',
        'pending' => l10n?.kycStatusPending ?? 'Under review',
        'rejected' => l10n?.kycStatusRejected ?? 'Rejected',
        'expired' => l10n?.kycStatusExpired ?? 'Expired',
        _ => l10n?.kycStatusNotStarted ?? 'Not started',
      };

  String _kycStatusDescription(AppLocalizations? l10n, String? status) =>
      switch (status) {
        'approved' => l10n?.kycStatusApprovedDesc ??
            'Identity verified. You can now create listings.',
        'pending' => l10n?.kycStatusPendingDesc ??
            'Documents submitted. Admin review in progress.',
        'rejected' => l10n?.kycStatusRejectedDesc ??
            'Submission rejected. Please re-upload and resubmit.',
        'expired' => l10n?.kycStatusExpiredDesc ??
            'Your KYC has expired. Please re-verify.',
        _ => l10n?.kycStatusNotSubmittedDesc ??
            'Submit documents to unlock listing creation.',
      };
}

class MarketplaceAccessSummary extends StatelessWidget {
  const MarketplaceAccessSummary({
    super.key,
    required this.isKycApproved,
    required this.canBorrow,
    required this.canLend,
    required this.canOfferService,
  });

  final bool isKycApproved;
  final bool canBorrow;
  final bool canLend;
  final bool canOfferService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(String, IconData, bool)>[
      (
        l10n.accessLoanRequests,
        Icons.request_quote_outlined,
        isKycApproved && canBorrow
      ),
      (
        l10n.accessForexRequests,
        Icons.currency_exchange_rounded,
        isKycApproved && canBorrow
      ),
      (
        l10n.accessNeedRequests,
        Icons.volunteer_activism_outlined,
        isKycApproved && canBorrow
      ),
      (l10n.accessMakeOffers, Icons.handshake_outlined, canLend),
      (l10n.accessOfferService, Icons.storefront_outlined, canOfferService),
    ];
    final unlockedCount = items.where((item) => item.$3).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.marketplaceAccessSummary,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l10n.marketplaceAccessCount(unlockedCount)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              _MarketplaceAccessChip(
                label: item.$1,
                icon: item.$2,
                unlocked: item.$3,
              ),
          ],
        ),
      ],
    );
  }
}

class _MarketplaceAccessChip extends StatelessWidget {
  const _MarketplaceAccessChip({
    required this.label,
    required this.icon,
    required this.unlocked,
  });

  final String label;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = unlocked
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minHeight: 44, maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? 0.10 : 0.06),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(unlocked ? icon : Icons.lock_outline_rounded,
              size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label · ${unlocked ? l10n.accessUnlocked : l10n.accessLocked}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
