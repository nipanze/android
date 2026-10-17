import 'package:file_picker/file_picker.dart';
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
    required this.requirements,
    required this.existingEvidence,
    required this.providerRepository,
    required this.onSave,
  });

  final String categorySlug;
  final int serviceCount;
  final int roleCount;
  final ProviderCompanyProfile? initialProfile;
  final List<Map<String, dynamic>> requirements;
  final List<Map<String, dynamic>> existingEvidence;
  final IProviderRepository providerRepository;
  final Future<void> Function({
    required Map<String, dynamic> profile,
    required List<Map<String, String>> evidence,
  }) onSave;

  @override
  State<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends State<CompanyDetailsStep> {
  final _nameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _areasController = TextEditingController();
  String? _teamSize;
  String? _yearsInBusiness;
  final Map<String, String> _uploadedPaths = {};
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _registrationController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  List<_EvidenceRequirement> get _evidenceRequirements {
    final byKey = <String, _EvidenceRequirement>{};
    for (final row in widget.requirements) {
      final raw = row['required_evidence'] as List? ?? const [];
      final extra = row['evidence_requirements'] as List? ?? const [];
      for (final item in [...raw, ...extra]) {
        final key = item.toString().trim();
        if (key.isEmpty) continue;
        byKey.putIfAbsent(key, () => _EvidenceRequirement(key));
      }
    }
    return byKey.values.toList()
      ..sort((a, b) => _label(a.key).compareTo(_label(b.key)));
  }

  static String _label(String key) => key
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _errorText(Object error) => switch (error) {
        StateError(:final message) => message.toString(),
        FormatException(:final message) => message ?? '',
        _ => userFacingErrorMessage(error),
      };

  List<Map<String, dynamic>> _evidenceFor(String key) {
    final result = <Map<String, dynamic>>[];
    for (final capability in widget.existingEvidence) {
      for (final raw
          in capability['provider_capability_evidence'] as List? ?? const []) {
        if (raw is Map && raw['requirement_key'] == key) {
          result.add(raw.cast<String, dynamic>());
        }
      }
    }
    result.sort((a, b) => (b['created_at']?.toString() ?? '')
        .compareTo(a['created_at']?.toString() ?? ''));
    return result;
  }

  String _statusLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    if (_uploadedPaths.containsKey(key)) return l10n.companyEvidenceUploaded;
    final rows = _evidenceFor(key);
    if (rows.isEmpty) return l10n.companyEvidenceNotAdded;
    final statuses = rows.map((row) => row['status']?.toString()).toSet();
    if (statuses.contains('pending')) return l10n.companyEvidenceUnderReview;
    if (statuses.contains('rejected')) return l10n.companyEvidenceRejected;
    if (statuses.contains('expired')) return l10n.companyEvidenceExpired;
    if (statuses.contains('approved')) return l10n.companyEvidenceApproved;
    return l10n.companyEvidenceNotAdded;
  }

  Future<void> _pickEvidence(String key) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw StateError(l10n.companyEvidenceTooLarge);
      }
      final extension = file.extension?.toLowerCase();
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        _ => '',
      };
      if (mime.isEmpty) throw StateError(l10n.companyEvidenceUnsupported);
      final path = await widget.providerRepository.uploadCompanyEvidence(
        categorySlug: widget.categorySlug,
        requirementKey: key,
        fileName: file.name,
        mimeType: mime,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _uploadedPaths[key] = path;
        _saveError = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_errorText(error))),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final profile = ProviderCompanyProfile(
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
    try {
      await widget.onSave(
        profile: profile.toJson(),
        evidence: _uploadedPaths.entries
            .map((entry) =>
                {'requirement_key': entry.key, 'file_path': entry.value})
            .toList(),
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
              ),
              const SizedBox(height: 8),
              _ChoiceChips(
                label: l10n.companyTeamSize,
                values: _teamSizes,
                selected: _teamSize,
                onSelected: (value) => setState(() => _teamSize = value),
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
                onSelected: (value) => setState(() => _yearsInBusiness = value),
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
              ),
              const SizedBox(height: 20),
              Text(l10n.companyProofTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.companyProofIntro,
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              if (_evidenceRequirements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.companyNoEvidenceRequirements,
                      style: theme.textTheme.bodySmall?.copyWith(color: text2)),
                )
              else
                for (final requirement in _evidenceRequirements)
                  _EvidenceRow(
                    label: _label(requirement.key),
                    status: _statusLabel(context, requirement.key),
                    reason: _evidenceFor(requirement.key)
                        .where((row) => row['status'] == 'rejected')
                        .map((row) => row['reject_reason']?.toString())
                        .whereType<String>()
                        .firstOrNull,
                    hasUpload: _uploadedPaths.containsKey(requirement.key),
                    hasExisting: _evidenceFor(requirement.key).isNotEmpty,
                    onTap: () => _pickEvidence(requirement.key),
                  ),
              const SizedBox(height: 8),
              Text(l10n.companyProofNote,
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

class _EvidenceRequirement {
  _EvidenceRequirement(this.key);
  final String key;
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
    required this.status,
    required this.hasUpload,
    required this.hasExisting,
    required this.onTap,
    this.reason,
  });

  final String label;
  final String status;
  final String? reason;
  final bool hasUpload;
  final bool hasExisting;
  final VoidCallback onTap;

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
                : l10n.companyEvidenceAdd),
          ),
        ]),
      ),
    );
  }
}
