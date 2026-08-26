// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
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
  final _phoneController = TextEditingController();
  final _employerController = TextEditingController();
  final _incomeController = TextEditingController();
  final _preferredBankController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CountryInfo _selectedCountry = EastAfricaCountries.defaultCountry;
  String? _district;
  String? _employmentType;
  String? _institutionType;
  bool _isBankAgent = false;
  bool _showProfessionalTag = true;
  bool _populated = false;
  bool _hasChanges = false;

  String _userInitials = 'U';

  static const _employmentTypes = [
    'employed',
    'government_employee',
    'self_employed',
    'small_business_owner',
    'business_owner',
    'student',
    'other',
  ];

  static const _institutionOptions = [
    '',
    'bank',
    'forex_exchange',
    'sacco',
    'company',
  ];

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
    _phoneController.dispose();
    _employerController.dispose();
    _incomeController.dispose();
    _preferredBankController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(ProfileCubitLoaded state) {
    if (_populated) return;
    final p = state.profile;
    _nameController.text = p.fullName ?? '';
    _employerController.text = p.employerName ?? '';
    _incomeController.text = p.monthlyIncomeUgx == null
        ? ''
        : NumberFormat('#,##0').format(p.monthlyIncomeUgx);
    _preferredBankController.text = p.preferredBank ?? '';
    _institutionType = p.institutionType;
    _isBankAgent = p.isBankAgent;
    _showProfessionalTag = p.showProfessionalTag;
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

    _employmentType =
        _employmentTypes.contains(p.employmentType) ? p.employmentType : null;

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

    final loadedState =
        cubitState is ProfileCubitLoaded ? cubitState : null;
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
                          Text(l10n?.pickExistingPhoto ?? 'Pick an existing photo',
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

    final source = option == 'camera' ? ImageSource.camera : ImageSource.gallery;

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

  String _employmentLabel(AppLocalizations? l10n, String value) {
    switch (value) {
      case 'government_employee':
        return l10n?.empGovEmployee ?? 'Government employee';
      case 'employed':
        return l10n?.empEmployedPrivate ?? 'Employed (private)';
      case 'self_employed':
        return l10n?.empSelfEmployed ?? 'Self-employed';
      case 'small_business_owner':
        return l10n?.empSmallBusinessOwner ?? 'Small business owner';
      case 'business_owner':
        return l10n?.empBusinessOwner ?? 'Business owner';
      case 'student':
        return l10n?.empStudent ?? 'Student';
      default:
        return l10n?.empOther ?? 'Other';
    }
  }

  String _institutionLabel(AppLocalizations? l10n, String value) {
    switch (value) {
      case 'bank':
        return l10n?.bankLabel ?? 'Bank';
      case 'forex_exchange':
        return l10n?.forexExchangeCompanyLabel ?? 'Forex exchange company';
      case 'sacco':
        return l10n?.saccoLabel ?? 'SACCO';
      case 'company':
        return l10n?.companyLabel ?? 'Company';
      default:
        return l10n?.individualPersonalAccountLabel ??
            'Individual / Personal account';
    }
  }

  Future<void> _saveProfile(
      BuildContext context, AppLocalizations? l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ProfileCubit>();
    final currentCubitState = cubit.state;
    final loaded = currentCubitState is ProfileCubitLoaded
        ? currentCubitState
        : null;
    final pendingBytes = loaded?.pendingAvatarBytes;
    final clearAvatar = loaded?.pendingAvatarRemoved ?? false;
    String? finalAvatarUrl = clearAvatar ? null : loaded?.profile.avatarUrl;

    if (pendingBytes != null) {
      try {
        final repo = getIt<ProfileRepository>();
        finalAvatarUrl = await repo.uploadAvatarBytes(pendingBytes, 'jpg');
      } catch (uploadErr) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(
            content: Text(l10n?.avatarUploadFailed(uploadErr.toString()) ??
                'Avatar upload failed: $uploadErr'),
            backgroundColor: AppColors.danger,
          ));
        }
        return;
      }
    }

    final incomeText = _incomeController.text.trim();
    final monthlyIncome = incomeText.isEmpty
        ? null
        : int.tryParse(incomeText.replaceAll(',', ''));
    final fullPhone = _formatFullPhoneNumber();

    if (!mounted) return;
    await cubit.updateProfile(
      fullName: _nameController.text.trim(),
      avatarUrl: finalAvatarUrl,
      clearAvatar: clearAvatar,
      phone: fullPhone.isEmpty ? null : fullPhone,
      district: _district,
      employmentType: _employmentType,
      employerName: _employerController.text.trim().isEmpty
          ? null
          : _employerController.text.trim(),
      monthlyIncome: monthlyIncome,
      preferredBank: _preferredBankController.text.trim().isEmpty
          ? null
          : _preferredBankController.text.trim(),
      institutionType: _institutionType ?? '',
      isBankAgent: _isBankAgent,
      showProfessionalTag: _showProfessionalTag,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.profileSaved ?? 'Profile saved.'),
                ),
              );
              // Refresh AuthBloc so top bars update immediately
              try {
                context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
              } catch (_) {}
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.pop();
              });
            }
          }
          if (state is ProfileCubitError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ));
          }
        },
        builder: (context, state) {
          if (state is ProfileCubitLoading || state is ProfileCubitInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileCubitError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<ProfileCubit>().load(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n?.tryAgain ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isSaving = state is ProfileCubitSaving;

          final loadedState = state is ProfileCubitLoaded ? state : null;
          final pendingBytes = loadedState?.pendingAvatarBytes;
          final isAvatarRemoved = loadedState?.pendingAvatarRemoved ?? false;
          final avatarUrl = isAvatarRemoved ? null : loadedState?.profile.avatarUrl;

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
                  const SizedBox(height: 16),

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
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCountry.flag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 5),
                            Text(
                              _selectedCountry.dialCode,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                  const SizedBox(height: 14),

                  // ── Income Type Dropdown ──────────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _employmentType,
                    decoration: InputDecoration(
                      labelText: l10n?.incomeTypeLabel ?? 'Income type',
                      prefixIcon:
                          const Icon(Icons.work_outline_rounded, size: 20),
                    ),
                    hint: Text(l10n?.selectIncomeType ?? 'Select income type'),
                    items: _employmentTypes
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(_employmentLabel(l10n, e)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _employmentType = v);
                      _markChanged();
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Employer Name ──────────────────────────────────────────
                  TextFormField(
                    controller: _employerController,
                    decoration: InputDecoration(
                      labelText: l10n?.employerBusinessOptionalLabel ??
                          'Employer / Business name (optional)',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20),
                    ),
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: 14),

                  // ── Monthly Income (Currency Scalable) ────────────────────
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n?.monthlyIncomeWithCurrency(
                            _selectedCountry.currency,
                          ) ??
                          'Monthly income (${_selectedCountry.currency})',
                      hintText: 'e.g. 1,500,000',
                      prefixIcon: const Icon(Icons.currency_exchange_outlined,
                          size: 20),
                    ),
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: 24),

                  // ── Bank & Professional Tag Section ───────────────────────
                  Text(
                    l10n?.bankProfessionalTagLabel ?? 'Bank & Professional Tag',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preferred / Deposit Bank Field
                  TextFormField(
                    controller: _preferredBankController,
                    decoration: InputDecoration(
                      labelText: l10n?.preferredDepositBankLabel ??
                          'Preferred or deposit bank (optional)',
                      hintText: l10n?.preferredDepositBankHint ??
                          'e.g. Equity Bank, Bank of Kigali, Stanbic, KCB',
                      prefixIcon: const Icon(
                        Icons.account_balance_outlined,
                        size: 20,
                      ),
                    ),
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: 14),

                  // Institution Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _institutionType ?? '',
                    decoration: InputDecoration(
                      labelText:
                          l10n?.accountRepresentsLabel ?? 'Account represents',
                      prefixIcon: const Icon(
                        Icons.business_center_outlined,
                        size: 20,
                      ),
                    ),
                    items: _institutionOptions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(_institutionLabel(l10n, e)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _institutionType =
                          (v == null || v.isEmpty) ? null : v);
                      _markChanged();
                    },
                  ),
                  const SizedBox(height: 8),

                  // Is Bank Agent Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n?.bankLoanAgentLabel ?? 'I am a bank loan agent',
                    ),
                    subtitle: Text(
                      l10n?.bankLoanAgentSubtitle ??
                          'Shows a bank-agent tag to Pro users seeking bank loans.',
                    ),
                    value: _isBankAgent,
                    onChanged: (v) {
                      setState(() => _isBankAgent = v);
                      _markChanged();
                    },
                  ),

                  // Show Professional Tag Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n?.showProfessionalTagLabel ??
                          'Show my professional tag',
                    ),
                    subtitle: Text(
                      l10n?.showProfessionalTagSubtitle ??
                          'Turn off to hide bank, forex company, SACCO, or agent labels on offers.',
                    ),
                    value: _showProfessionalTag,
                    onChanged: (v) {
                      setState(() => _showProfessionalTag = v);
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
}
