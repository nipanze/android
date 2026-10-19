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
    if (rows.isEmpty) return rows;
    final capIds = rows
        .map((row) => row['provider_capability_id'].toString())
        .toSet()
        .toList();
    final capabilities = await _client
        .from(TableNames.providerCapabilities)
        .select(
            'id, user_id, capability_slug, need_capabilities!capability_slug(name, category_slug, need_categories!category_slug(name))')
        .inFilter('id', capIds);
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
    final profiles = userIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.profiles)
            .select('id, full_name')
            .inFilter('id', userIds.toList()));
    final profilesById = {
      for (final row in profiles) row['id'].toString(): row
    };
    final companies = userIds.isEmpty || categorySlugs.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(TableNames.providerCompanyProfiles)
            .select(
                'user_id, category_slug, company_name, registration_number, team_size, years_in_business, service_areas')
            .inFilter('user_id', userIds.toList())
            .inFilter('category_slug', categorySlugs.toList()));
    final companyByOwnerCategory = {
      for (final row in companies)
        '${row['user_id']}|${row['category_slug']}': row,
    };
    return rows.map((row) {
      final cap = capById[row['provider_capability_id'].toString()] ?? {};
      final need = cap['need_capabilities'] as Map?;
      final category = need?['need_categories'] as Map?;
      final userId = cap['user_id']?.toString() ?? '';
      final categorySlug = need?['category_slug']?.toString() ?? '';
      return {
        ...row,
        'capability': cap,
        'capability_name': need?['name'] ?? cap['capability_slug'] ?? '',
        'category_name': category?['name'] ?? categorySlug,
        'provider_name': profilesById[userId]?['full_name'] ?? '',
        'company': companyByOwnerCategory['$userId|$categorySlug'],
      };
    }).toList();
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
                              ? 'Company / Organization proof'
                              : 'Individual proof',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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
                              title: Text(l10n.providerEvidenceCompanyDetails),
                              children: [
                                _CompanyProfileDetails(
                                  profile: (entry.value.first['company'] as Map)
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
