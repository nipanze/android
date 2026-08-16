// lib/features/admin/presentation/pages/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Stage 5 moderation console. RLS remains the authority: every query and
/// mutation below is allowed only when `private.is_admin()` is true.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _activity;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _activity = _loadActivity();
  }

  Future<List<Map<String, dynamic>>> _loadActivity() async =>
      List<Map<String, dynamic>>.from(
          await _client.from(ViewNames.marketplaceActivity).select().limit(12));

  Future<void> _refresh() async => setState(() => _activity = _loadActivity());

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop()),
          title: const Text('Admin dashboard'),
          bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'KYC'),
            Tab(text: 'Users'),
            Tab(text: 'Audit'),
            Tab(text: 'Settings'),
          ]),
        ),
        body: TabBarView(controller: _tabs, children: [
          _Overview(activity: _activity, onRefresh: _refresh),
          const _KycReview(),
          const _Users(),
          const _AuditLog(),
          const _Settings(),
        ]),
      );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.activity, required this.onRefresh});
  final Future<List<Map<String, dynamic>>> activity;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: activity,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
                message: userFacingErrorMessage(snapshot.error!),
                onRetry: onRefresh);
          }
          final rows = snapshot.data ?? [];
          final total = <String, num>{};
          for (final row in rows) {
            for (final key in [
              'active_listings',
              'pending_offers',
              'accepted_offers',
              'active_paid_subscribers'
            ]) {
              total[key] = (total[key] ?? 0) + ((row[key] as num?) ?? 0);
            }
          }
          final rate = rows.isEmpty ? 0 : rows.first['match_rate_pct'] ?? 0;
          return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                const Row(children: [
                  LiveDot(),
                  SizedBox(width: 6),
                  Text('Live marketplace activity')
                ]),
                const SizedBox(height: 16),
                GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      _Metric('Active listings',
                          '${total['active_listings'] ?? 0}', AppColors.accent),
                      _Metric('Pending offers',
                          '${total['pending_offers'] ?? 0}', AppColors.warning),
                      _Metric(
                          'Accepted offers',
                          '${total['accepted_offers'] ?? 0}',
                          AppColors.success),
                      _Metric(
                          'Paid subscribers',
                          '${total['active_paid_subscribers'] ?? 0}',
                          AppColors.purple),
                      _Metric('Latest match rate', '$rate%', AppColors.success),
                    ]),
                const SizedBox(height: 20),
                const Text(
                    'Metrics are read from the security-invoker marketplace activity view.',
                    style: TextStyle(fontSize: 11, color: AppColors.text3Dark)),
              ]));
        },
      );
}

class _KycReview extends StatefulWidget {
  const _KycReview();
  @override
  State<_KycReview> createState() => _KycReviewState();
}

class _KycReviewState extends State<_KycReview> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await _client
          .from(TableNames.kycVerifications)
          .select('*, profiles(full_name, email)')
          .eq('status', 'pending')
          .order('submitted_at'));
  Future<void> _review(Map<String, dynamic> item, bool approve) async {
    String? reason;
    if (!approve) reason = await _reason();
    if (!approve && (reason == null || reason.trim().isEmpty)) return;
    await _client.from(TableNames.kycVerifications).update({
      'status': approve ? 'approved' : 'rejected',
      'verified_by': _client.auth.currentUser!.id,
      'reviewed_at': DateTime.now().toIso8601String(),
      'rejection_reason': approve ? null : reason,
      'id_verified': approve,
      'selfie_verified': approve,
    }).eq('id', item['id']);
    await _client.from(TableNames.auditLogs).insert({
      'user_id': _client.auth.currentUser!.id,
      'event_type': 'admin_action',
      'entity_type': 'kyc_verifications',
      'entity_id': item['id'],
      'action': approve ? 'approve_kyc' : 'reject_kyc',
      'new_values': {'status': approve ? 'approved' : 'rejected'},
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'KYC approved.' : 'KYC rejected.')));
      setState(() => _items = _load());
    }
  }

  Future<String?> _reason() async {
    final c = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Rejection reason'),
                content: TextField(controller: c, autofocus: true, maxLines: 3),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text),
                      child: const Text('Reject'))
                ]));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<
          List<Map<String, dynamic>>>(
      future: _items,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return ErrorState(
              message: userFacingErrorMessage(s.error!),
              onRetry: () async => setState(() => _items = _load()));
        }
        final items = s.data ?? [];
        if (items.isEmpty) {
          return const Center(
              child: Text('No KYC submissions awaiting review.'));
        }
        return RefreshIndicator(
            onRefresh: () async => setState(() => _items = _load()),
            child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final person = item['profiles'] as Map<String, dynamic>?;
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(person?['full_name'] ?? 'Unknown user',
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                Text(person?['email'] ?? '',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Wrap(
                                    spacing: 6,
                                    children: [
                                      'national_id_front_url',
                                      'national_id_back_url',
                                      'selfie_url'
                                    ]
                                        .where((k) => item[k] != null)
                                        .map((_) =>
                                            const Chip(label: Text('Document')))
                                        .toList()),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                          onPressed: () => _review(item, false),
                                          child: const Text('Reject')),
                                      FilledButton(
                                          onPressed: () => _review(item, true),
                                          child: const Text('Approve'))
                                    ])
                              ])));
                }));
      });
}

