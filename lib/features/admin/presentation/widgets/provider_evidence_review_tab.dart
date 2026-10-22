import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ProviderEvidenceReviewTab extends StatefulWidget {
  const ProviderEvidenceReviewTab({super.key});

  @override
  State<ProviderEvidenceReviewTab> createState() =>
      _ProviderEvidenceReviewTabState();
}

class _ProviderEvidenceReviewTabState extends State<ProviderEvidenceReviewTab> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _items;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final evidence = await _client
        .from(TableNames.providerCapabilityEvidence)
        .select(
            'id, provider_capability_id, requirement_key, provider_type, file_url, status, reject_reason, created_at')
        .eq('status', 'pending')
        .order('created_at');
    final rows = List<Map<String, dynamic>>.from(evidence);
    final roleRows = List<Map<String, dynamic>>.from(await _client
        .from(TableNames.providerRoleQualificationClaims)
        .select(
            'id, provider_capability_id, role_slug, qualification_slug, evidence_object_path, reject_reason, updated_at')
        .eq('status', 'pending_review')
        .eq('is_claimed', true));
    final roleProofs = roleRows
        .map((row) =>
            '${row['provider_capability_id']}|${row['qualification_slug']}|${row['evidence_object_path']}')
        .toSet();
    final capabilityEvidenceRows = rows.where((row) => !roleProofs.contains(
        '${row['provider_capability_id']}|${row['requirement_key']}|${row['file_url']}'));
    final capIds = {
      ...capabilityEvidenceRows
          .map((row) => row['provider_capability_id'].toString())
          .toSet(),
      ...roleRows.map((row) => row['provider_capability_id'].toString()),
    }.toList();
    final capabilities = capIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.providerCapabilities)
            .select(
                'id, user_id, capability_slug, identity_type, need_capabilities!capability_slug(name, category_slug, need_categories!category_slug(name))')
            .inFilter('id', capIds));
    final capById = {
      for (final cap in List<Map<String, dynamic>>.from(capabilities))
        cap['id'].toString(): cap,
    };
    final userIds =
        capById.values.map((row) => row['user_id'].toString()).toSet();
    final categorySlugs = capById.values
        .map((row) => (row['need_capabilities'] as Map?)?['category_slug'])
        .whereType<String>()
        .toSet();
    final companyRows = List<Map<String, dynamic>>.from(await _client
        .from(TableNames.providerCompanyVerificationSubmissions)
        .select(
            'id, user_id, category_slug, document_type, file_name, file_path, status, reject_reason, created_at')
        .eq('status', 'pending')
        .order('created_at'));
    final companyUserIds =
        companyRows.map((row) => row['user_id'].toString()).toSet();
    final allUserIds = {...userIds, ...companyUserIds};
    final allCategorySlugs = {
      ...categorySlugs,
      ...companyRows.map((row) => row['category_slug'].toString()),
    };
    final profiles = allUserIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.profiles)
            .select('id, full_name')
            .inFilter('id', allUserIds.toList()));
    final profilesById = {
      for (final row in profiles) row['id'].toString(): row
    };
    final companies = allUserIds.isEmpty || allCategorySlugs.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.providerCompanyProfiles)
            .select(
                'user_id, category_slug, company_name, registration_number, team_size, years_in_business, service_areas')
            .inFilter('user_id', allUserIds.toList())
            .inFilter('category_slug', allCategorySlugs.toList()));
    final categories = allCategorySlugs.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.needCategories)
            .select('slug, name')
            .inFilter('slug', allCategorySlugs.toList()));
    final categoryNames = {
      for (final row in categories) row['slug'].toString(): row['name']
    };
    final companyByOwnerCategory = {
      for (final row in companies)
        '${row['user_id']}|${row['category_slug']}': row,
    };
    final identityRows = allUserIds.isEmpty || allCategorySlugs.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.providerCategoryProfiles)
            .select('user_id, category_slug, provider_type')
            .inFilter('user_id', allUserIds.toList())
            .inFilter('category_slug', allCategorySlugs.toList()));
    final presentations = allUserIds.isEmpty || allCategorySlugs.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.providerIdentityPresentations)
            .select(
                'user_id, category_slug, identity_type, display_mode, display_name, representative_name')
            .inFilter('user_id', allUserIds.toList())
            .inFilter('category_slug', allCategorySlugs.toList()));
    final identityByOwnerCategory = {
      for (final row in identityRows)
        '${row['user_id']}|${row['category_slug']}': row,
    };
    final presentationByOwnerCategoryIdentity = {
      for (final row in presentations)
        '${row['user_id']}|${row['category_slug']}|${row['identity_type']}':
            row,
    };
    Map<String, dynamic> identityContext(String userId, String categorySlug,
        {String? identityType}) {
      final identity =
          identityByOwnerCategory['$userId|$categorySlug'] ?? const {};
      final type = identityType ?? identity['provider_type']?.toString();
      final presentation = type == null
          ? const <String, dynamic>{}
          : presentationByOwnerCategoryIdentity[
                  '$userId|$categorySlug|$type'] ??
              const <String, dynamic>{};
      final company = companyByOwnerCategory['$userId|$categorySlug'];
      final fallbackName = type == 'company'
          ? company?.cast<String, dynamic>()['company_name']
          : profilesById[userId]?.cast<String, dynamic>()['full_name'];
      final displayName = presentation['display_name']?.toString().trim();
      final representative =
          presentation['representative_name']?.toString().trim();
      return {
        'identity_type': type,
        'identity_display_name': (displayName?.isNotEmpty == true
                ? displayName
                : fallbackName?.toString()) ??
            '',
        'identity_representative':
            presentation['display_mode'] == 'company_with_representative'
                ? representative ?? ''
                : '',
      };
    }

    final capabilityItems = capabilityEvidenceRows.map((row) {
      final cap = capById[row['provider_capability_id'].toString()] ?? {};
      final need = cap['need_capabilities'] as Map?;
      final category = need?['need_categories'] as Map?;
      final userId = cap['user_id']?.toString() ?? '';
      final categorySlug = need?['category_slug']?.toString() ?? '';
      final identity = identityContext(userId, categorySlug,
          identityType: cap['identity_type']?.toString());
      return {
        ...row,
        'capability': cap,
        'capability_name': need?['name'] ?? cap['capability_slug'] ?? '',
        'category_name': category?['name'] ?? categorySlug,
        'provider_name': profilesById[userId]?['full_name'] ?? '',
        'company': companyByOwnerCategory['$userId|$categorySlug'],
        ...identity,
      };
    }).toList();
    final roleItems = roleRows.map((row) {
      final cap = capById[row['provider_capability_id'].toString()] ?? {};
      final need = cap['need_capabilities'] as Map?;
      final category = need?['need_categories'] as Map?;
      final userId = cap['user_id']?.toString() ?? '';
      final categorySlug = need?['category_slug']?.toString() ?? '';
      final identity =
          identityContext(userId, categorySlug, identityType: 'individual');
      final capabilityName = need?['name'] ?? cap['capability_slug'] ?? '';
      return {
        ...row,
        'kind': 'role',
        'file_url': row['evidence_object_path'],
        'requirement_key': row['qualification_slug'],
        'provider_type': 'individual',
        'capability_name':
            '$capabilityName · ${row['role_slug']} · ${row['qualification_slug']}',
        'category_name': category?['name'] ?? categorySlug,
        'provider_name': profilesById[userId]?['full_name'] ?? '',
        ...identity,
      };
    }).toList();
    final companyItems = companyRows.map((row) {
      final userId = row['user_id'].toString();
      final categorySlug = row['category_slug'].toString();
      final company = companyByOwnerCategory['$userId|$categorySlug'];
      final identity =
          identityContext(userId, categorySlug, identityType: 'company');
      return {
        ...row,
        'kind': 'company',
        'file_url': row['file_path'],
        'provider_name': profilesById[userId]?['full_name'] ?? '',
        'category_name': categoryNames[categorySlug] ?? categorySlug,
        'company': company,
        ...identity,
      };
    }).toList();
    return [...capabilityItems, ...roleItems, ...companyItems];
  }

  Future<void> _refresh() async => setState(() => _items = _load());

  Future<void> _openFile(String path) async {
    try {
      final url = await _client.storage
          .from('provider-evidence')
          .createSignedUrl(path, 60);
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open the evidence file.');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  Future<String?> _rejectReason() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.providerEvidenceRejectReason),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.providerEvidenceReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.providerEvidenceReject),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> _review(Map<String, dynamic> item, bool approve) async {
    final id = item['id'].toString();
    final reason = approve ? null : await _rejectReason();
    if (!approve && reason == null) return;
    setState(() => _busy.add(id));
    try {
      await _client
          .rpc(RpcNames.adminReviewProviderCapabilityEvidence, params: {
        'p_evidence_id': id,
        'p_action': approve ? 'approve' : 'reject',
        'p_reject_reason': reason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.providerEvidenceReviewSaved)),
      );
      setState(() => _items = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _reviewCompany(Map<String, dynamic> item, bool approve) async {
    final id = item['id'].toString();
    final reason = approve ? null : await _rejectReason();
    if (!approve && reason == null) return;
    setState(() => _busy.add(id));
    try {
      await _client.rpc(RpcNames.adminReviewProviderCompanyDocument, params: {
        'p_submission_id': item['id'],
        'p_action': approve ? 'approve' : 'reject',
        'p_reject_reason': reason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.providerEvidenceReviewSaved)));
      setState(() => _items = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _reviewRole(Map<String, dynamic> item, bool approve) async {
    final id = item['id'].toString();
    final reason = approve ? null : await _rejectReason();
    if (!approve && reason == null) return;
    setState(() => _busy.add(id));
    try {
      await _client.rpc(RpcNames.adminReviewProviderRoleQualification, params: {
        'p_claim_id': id,
        'p_action': approve ? 'approve' : 'reject',
        'p_reject_reason': reason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.providerEvidenceReviewSaved)));
      setState(() => _items = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: userFacingErrorMessage(snapshot.error!),
            onRetry: _refresh,
          );
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return Center(child: Text(l10n.providerEvidenceEmpty));
        }
        final byPath = <String, List<Map<String, dynamic>>>{};
        for (final row in rows) {
          byPath.putIfAbsent(row['file_url'].toString(), () => []).add(row);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(l10n.providerEvidenceHeader,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final entry in byPath.entries)
                if (entry.value.first['kind'] == 'company')
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (entry.value.first['document_type']) {
                              'business_registration' =>
                                l10n.companyVerificationRegistration,
                              'business_licence' =>
                                l10n.companyVerificationLicence,
                              'certificate' =>
                                l10n.companyDocumentTypeCertificate,
                              _ => l10n.companyDocumentTypeOther,
                            },
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            entry.value.first['file_name']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                              '${entry.value.first['provider_name']} · ${entry.value.first['category_name']}',
                              style: Theme.of(context).textTheme.bodySmall),
                          _ProviderIdentityContext(item: entry.value.first),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () => _openFile(entry.key),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(l10n.providerEvidenceOpenFile),
                            ),
                          ),
                          if (entry.value.first['company'] is Map)
                            _CompanyProfileDetails(
                              profile: (entry.value.first['company'] as Map)
                                  .cast<String, dynamic>(),
                            ),
                          const Divider(height: 16),
                          _CapabilityReviewRow(
                            item: entry.value.first,
                            busy: _busy
                                .contains(entry.value.first['id'].toString()),
                            onApprove: () =>
                                _reviewCompany(entry.value.first, true),
                            onReject: () =>
                                _reviewCompany(entry.value.first, false),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (entry.value.first['kind'] == 'role')
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value.first['capability_name'].toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          _ProviderIdentityContext(item: entry.value.first),
                          Text(
                              '${entry.value.first['provider_name']} · ${entry.value.first['category_name']}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () => _openFile(entry.key),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(l10n.providerEvidenceOpenFile),
                            ),
                          ),
                          const Divider(height: 16),
                          _CapabilityReviewRow(
                            item: entry.value.first,
                            busy: _busy
                                .contains(entry.value.first['id'].toString()),
                            onApprove: () =>
                                _reviewRole(entry.value.first, true),
                            onReject: () =>
                                _reviewRole(entry.value.first, false),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value.first['requirement_key'].toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            entry.value.first['provider_type'] == 'company'
                                ? l10n.providerTypeCompany
                                : l10n.providerTypeIndividual,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          _ProviderIdentityContext(item: entry.value.first),
                          Text(
                            '${entry.value.first['provider_name']} · ${entry.value.length} ${l10n.providerEvidenceCapabilities}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () => _openFile(entry.key),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(l10n.providerEvidenceOpenFile),
                            ),
                          ),
                          for (final item in entry.value) ...[
                            const Divider(height: 16),
                            _CapabilityReviewRow(
                              item: item,
                              busy: _busy.contains(item['id'].toString()),
                              onApprove: () => _review(item, true),
                              onReject: () => _review(item, false),
                            ),
                          ],
                          if (entry.value.first['company'] is Map)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  start: 8, top: 4),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title:
                                    Text(l10n.providerEvidenceCompanyDetails),
                                children: [
                                  _CompanyProfileDetails(
                                    profile:
                                        (entry.value.first['company'] as Map)
                                            .cast<String, dynamic>(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _CapabilityReviewRow extends StatelessWidget {
  const _CapabilityReviewRow({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item['capability_name']} · ${item['category_name']}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(item['provider_name']?.toString() ?? '',
            style: theme.textTheme.bodySmall),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Wrap(spacing: 8, children: [
            FilledButton.tonal(
              onPressed: onApprove,
              child: Text(l10n.providerEvidenceApprove),
            ),
            OutlinedButton(
              onPressed: onReject,
              child: Text(l10n.providerEvidenceReject),
            ),
          ]),
      ],
    );
  }
}

class _ProviderIdentityContext extends StatelessWidget {
  const _ProviderIdentityContext({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final type = item['identity_type']?.toString();
    if (type == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final name = item['identity_display_name']?.toString().trim() ?? '';
    final representative =
        item['identity_representative']?.toString().trim() ?? '';
    final identityLabel = type == 'company'
        ? l10n.providerTypeCompany
        : l10n.providerTypeIndividual;
    final details = [
      if (name.isNotEmpty) name,
      if (representative.isNotEmpty) representative,
    ].join(' · ');
    return Text(
      details.isEmpty ? identityLabel : '$identityLabel · $details',
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _CompanyProfileDetails extends StatelessWidget {
  const _CompanyProfileDetails({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final areas = (profile['service_areas'] as List? ?? const []).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileValue(l10n.companyName, profile['company_name']?.toString()),
        _ProfileValue(l10n.companyRegistrationNumber,
            profile['registration_number']?.toString()),
        _ProfileValue(l10n.companyTeamSize, profile['team_size']?.toString()),
        _ProfileValue(l10n.companyYearsInBusiness,
            profile['years_in_business']?.toString()),
        _ProfileValue(l10n.companyServiceAreas, areas),
      ],
    );
  }
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        const SizedBox(width: 12),
        Expanded(child: Text(value!, textAlign: TextAlign.end)),
      ]),
    );
  }
}
