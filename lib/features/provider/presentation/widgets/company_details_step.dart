import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_company_profile.dart';
import '../../domain/repositories/provider_repository_interface.dart';

class CompanyDetailsStep extends StatefulWidget {
  const CompanyDetailsStep({
    super.key,
    required this.categorySlug,
    required this.serviceCount,
    required this.roleCount,
    required this.initialProfile,
    this.verificationSubmissions = const [],
    required this.providerRepository,
    required this.onDraftChanged,
    required this.onSave,
  });

  final String categorySlug;
  final int serviceCount;
  final int roleCount;
  final ProviderCompanyProfile? initialProfile;
  final List<Map<String, dynamic>> verificationSubmissions;
  final IProviderRepository providerRepository;
  final ValueChanged<ProviderCompanyProfile> onDraftChanged;
  final Future<void> Function({required Map<String, dynamic> profile}) onSave;

  @override
  State<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends State<CompanyDetailsStep> {
  final _nameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _areasController = TextEditingController();
  String? _teamSize;
  String? _yearsInBusiness;
  late List<Map<String, dynamic>> _verificationSubmissions;
  String? _uploadingDocumentType;
  bool _saving = false;
  String? _saveError;

  static const _teamSizes = ['1-5', '6-20', '21-50', '50+'];
  static const _businessYears = ['<1', '1-2', '3-5', '6-10', '10+'];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController.text = profile?.companyName ?? '';
    _registrationController.text = profile?.registrationNumber ?? '';
    _areasController.text = profile?.serviceAreas.join(', ') ?? '';
    _teamSize = profile?.teamSize;
    _yearsInBusiness = profile?.yearsInBusiness;
    _verificationSubmissions = List.of(widget.verificationSubmissions);
  }

