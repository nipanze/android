import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
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
    required this.companyName,
    this.representativeName = '',
    this.representativeAuthorized = false,
    this.onPresentationChanged,
    this.verificationSubmissions = const [],
    required this.providerRepository,
    required this.onDraftChanged,
    required this.onSave,
    required this.onEditCompanyName,
  });

  final String categorySlug;
  final int serviceCount;
  final int roleCount;
  final ProviderCompanyProfile? initialProfile;
  final String companyName;
  final String representativeName;
  final bool representativeAuthorized;
  final ValueChanged<Map<String, dynamic>>? onPresentationChanged;
  final List<Map<String, dynamic>> verificationSubmissions;
  final IProviderRepository providerRepository;
  final ValueChanged<ProviderCompanyProfile> onDraftChanged;
  final Future<void> Function({required Map<String, dynamic> profile}) onSave;
  final VoidCallback onEditCompanyName;

  @override
  State<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends State<CompanyDetailsStep> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _representativeController;
  final _registrationController = TextEditingController();
  final _areasController = TextEditingController();
  String? _teamSize;
  String? _yearsInBusiness;
  late List<Map<String, dynamic>> _verificationSubmissions;
  String? _uploadingDocumentType;
  String _selectedDocumentType = 'business_registration';
  bool _saving = false;
  String? _saveError;

  static const _teamSizes = ['1-5', '6-20', '21-50', '50+'];
  static const _businessYears = ['<1', '1-2', '3-5', '6-10', '10+'];

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.companyName);
    _representativeController =
        TextEditingController(text: widget.representativeName);
    final profile = widget.initialProfile;
    _registrationController.text = profile?.registrationNumber ?? '';
    _areasController.text = profile?.serviceAreas.join(', ') ?? '';
    _teamSize = profile?.teamSize;
    _yearsInBusiness = profile?.yearsInBusiness;
    _verificationSubmissions = List.of(widget.verificationSubmissions);
  }

  @override
  void didUpdateWidget(covariant CompanyDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyName != widget.companyName &&
        _companyNameController.text != widget.companyName) {
      _companyNameController.text = widget.companyName;
    }
    if (oldWidget.representativeName != widget.representativeName &&
        _representativeController.text != widget.representativeName) {
      _representativeController.text = widget.representativeName;
    }
    final profile = widget.initialProfile;
    if (profile == null ||
        oldWidget.initialProfile != null ||
        oldWidget.categorySlug != widget.categorySlug) {
      return;
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
    _companyNameController.dispose();
    _representativeController.dispose();
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
        companyName: widget.companyName,
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

  Future<void> _pickCompanyDocument({Map<String, dynamic>? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final documentType =
        existing?['document_type']?.toString() ?? _selectedDocumentType;
    final submissionId = existing?['id']?.toString();
    setState(() => _uploadingDocumentType = submissionId ?? documentType);
    try {
      final group = XTypeGroup(
        label: l10n.companyDocumentsTitle,
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
      await widget.providerRepository.saveCompanyDocument(
        categorySlug: widget.categorySlug,
        documentType: documentType,
        filePath: path,
        fileName: file.name,
        submissionId: submissionId,
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

  Future<void> _addCompanyDocument() => _pickCompanyDocument();

  Future<void> _removeCompanyDocument(Map<String, dynamic> submission) async {
    final l10n = AppLocalizations.of(context)!;
    final id = submission['id']?.toString();
    if (id == null || submission['status'] == 'approved') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.companyDocumentRemove),
        content: Text(l10n.providerEvidenceRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.companyDocumentRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.providerRepository.removeCompanyDocument(id);
      final submissions = await widget.providerRepository
          .getCompanyVerificationSubmissions(widget.categorySlug);
      if (!mounted) return;
      setState(() => _verificationSubmissions = submissions);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  String _documentTypeLabel(AppLocalizations l10n, String? type) =>
      switch (type) {
        'business_registration' => l10n.companyVerificationRegistration,
        'business_licence' => l10n.companyVerificationLicence,
        'certificate' => l10n.companyDocumentTypeCertificate,
        'other' => l10n.companyDocumentTypeOther,
        _ => type ?? l10n.companyDocumentTypeOther,
      };

  String _documentStatusLabel(AppLocalizations l10n, String? status) =>
      switch (status) {
        'pending' => l10n.companyVerificationPending,
        'approved' => l10n.companyVerificationVerified,
        'rejected' => l10n.companyVerificationRejected,
        _ => l10n.companyVerificationNotSubmitted,
      };

  List<Map<String, dynamic>> get _orderedSubmissions {
    final sorted = List<Map<String, dynamic>>.of(_verificationSubmissions);
    sorted.sort((a, b) => (b['created_at']?.toString() ?? '')
        .compareTo(a['created_at']?.toString() ?? ''));
    return sorted;
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
              const SizedBox(height: 16),
              Text('How should you be shown?',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6FC),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_rounded,
                          color: theme.colorScheme.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Company logo',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(
                              'Optional. JPG or PNG, up to 2 MB. A square image works best.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: text2,
                                height: 1.3,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Company or business name',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _companyNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
                onChanged: (value) => widget.onPresentationChanged?.call({
                  'display_name': value,
                }),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Also show me as representative',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text(
                              'Only if you are allowed to act for this business.',
                              style: TextStyle(
                                  color: Color(0xFF5B6470), height: 1.3)),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: widget.representativeAuthorized,
                      onChanged: (value) => widget.onPresentationChanged?.call({
                        'representative_authorized': value,
                        'display_mode':
                            value ? 'company_with_representative' : 'company',
                      }),
                    ),
                  ],
                ),
              ),
              if (widget.representativeAuthorized) ...[
                const SizedBox(height: 12),
                Text('Representative name',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _representativeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  onChanged: (value) => widget.onPresentationChanged?.call({
                    'representative_name': value,
                  }),
                ),
              ],
              const SizedBox(height: 18),
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
              Text(l10n.companyDocumentsTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.companyDocumentsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              const SizedBox(height: 8),
              Text(_companyStatusLabel(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedDocumentType,
                decoration: InputDecoration(
                  labelText: l10n.companyDocumentTypeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'business_registration',
                    child: Text(l10n.companyVerificationRegistration),
                  ),
                  DropdownMenuItem(
                    value: 'business_licence',
                    child: Text(l10n.companyVerificationLicence),
                  ),
                  DropdownMenuItem(
                    value: 'certificate',
                    child: Text(l10n.companyDocumentTypeCertificate),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(l10n.companyDocumentTypeOther),
                  ),
                ],
                onChanged: _uploadingDocumentType == null
                    ? (value) {
                        if (value != null) {
                          setState(() => _selectedDocumentType = value);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _uploadingDocumentType == null
                      ? _addCompanyDocument
                      : null,
                  icon: _uploadingDocumentType == _selectedDocumentType
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(l10n.companyVerificationUpload),
                ),
              ),
              for (final submission in _orderedSubmissions) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            submission['status'] == 'approved'
                                ? Icons.check_circle_outline_rounded
                                : submission['status'] == 'rejected'
                                    ? Icons.error_outline_rounded
                                    : Icons.description_outlined,
                            size: 18,
                            color: submission['status'] == 'approved'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _documentTypeLabel(
                                    l10n,
                                    submission['document_type']?.toString(),
                                  ),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  submission['file_name']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  submission['reject_reason'] == null
                                      ? _documentStatusLabel(
                                          l10n,
                                          submission['status']?.toString(),
                                        )
                                      : '${_documentStatusLabel(l10n, submission['status']?.toString())} · ${submission['reject_reason']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: submission['status'] == 'rejected'
                                        ? theme.colorScheme.error
                                        : text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: _uploadingDocumentType == null
                                  ? () =>
                                      _pickCompanyDocument(existing: submission)
                                  : null,
                              child: Text(l10n.companyEvidenceReplace),
                            ),
                            if (submission['status'] != 'approved')
                              IconButton(
                                tooltip: l10n.companyDocumentRemove,
                                visualDensity: VisualDensity.compact,
                                onPressed: _uploadingDocumentType == null
                                    ? () => _removeCompanyDocument(submission)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE1E7EF))),
            ),
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
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF216EEF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
