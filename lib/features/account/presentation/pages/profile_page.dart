// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';

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

  static const _employmentTypes = [
    ('employed', 'Employed'),
    ('government_employee', 'Government employee'),
    ('self_employed', 'Self-employed'),
    ('small_business_owner', 'Small business owner'),
    ('business_owner', 'Business owner'),
    ('student', 'Student'),
    ('other', 'Other'),
  ];

  static const _institutionOptions = [
    ('', 'Individual / Personal account'),
    ('bank', 'Bank'),
    ('forex_exchange', 'Forex exchange company'),
    ('sacco', 'SACCO'),
    ('company', 'Company'),
  ];

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

    // Auto-detect country from phone prefix or default to Uganda
    final matchedCountry = EastAfricaCountries.findByPhone(p.phone);
    _selectedCountry = matchedCountry;

    // Strip dial code for local phone field display
    final rawPhone = p.phone ?? '';
    if (rawPhone.startsWith(matchedCountry.dialCode)) {
      _phoneController.text = rawPhone.substring(matchedCountry.dialCode.length).trim();
    } else {
      _phoneController.text = rawPhone;
    }

    // Validate district against selected country's regions
    if (p.district != null && matchedCountry.regions.contains(p.district)) {
      _district = p.district;
    } else if (p.district != null && EastAfricaCountries.uganda.regions.contains(p.district)) {
      _district = p.district;
    } else {
      _district = null;
    }

    _employmentType = _employmentTypes.any((e) => e.$1 == p.employmentType)
        ? p.employmentType
        : null;

    _populated = true;
  }

  String _formatFullPhoneNumber() {
    final local = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (local.isEmpty) return '';
    if (local.startsWith('+')) return local;
    final dial = _selectedCountry.dialCode;
    final cleanLocal = local.startsWith('0') ? local.substring(1) : local;
    return '$dial$cleanLocal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit profile'),
      ),
      body: BlocConsumer<ProfileCubit, ProfileCubitState>(
        listener: (context, state) {
          if (state is ProfileCubitLoaded && state.justSaved) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Profile saved.')));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.pop();
            });
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
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
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
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ProfileCubitLoaded) _populateIfNeeded(state);
          final isSaving = state is ProfileCubitSaving;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Full Name ─────────────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // ── WhatsApp-Style Merged Country & Phone Field ───────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: '7XX XXX XXX',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20)),
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
                  ),
                  const SizedBox(height: 14),

                  // ── Regional / District Dropdown ──────────────────────────
                  DropdownButtonFormField<String>(
                    key: ValueKey('district_${_selectedCountry.code}'),
                    initialValue: _district,
                    decoration: InputDecoration(
                      labelText: _selectedCountry.regionsLabel,
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    ),
                    hint: Text('Select ${_selectedCountry.regionsLabel.toLowerCase()}'),
                    items: _selectedCountry.regions
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _district = v),
                  ),
                  const SizedBox(height: 14),

                  // ── Income Type Dropdown ──────────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _employmentType,
                    decoration: const InputDecoration(
                      labelText: 'Income type',
                      prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                    ),
                    hint: const Text('Select income type'),
                    items: _employmentTypes
                        .map((e) =>
                            DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) => setState(() => _employmentType = v),
                  ),
                  const SizedBox(height: 14),

                  // ── Employer Name ──────────────────────────────────────────
                  TextFormField(
                    controller: _employerController,
                    decoration: const InputDecoration(
                      labelText: 'Employer / Business name (optional)',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Monthly Income (Currency Scalable) ────────────────────
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monthly income (${_selectedCountry.currency})',
                      hintText: 'e.g. 1,500,000',
                      prefixIcon: const Icon(Icons.currency_exchange_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Bank & Professional Tag Section ───────────────────────
                  const Text(
                    'Bank & Professional Tag',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Preferred / Deposit Bank Field
                  TextFormField(
                    controller: _preferredBankController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred or deposit bank (optional)',
                      hintText: 'e.g. Equity Bank, Bank of Kigali, Stanbic, KCB',
                      prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Institution Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _institutionType ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Account represents',
                      prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                    ),
                    items: _institutionOptions
                        .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _institutionType = (v == null || v.isEmpty) ? null : v),
                  ),
                  const SizedBox(height: 8),

                  // Is Bank Agent Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I am a bank loan agent'),
                    subtitle: const Text(
                        'Shows a bank-agent tag to Pro users seeking bank loans.'),
                    value: _isBankAgent,
                    onChanged: (v) => setState(() => _isBankAgent = v),
                  ),

                  // Show Professional Tag Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show my professional tag'),
                    subtitle: const Text(
                        'Turn off to hide bank, forex company, SACCO, or agent labels on offers.'),
                    value: _showProfessionalTag,
                    onChanged: (v) => setState(() => _showProfessionalTag = v),
                  ),
                  const SizedBox(height: 28),

                  // ── Save Button ────────────────────────────────────────────
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            final incomeText = _incomeController.text.trim();
                            final monthlyIncome = incomeText.isEmpty
                                ? null
                                : int.tryParse(incomeText.replaceAll(',', ''));
                            final fullPhone = _formatFullPhoneNumber();

                            context.read<ProfileCubit>().updateProfile(
                                  fullName: _nameController.text.trim(),
                                  phone: fullPhone.isEmpty ? null : fullPhone,
                                  district: _district,
                                  employmentType: _employmentType,
                                  employerName:
                                      _employerController.text.trim().isEmpty
                                          ? null
                                          : _employerController.text.trim(),
                                  monthlyIncome: monthlyIncome,
                                  preferredBank: _preferredBankController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : _preferredBankController.text.trim(),
                                  institutionType: _institutionType ?? '',
                                  isBankAgent: _isBankAgent,
                                  showProfessionalTag: _showProfessionalTag,
                                );
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
