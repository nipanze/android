// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _formKey = GlobalKey<FormState>();
  String? _district;
  String? _employmentType;
  bool _populated = false;

  // Filter preferences
  final Set<String> _selectedEmploymentTypes = {};
  String? _selectedIncomeBracket;
  bool _prefersSuggestedTerms = false;
  bool _prefersVerifiedOnly = false;

  static const _districts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Mbale',
    'Gulu',
    'Mbarara',
    'Masaka',
    'Lira',
    'Soroti',
    'Arua',
    'Fort Portal',
    'Kabale',
    'Other',
  ];

  static const _employmentTypes = [
    ('employed', 'Employed'),
    ('government_employee', 'Government employee'),
    ('self_employed', 'Self-employed'),
    ('small_business_owner', 'Small business owner'),
    ('business_owner', 'Business owner'),
    ('student', 'Student'),
    ('other', 'Other'),
  ];

  static const _incomeBrackets = [
    ('under_2m', 'Under 2M UGX / month'),
    ('2m_5m', '2M – 5M UGX / month'),
    ('5m_10m', '5M – 10M UGX / month'),
    ('over_10m', 'Over 10M UGX / month'),
  ];

  String? _fnIncomeBracket(int? monthlyIncomeUgx) {
    if (monthlyIncomeUgx == null) return null;
    if (monthlyIncomeUgx < 2000000) return 'under_2m';
    if (monthlyIncomeUgx < 5000000) return '2m_5m';
    if (monthlyIncomeUgx < 10000000) return '5m_10m';
    return 'over_10m';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _employerController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(ProfileCubitLoaded state) {
    if (_populated) return;
    final p = state.profile;
    _nameController.text = p.fullName ?? '';
    _phoneController.text = p.phone ?? '';
    _employerController.text = p.employerName ?? '';
    _incomeController.text = p.monthlyIncomeUgx == null
        ? ''
        : NumberFormat('#,##0').format(p.monthlyIncomeUgx);
    _district = p.district;
    _employmentType = p.employmentType;

    _selectedEmploymentTypes
      ..clear()
      ..addAll(p.preferredEmploymentTypes ?? const []);
    _selectedIncomeBracket = p.preferredIncomeBracket ??
        _fnIncomeBracket(p.monthlyIncomeUgx);
    _prefersSuggestedTerms = p.prefersSuggestedTerms;
    _prefersVerifiedOnly = p.prefersVerifiedOnly;

    _populated = true;
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
            context.pop();
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

          if (state is ProfileCubitLoaded) _populateIfNeeded(state);
          final isSaving = state is ProfileCubitSaving;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+256 7XX XXX XXX',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _district,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    hint: const Text('Select district'),
                    items: _districts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _district = v),
                  ),
                  const SizedBox(height: 14),
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
                  TextFormField(
                    controller: _employerController,
                    decoration: const InputDecoration(
                      labelText: 'Employer / Business name (optional)',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly income (UGX)',
                      hintText: 'e.g. 1,500,000',
                      prefixIcon: Icon(Icons.currency_exchange_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Advanced filter preferences ──────────────────────────
                  const Text(
                    'Advanced filter preferences',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'These settings are used as defaults when you open Advanced '
                    'Filters in the marketplace.',
                    style: TextStyle(fontSize: 12, color: AppColors.text2Light),
                  ),
                  const SizedBox(height: 16),

                  // Employment type chips
                  const Text(
                    'Employment type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _employmentTypes.map((opt) {
                      final selected =
                          _selectedEmploymentTypes.contains(opt.$1);
                      return _FilterChip(
                        label: opt.$2,
                        selected: selected,
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedEmploymentTypes.remove(opt.$1);
                          } else {
                            _selectedEmploymentTypes.add(opt.$1);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Income bracket chips
                  const Text(
                    'Monthly income range',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _incomeBrackets.map((opt) {
                      final selected = _selectedIncomeBracket == opt.$1;
                      return _FilterChip(
                        label: opt.$2,
                        selected: selected,
                        onTap: () => setState(
                          () => _selectedIncomeBracket = opt.$1,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Boolean toggles
                  _ToggleTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.accent,
                    title: 'Has suggested terms',
                    subtitle:
                        'Prefer Pro-posted listings with locked interest rate, late fee, and repayment schedule',
                    value: _prefersSuggestedTerms,
                    onChanged: (v) =>
                        setState(() => _prefersSuggestedTerms = v),
                  ),
                  const SizedBox(height: 10),
                  _ToggleTile(
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.success,
                    title: 'Verified borrower',
                    subtitle:
                        'Prefer listings from KYC-approved account holders',
                    value: _prefersVerifiedOnly,
                    onChanged: (v) =>
                        setState(() => _prefersVerifiedOnly = v),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            final incomeText = _incomeController.text.trim();
                            final monthlyIncomeUgx = incomeText.isEmpty
                                ? null
                                : int.tryParse(incomeText.replaceAll(',', ''));
                            context.read<ProfileCubit>().updateProfile(
                                  fullName: _nameController.text.trim(),
                                  phone:
                                      _phoneController.text.trim().isEmpty
                                          ? null
                                          : _phoneController.text.trim(),
                                  district: _district,
                                  employmentType: _employmentType,
                                  employerName:
                                      _employerController.text.trim().isEmpty
                                          ? null
                                          : _employerController.text.trim(),
                                  monthlyIncomeUgx: monthlyIncomeUgx,
                                  preferredEmploymentTypes:
                                      _selectedEmploymentTypes.isNotEmpty
                                          ? _selectedEmploymentTypes.toList()
                                          : null,
                                  preferredIncomeBracket: _selectedIncomeBracket,
                                  prefersSuggestedTerms: _prefersSuggestedTerms,
                                  prefersVerifiedOnly: _prefersVerifiedOnly,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.purple
                : AppColors.borderDark.withValues(alpha: 0.5),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.purple : null,
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withValues(alpha: 0.35),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