  @override
  void didUpdateWidget(covariant CompanyDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final profile = widget.initialProfile;
    if (profile == null ||
        oldWidget.initialProfile != null ||
        oldWidget.categorySlug != widget.categorySlug) {
      return;
    }
    if (_nameController.text.isEmpty && profile.companyName != null) {
      _nameController.text = profile.companyName!;
    }
    if (_registrationController.text.isEmpty &&
        profile.registrationNumber != null) {
      _registrationController.text = profile.registrationNumber!;
    }
    if (_areasController.text.isEmpty && profile.serviceAreas.isNotEmpty) {
      _areasController.text = profile.serviceAreas.join(', ');
    }
    _teamSize ??= profile.teamSize;
    _yearsInBusiness ??= profile.yearsInBusiness;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _registrationController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  static String _errorText(Object error) => switch (error) {
        StateError(:final message) => message.toString(),
        FormatException(:final message) => message,
        _ => userFacingErrorMessage(error),
      };

  ProviderCompanyProfile _currentProfile() => ProviderCompanyProfile(
        categorySlug: widget.categorySlug,
        companyName: _nameController.text,
        registrationNumber: _registrationController.text,
        teamSize: _teamSize,
        yearsInBusiness: _yearsInBusiness,
        serviceAreas: _areasController.text
            .split(',')
            .map((area) => area.trim())
            .where((area) => area.isNotEmpty)
            .toSet()
            .toList(),
      );

  void _notifyDraftChanged() => widget.onDraftChanged(_currentProfile());

  Future<void> _pickCompanyDocument(String documentType) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _uploadingDocumentType = documentType);
    try {
      final group = XTypeGroup(
        label: l10n.companyVerificationTitle,
        extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [group]);
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw StateError(l10n.companyEvidenceTooLarge);
      }
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        _ => '',
      };
      if (mime.isEmpty) throw StateError(l10n.companyEvidenceUnsupported);
      final path =
          await widget.providerRepository.uploadCompanyVerificationDocument(
        categorySlug: widget.categorySlug,
        documentType: documentType,
        fileName: file.name,
        mimeType: mime,
        bytes: bytes,
      );
      await widget.providerRepository.submitCompanyVerificationDocument(
        categorySlug: widget.categorySlug,
        documentType: documentType,
        filePath: path,
      );
      final submissions = await widget.providerRepository
          .getCompanyVerificationSubmissions(widget.categorySlug);
      if (!mounted) return;
      setState(() => _verificationSubmissions = submissions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.companyVerificationUploaded)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(error))),
      );
    } finally {
      if (mounted) setState(() => _uploadingDocumentType = null);
    }
  }

  Map<String, dynamic>? _submission(String documentType) {
    return _verificationSubmissions
        .where((row) => row['document_type'] == documentType)
        .firstOrNull;
  }

  String _companyStatusLabel(AppLocalizations l10n) {
    final statuses = _verificationSubmissions
        .map((row) => row['status']?.toString())
        .toSet();
    if (statuses.contains('pending')) return l10n.companyVerificationPending;
    if (statuses.contains('rejected')) return l10n.companyVerificationRejected;
    if (statuses.contains('approved')) return l10n.companyVerificationVerified;
    return l10n.companyVerificationNotSubmitted;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final profile = _currentProfile();
    try {
      await widget.onSave(
        profile: profile.toJson(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = _errorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final text2 = theme.colorScheme.onSurfaceVariant;
    final allCount = widget.serviceCount + widget.roleCount;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Row(children: [
                Expanded(child: _progressSegment(theme.colorScheme.primary)),
                const SizedBox(width: 6),
                Expanded(child: _progressSegment(theme.colorScheme.primary)),
              ]),
              const SizedBox(height: 12),
              Text(l10n.companyStepTwoOfTwo,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7)),
              const SizedBox(height: 5),
              Text(l10n.companyDetailsTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(l10n.companyDetailsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.companyName,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (_) => _notifyDraftChanged(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _registrationController,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: l10n.companyRegistrationNumber,
                  border: const OutlineInputBorder(),
                  counterText: '',
                  helperText: l10n.companyRegistrationPrivate,
                ),
                onChanged: (_) => _notifyDraftChanged(),
              ),
              const SizedBox(height: 8),
              _ChoiceChips(
                label: l10n.companyTeamSize,
                values: _teamSizes,
                selected: _teamSize,
                onSelected: (value) {
                  setState(() => _teamSize = value);
                  _notifyDraftChanged();
                },
                labels: [
                  l10n.companyTeamOneToFive,
                  l10n.companyTeamSixToTwenty,
                  l10n.companyTeamTwentyOneToFifty,
                  l10n.companyTeamFiftyPlus,
                ],
              ),
              const SizedBox(height: 14),
              _ChoiceChips(
                label: l10n.companyYearsInBusiness,
                values: _businessYears,
                selected: _yearsInBusiness,
                onSelected: (value) {
                  setState(() => _yearsInBusiness = value);
                  _notifyDraftChanged();
                },
                labels: [
                  l10n.companyYearsUnderOne,
                  l10n.companyYearsOneToTwo,
                  l10n.companyYearsThreeToFive,
                  l10n.companyYearsSixToTen,
                  l10n.companyYearsTenPlus,
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _areasController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.companyServiceAreas,
                  border: const OutlineInputBorder(),
                  helperText: l10n.companyServiceAreasHint,
                ),
                onChanged: (_) => _notifyDraftChanged(),
              ),
              const SizedBox(height: 20),
              Text(l10n.companyVerificationTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.companyVerificationIntro,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              const SizedBox(height: 8),
              Text(_companyStatusLabel(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              for (final item in [
                ('business_registration', l10n.companyVerificationRegistration),
                ('business_licence', l10n.companyVerificationLicence),
              ]) ...[
                const SizedBox(height: 8),
                _EvidenceRow(
                  label: item.$2,
                  busy: _uploadingDocumentType == item.$1,
                  status: _submission(item.$1)?['status'] == 'approved'
                      ? l10n.companyVerificationVerified
                      : _submission(item.$1)?['status'] == 'rejected'
                          ? l10n.companyVerificationRejected
                          : _submission(item.$1)?['status'] == 'pending'
                              ? l10n.companyVerificationPending
                              : l10n.companyVerificationNotSubmitted,
                  reason: _submission(item.$1)?['reject_reason']?.toString(),
                  hasUpload: false,
                  hasExisting: _submission(item.$1) != null,
                  onTap: _uploadingDocumentType == null
                      ? () => _pickCompanyDocument(item.$1)
                      : null,
                ),
              ],
              const SizedBox(height: 8),
              Text(l10n.companyVerificationSeparateNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              const SizedBox(height: 4),
              Text(l10n.companyVerificationFileHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_saveError!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(children: [
              Text(
                l10n.companySelectionCount(
                    widget.serviceCount, widget.roleCount),
                style: theme.textTheme.bodySmall?.copyWith(color: text2),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving || allCount == 0 ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.companySave),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _progressSegment(Color color) => Container(
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.labels,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < values.length; i++)
                ChoiceChip(
                  label: Text(labels[i]),
                  selected: selected == values[i],
                  onSelected: (_) => onSelected(values[i]),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
            ],
          ),
        ],
      );
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.label,
    required this.busy,
    required this.status,
    required this.hasUpload,
    required this.hasExisting,
    required this.onTap,
    this.reason,
  });

  final String label;
  final bool busy;
  final String status;
  final String? reason;
  final bool hasUpload;
  final bool hasExisting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(
            hasUpload ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: hasUpload
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          if (busy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(reason == null ? status : '$status · $reason',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(hasUpload || hasExisting
                ? l10n.companyEvidenceReplace
                : l10n.companyVerificationUpload),
          ),
        ]),
      ),
    );
  }
}