class _Users extends StatefulWidget {
  const _Users();
  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _rows;
  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async => List<
      Map<String,
          dynamic>>.from(await _client
      .from(TableNames.profiles)
      .select(
          'id, full_name, email, account_status, is_admin, subscriptions(plan, status), kyc_verifications(status)')
      .order('created_at', ascending: false)
      .limit(100));
  Future<void> _toggleStatus(Map<String, dynamic> row) async {
    final next = row['account_status'] == 'suspended' ? 'active' : 'suspended';
    await _client
        .from(TableNames.profiles)
        .update({'account_status': next}).eq('id', row['id']);
    await _client.from(TableNames.auditLogs).insert({
      'user_id': _client.auth.currentUser!.id,
      'event_type': 'admin_action',
      'entity_type': 'profiles',
      'entity_id': row['id'],
      'action': 'set_account_status',
      'new_values': {'account_status': next}
    });
    if (mounted) setState(() => _rows = _load());
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (_, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return ErrorState(
                  message: userFacingErrorMessage(s.error!),
                  onRetry: () async => setState(() => _rows = _load()));
            }
            return RefreshIndicator(
                onRefresh: () async => setState(() => _rows = _load()),
                child: ListView(children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Users',
                          style: Theme.of(context).textTheme.titleMedium)),
                  ...(s.data ?? []).map((row) {
                    final sub = row['subscriptions'] as List?;
                    final kyc = row['kyc_verifications'] as List?;
                    return ListTile(
                        title: Text(row['full_name'] ?? 'Unnamed user'),
                        subtitle: Text(
                            '${row['email'] ?? ''}\n${sub?.firstOrNull?['plan'] ?? 'free'} plan · KYC ${kyc?.firstOrNull?['status'] ?? 'not submitted'}'),
                        isThreeLine: true,
                        trailing: TextButton(
                            onPressed: () => _toggleStatus(row),
                            child: Text(row['account_status'] == 'suspended'
                                ? 'Activate'
                                : 'Suspend')));
                  }),
                ]));
          });
}

class _AuditLog extends StatelessWidget {
  const _AuditLog();
  @override
  Widget build(BuildContext context) => _AdminList(
      table: TableNames.auditLogs,
      fields: 'event_type, action, entity_type, created_at',
      title: 'Audit trail',
      item: (row) => ListTile(
          title: Text(row['event_type'] ?? 'Event'),
          subtitle:
              Text('${row['action'] ?? ''} · ${row['entity_type'] ?? ''}'),
          trailing:
              Text((row['created_at'] ?? '').toString().split('T').first)));
}

class _AdminList extends StatefulWidget {
  const _AdminList(
      {required this.table,
      required this.fields,
      required this.title,
      required this.item});
  final String table, fields, title;
  final Widget Function(Map<String, dynamic>) item;
  @override
  State<_AdminList> createState() => _AdminListState();
}

class _AdminListState extends State<_AdminList> {
  late Future<List<Map<String, dynamic>>> _rows;
  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await Supabase.instance.client
          .from(widget.table)
          .select(widget.fields)
          .order('created_at', ascending: false)
          .limit(100));
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (_, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return ErrorState(
                  message: userFacingErrorMessage(s.error!),
                  onRetry: () async => setState(() => _rows = _load()));
            }
            return RefreshIndicator(
                onRefresh: () async => setState(() => _rows = _load()),
                child: ListView(children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.title,
                          style: Theme.of(context).textTheme.titleMedium)),
                  ...(s.data ?? []).map(widget.item)
                ]));
          });
}

class _Settings extends StatefulWidget {
  const _Settings();
  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _rows;
  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await _client
          .from(TableNames.systemSettings)
          .select()
          .order('category')
          .order('setting_key'));
  Future<void> _edit(Map<String, dynamic> r) async {
    final c = TextEditingController(text: r['setting_value']);
    final v = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(r['setting_key']),
                content: TextField(controller: c),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text),
                      child: const Text('Save'))
                ]));
    if (v == null) return;
    await _client
        .from(TableNames.systemSettings)
        .update({'setting_value': v}).eq('setting_id', r['setting_id']);
    await _client.from(TableNames.auditLogs).insert({
      'user_id': _client.auth.currentUser!.id,
      'event_type': 'admin_action',
      'entity_type': 'system_settings',
      'entity_id': r['setting_id'],
      'action': 'update_setting',
      'new_values': {'setting_key': r['setting_key'], 'setting_value': v}
    });
    if (mounted) setState(() => _rows = _load());
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (_, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return ErrorState(
                  message: userFacingErrorMessage(s.error!),
                  onRetry: () async => setState(() => _rows = _load()));
            }
            return ListView(
                children: (s.data ?? [])
                    .map((r) => ListTile(
                        title: Text(r['setting_key']),
                        subtitle: Text(r['description'] ?? ''),
                        trailing: Text(r['setting_value'] ?? ''),
                        onTap: () => _edit(r)))
                    .toList());
          });
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color))
      ]));
}
