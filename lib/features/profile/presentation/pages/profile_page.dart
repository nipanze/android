// lib/features/profile/presentation/pages/profile_page.dart
// ignore_for_file: unused_import, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop()),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(32)),
                child: Center(
                    child: Text(
                        user?.fullName?.isNotEmpty == true
                            ? user!.fullName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)))),
            const SizedBox(height: 12),
            Text(user?.fullName ?? 'User',
                style: Theme.of(context).textTheme.titleMedium),
            Text(user?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            const SizedBox(height: 20),
            SectionHeader('Details'),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      _Row('Email', user?.email ?? '—'),
                      const Divider(height: 16),
                      _Row('Phone', user?.phone ?? '—'),
                      const Divider(height: 16),
                      _Row('District', user?.district ?? '—'),
                      const Divider(height: 16),
                      _Row('Street / road', user?.streetAddress ?? '—'),
                    ]))),
            const SizedBox(height: 16),
            SectionHeader('Employment & Income'),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      _Row('Employment type',
                          _employmentLabel(user?.employmentType)),
                      const Divider(height: 16),
                      _Row('Employer', user?.employerName ?? '—'),
                      const Divider(height: 16),
                      _Row('Monthly income',
                          user?.monthlyIncomeUgx != null
                              ? 'UGX ${_fmtAmount(user!.monthlyIncomeUgx!)}'
                              : '—'),
                    ]))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _openEditProfile(context, user),
                child: const Text('Edit profile'),
              ),
            ),
          ])),
    );
  }

  String _employmentLabel(EmploymentType? type) {
    switch (type) {
      case EmploymentType.employed:
        return 'Employed (private)';
      case EmploymentType.governmentEmployee:
        return 'Government employee';
      case EmploymentType.selfEmployed:
        return 'Self-employed';
      case EmploymentType.smallBusinessOwner:
        return 'Small business owner';
      case EmploymentType.businessOwner:
        return 'Business owner';
      case EmploymentType.student:
        return 'Student';
      case EmploymentType.other:
        return 'Other';
      case null:
        return '—';
    }
  }

  String _fmtAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  void _openEditProfile(BuildContext context, NipanzeUser? user) {
    if (user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditProfilePage(user: user),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.l, this.v);
  final String l, v;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(l, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(v,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
      ]);
}

// ── Edit Profile Page ──────────────────────────────────────────────────────

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.user});
  final NipanzeUser user;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _employerCtrl;
  late final TextEditingController _incomeCtrl;
  EmploymentType? _employmentType;
  bool _saving = false;

  static const _employmentOptions = [
    EmploymentType.employed,
    EmploymentType.governmentEmployee,
    EmploymentType.selfEmployed,
    EmploymentType.smallBusinessOwner,
    EmploymentType.businessOwner,
    EmploymentType.student,
    EmploymentType.other,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _districtCtrl = TextEditingController(text: widget.user.district ?? '');
    _streetCtrl = TextEditingController(text: widget.user.streetAddress ?? '');
    _employerCtrl = TextEditingController(text: widget.user.employerName ?? '');
    _incomeCtrl = TextEditingController(
        text: widget.user.monthlyIncomeUgx != null
            ? widget.user.monthlyIncomeUgx.toString()
            : '');
    _employmentType = widget.user.employmentType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _districtCtrl.dispose();
    _streetCtrl.dispose();
    _employerCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Full name', _nameCtrl),
          const SizedBox(height: 14),
          _field('Phone', _phoneCtrl),
          const SizedBox(height: 14),
          _field('District', _districtCtrl),
          const SizedBox(height: 14),
          _field('Street / road', _streetCtrl),
          const SizedBox(height: 14),
          DropdownButtonFormField<EmploymentType>(
            initialValue: _employmentType,
            decoration: const InputDecoration(
              labelText: 'Employment type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _employmentOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(_label(e))))
                .toList(),
            onChanged: (v) => setState(() => _employmentType = v),
          ),
          const SizedBox(height: 14),
          _field('Employer name', _employerCtrl),
          const SizedBox(height: 14),
          _field('Monthly income (UGX)', _incomeCtrl, numeric: true),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  String _label(EmploymentType t) {
    switch (t) {
      case EmploymentType.employed:
        return 'Employed (private)';
      case EmploymentType.governmentEmployee:
        return 'Government employee';
      case EmploymentType.selfEmployed:
        return 'Self-employed';
      case EmploymentType.smallBusinessOwner:
        return 'Small business owner';
      case EmploymentType.businessOwner:
        return 'Business owner';
      case EmploymentType.student:
        return 'Student';
      case EmploymentType.other:
        return 'Other';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = getIt<AuthRepository>();
      await repo.updateProfile(
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        district:
            _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
        streetAddress:
            _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
        employmentType: NipanzeUser.employmentToString(_employmentType),
        employerName:
            _employerCtrl.text.trim().isEmpty ? null : _employerCtrl.text.trim(),
        monthlyIncome: int.tryParse(_incomeCtrl.text.trim()),
      );
      // Refresh auth state so the profile page updates
      if (mounted) {
        context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
