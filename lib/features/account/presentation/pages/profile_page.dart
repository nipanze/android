// lib/features/account/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  final _formKey = GlobalKey<FormState>();
  String? _district;
  String? _employmentType;
  bool _populated = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _employerController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(ProfileCubitLoaded state) {
    if (_populated) return;
    // Fix: state.profile is UserProfile (non-null) — null check removed
    final p = state.profile;
    _nameController.text = p.fullName ?? '';
    _phoneController.text = p.phone ?? '';
    _employerController.text = p.employerName ?? '';
    _district = p.district;
    _employmentType = p.employmentType;
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
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            context.read<ProfileCubit>().updateProfile(
                                  fullName: _nameController.text.trim(),
                                  phone: _phoneController.text.trim().isEmpty
                                      ? null
                                      : _phoneController.text.trim(),
                                  district: _district,
                                  employmentType: _employmentType,
                                  employerName:
                                      _employerController.text.trim().isEmpty
                                          ? null
                                          : _employerController.text.trim(),
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
