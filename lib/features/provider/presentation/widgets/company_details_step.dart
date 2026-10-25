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
    this.categoryName = '',
    this.locationHint,
    required this.serviceCount,
    this.serviceNames = const [],
    required this.roleCount,
    required this.initialProfile,
    required this.companyName,
    this.representativeName = '',
    this.representativeAvatarUrl,
    this.representativeAuthorized = false,
    this.onPresentationChanged,
    this.onChangeProfile,
    this.verificationSubmissions = const [],
    required this.providerRepository,
    required this.onDraftChanged,
    required this.onSave,
    this.onEditCompanyName,
  });

  final String categorySlug;
  final String categoryName;
  final String? locationHint;
  final int serviceCount;
  final List<String> serviceNames;
  final int roleCount;
  final ProviderCompanyProfile? initialProfile;
  final String companyName;
  final String representativeName;
  final String? representativeAvatarUrl;
  final bool representativeAuthorized;
  final ValueChanged<Map<String, dynamic>>? onPresentationChanged;
  final VoidCallback? onChangeProfile;
  final List<Map<String, dynamic>> verificationSubmissions;
  final IProviderRepository providerRepository;
  final ValueChanged<ProviderCompanyProfile> onDraftChanged;
  final Future<void> Function({required Map<String, dynamic> profile}) onSave;
  final VoidCallback? onEditCompanyName;

  @override
  State<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends State<CompanyDetailsStep> {
  late final TextEditingController _companyNameController;
  final _registrationController = TextEditingController();
  final _areasController = TextEditingController();
  String? _teamSize;
  String? _yearsInBusiness;
  late List<Map<String, dynamic>> _verificationSubmissions;
  String? _uploadingDocumentType;
  bool _saving = false;
  String? _saveError;
  String? _companyLogoUrl;
  bool _uploadingLogo = false;

  static const _teamSizes = ['1-5', '6-20', '21-50', '50+'];
  static const _businessYears = ['<1', '1-2', '3-5', '6-10', '10+'];

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.companyName);
    final profile = widget.initialProfile;
    _registrationController.text = profile?.registrationNumber ?? '';
    _areasController.text = profile?.serviceAreas.join(', ') ?? '';
    _teamSize = profile?.teamSize;
    _yearsInBusiness = profile?.yearsInBusiness;
    _verificationSubmissions = List.of(widget.verificationSubmissions);
    final logoPath = profile?.logoPath;
    if (logoPath != null && logoPath.isNotEmpty) {
      _loadCompanyLogo(logoPath);
    }
  }

  @override
  void didUpdateWidget(covariant CompanyDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyName != widget.companyName &&
        _companyNameController.text != widget.companyName) {
      _companyNameController.text = widget.companyName;
    }
    final profile = widget.initialProfile;
    if (oldWidget.initialProfile?.logoPath != profile?.logoPath &&
        profile?.logoPath != null) {
      _loadCompanyLogo(profile!.logoPath!);
    }
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
    _registrationController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  static String _errorText(Object error) => switch (error) {
        StateError(:final message) => message.toString(),
        FormatException(:final message) => message,
        _ => userFacingErrorMessage(error),
      };

  Future<void> _loadCompanyLogo(String path) async {
    try {
      final url = await widget.providerRepository.getCompanyLogoUrl(path);
      if (mounted) setState(() => _companyLogoUrl = url);
    } catch (_) {
      // Keep the upload affordance available if an old logo cannot be loaded.
    }
  }

  Future<void> _pickCompanyLogo() async {
    if (_uploadingLogo) return;
    setState(() => _uploadingLogo = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
              label: 'Company logo', extensions: ['jpg', 'jpeg', 'png']),
        ],
      );
      if (file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => '',
      };
      if (mimeType.isEmpty) {
        throw const FormatException('Choose a JPG or PNG image.');
      }
      final bytes = await file.readAsBytes();
      final path = await widget.providerRepository.uploadCompanyLogo(
        categorySlug: widget.categorySlug,
        fileName: file.name,
        mimeType: mimeType,
        bytes: bytes,
      );
      await widget.providerRepository.saveCompanyLogo(
        categorySlug: widget.categorySlug,
        filePath: path,
      );
      final url = await widget.providerRepository.getCompanyLogoUrl(path);
      if (mounted) setState(() => _companyLogoUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  ProviderCompanyProfile _currentProfile() => ProviderCompanyProfile(
        categorySlug: widget.categorySlug,
        companyName: _companyNameController.text,
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

  Future<void> _pickCompanyDocument({
    Map<String, dynamic>? existing,
    String? selectedDocumentType,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final documentType = existing?['document_type']?.toString() ??
        selectedDocumentType ??
        'business_registration';
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

  Map<String, dynamic>? _submissionFor(String documentType) =>
      _orderedSubmissions.cast<Map<String, dynamic>?>().firstWhere(
            (row) => row?['document_type']?.toString() == documentType,
            orElse: () => null,
          );

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

  String _documentStatusLabel(AppLocalizations l10n, String? status) =>
      switch (status) {
        'pending' => l10n.companyVerificationPending,
        'approved' => l10n.companyVerificationVerified,
        'rejected' => l10n.companyVerificationRejected,
        _ => l10n.companyVerificationNotSubmitted,
      };

  Widget _companyDocumentRow({
    required String documentType,
    required String title,
    required AppLocalizations l10n,
    required ThemeData theme,
    required Color text2,
  }) {
    final submission = _submissionFor(documentType);
    final status = submission?['status']?.toString();
    final uploading = _uploadingDocumentType != null &&
        (_uploadingDocumentType == documentType ||
            _uploadingDocumentType == submission?['id']?.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  submission == null
                      ? l10n.companyVerificationNotSubmitted
                      : '${_documentStatusLabel(l10n, status)}${submission['file_name'] == null ? '' : ' · ${submission['file_name']}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        status == 'rejected' ? theme.colorScheme.error : text2,
                  ),
                ),
                if (submission?['reject_reason'] != null)
                  Text(submission!['reject_reason'].toString(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 40),
            ),
            onPressed: _uploadingDocumentType == null
                ? () => _pickCompanyDocument(
                      selectedDocumentType: documentType,
                      existing: submission,
                    )
                : null,
            icon: uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(submission == null ? 'Add proof' : 'Replace'),
          ),
          if (submission != null && status != 'approved')
            IconButton(
              tooltip: l10n.companyDocumentRemove,
              visualDensity: VisualDensity.compact,
              onPressed: _uploadingDocumentType == null
                  ? () => _removeCompanyDocument(submission)
                  : null,
              icon: const Icon(Icons.delete_outline, size: 19),
            ),
        ],
      ),
    );
  }

  String get _serviceVerificationNote {
    final names = widget.serviceNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final requirement = switch (names.length) {
      0 =>
        'Selected services need their own approved proof before they go live.',
      1 => '${names.single} needs its own approved proof before it goes live.',
      _ =>
        '${names.take(names.length - 1).join(', ')} and ${names.last} need their own approved proof before they go live.',
    };
    return '$requirement Add it from Provider Services after saving. JPG, PNG or PDF, up to 5 MB each.';
  }

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
    if (_companyNameController.text.trim().isEmpty) {
      setState(() => _saveError = 'Company or business name is required.');
      return;
    }
    if (widget.representativeAuthorized &&
        widget.representativeName.trim().isEmpty) {
      setState(() => _saveError =
          'Add your name to your Profile or turn off the representative option.');
      return;
    }
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
    final representativeName = widget.representativeName.trim();
    final representativePhoto = widget.representativeAvatarUrl?.trim();
    final representativeInitials = representativeName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: _uploadingLogo ? null : _pickCompanyLogo,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCE4EF)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F6FC),
                            border:
                                Border.all(color: theme.colorScheme.primary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _uploadingLogo
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : _companyLogoUrl == null
                                  ? Icon(Icons.upload_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 26)
                                  : Image.network(
                                      _companyLogoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.upload_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 26,
                                      ),
                                    ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _companyLogoUrl == null
                                    ? 'Company logo'
                                    : 'Change company logo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Optional. JPG or PNG, up to 2 MB. A square image works best.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: text2,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Company or business name *',
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
              const SizedBox(height: 5),
              Text('Required. Shown publicly as the provider name.',
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
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
                                color: Color(0xFF5B6470), height: 1.3),
                          ),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FA),
                    border: Border.all(color: const Color(0xFFDCE4EF)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E7EF),
                          shape: BoxShape.circle,
                        ),
                        child: representativePhoto?.isNotEmpty == true
                            ? Image.network(
                                representativePhoto!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    representativeInitials.isEmpty
                                        ? '•'
                                        : representativeInitials,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  representativeInitials.isEmpty
                                      ? '•'
                                      : representativeInitials,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Representative',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: text2)),
                            Text(
                              representativeName.isEmpty
                                  ? 'Profile name not set'
                                  : representativeName,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text('Name and photo from your Profile',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: text2)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: representativeName.isEmpty
                              ? const Color(0xFFFFF0D6)
                              : const Color(0xFFDCF4E5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              representativeName.isEmpty
                                  ? Icons.sync_problem_rounded
                                  : Icons.check_rounded,
                              size: 13,
                              color: representativeName.isEmpty
                                  ? const Color(0xFFAA6500)
                                  : const Color(0xFF168044),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              representativeName.isEmpty
                                  ? 'Not synced'
                                  : 'Synced',
                              style: TextStyle(
                                color: representativeName.isEmpty
                                    ? const Color(0xFFAA6500)
                                    : const Color(0xFF168044),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onChangeProfile != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: widget.onChangeProfile,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      child: const Text('Change in Profile'),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              Text('PREVIEW',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF596579),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _companyLogoUrl == null
                          ? Icon(Icons.business_outlined,
                              color: theme.colorScheme.primary)
                          : Image.network(_companyLogoUrl!, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.companyName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (widget.representativeAuthorized &&
                              widget.representativeName.trim().isNotEmpty)
                            Text('Represented by ${widget.representativeName}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: text2)),
                          if (widget.categoryName.isNotEmpty)
                            Text(widget.categoryName,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: text2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Company details',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(l10n.companyRegistrationNumber,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _registrationController,
                maxLength: 40,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'For example, your business registration number',
                  counterText: '',
                ),
                onChanged: (_) => _notifyDraftChanged(),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 18),
              Text('Where do you work?',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _areasController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: widget.locationHint?.trim().isNotEmpty == true
                      ? widget.locationHint
                      : l10n.locationLabel,
                ),
                onChanged: (_) => _notifyDraftChanged(),
              ),
              const SizedBox(height: 5),
              Text('District or city only. Your exact address is never shown.',
                  style: theme.textTheme.bodySmall?.copyWith(color: text2)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.companyVerificationTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(_companyStatusLabel(l10n),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Optional. Upload documents for manual review by Nipanze. A registration certificate does not authorize regulated services; those are verified separately, per service.',
                style: theme.textTheme.bodySmall?.copyWith(color: text2),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4EF)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _companyDocumentRow(
                      documentType: 'business_registration',
                      title: l10n.companyVerificationRegistration,
                      l10n: l10n,
                      theme: theme,
                      text2: text2,
                    ),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    _companyDocumentRow(
                      documentType: 'business_licence',
                      title: l10n.companyVerificationLicence,
                      l10n: l10n,
                      theme: theme,
                      text2: text2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 17, color: text2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _serviceVerificationNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: text2,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
