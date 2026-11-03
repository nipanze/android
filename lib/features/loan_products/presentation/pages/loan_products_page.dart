import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/loan_product_repository.dart';
import '../loan_product_strings.dart';

class LoanProductsPage extends StatefulWidget {
  const LoanProductsPage({super.key});

  @override
  State<LoanProductsPage> createState() => _LoanProductsPageState();
}

class _LoanProductsPageState extends State<LoanProductsPage> {
  final _repository = getIt<LoanProductRepository>();
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic> _quota = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getMyProducts(),
        _repository.getQuota(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _quota = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({String? productId}) async {
    await context.push<void>(
      productId == null
          ? '/provider/loan-products/new'
          : '/provider/loan-products/$productId/edit',
    );
    if (mounted) await _load();
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      if (status == 'active') {
        final result = await _repository.publish(id);
        if (mounted && result['active_limit'] != null) {
          final count = result['active_count'];
          final limit = result['active_limit'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count of $limit active products')),
          );
        }
      } else {
        await _repository.setStatus(id, status);
      }
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeCount = _quota['active_count'] ?? 0;
    final activeLimit = _quota['active_limit'] ?? '—';
    return Scaffold(
      appBar: AppBar(
        title: Text(loanProductText(context, 'title')),
        actions: [
          IconButton(
            tooltip: loanProductText(context, 'browse'),
            onPressed: () => context.push('/loan-products'),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _products.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 72),
                            const Icon(Icons.account_balance_outlined,
                                size: 54, color: AppColors.accent),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                loanProductText(context, 'none'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                loanProductText(context, 'publish_gate'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          children: [
                            _QuotaCard(
                              current: activeCount.toString(),
                              maximum: activeLimit.toString(),
                            ),
                            const SizedBox(height: 12),
                            for (final product in _products)
                              _LoanProductManagementCard(
                                product: product,
                                onEdit: () => _openForm(
                                  productId: product['id']?.toString(),
                                ),
                                onAction: (status) => _setStatus(
                                  product['id'].toString(),
                                  status,
                                ),
                                l10n: l10n,
                              ),
                          ],
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(loanProductText(context, 'new')),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.current, required this.maximum});

  final String current;
  final String maximum;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(loanProductText(context, 'quota'))),
              Text('$current of $maximum'),
            ],
          ),
        ),
      );
}

class _LoanProductManagementCard extends StatelessWidget {
  const _LoanProductManagementCard({
    required this.product,
    required this.onEdit,
    required this.onAction,
    required this.l10n,
  });

  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;
  final AppLocalizations l10n;

  String _statusLabel(BuildContext context, String status) => switch (status) {
        'active' => loanProductText(context, 'active'),
        'paused' => loanProductText(context, 'paused'),
        'unavailable' => loanProductText(context, 'unavailable_status'),
        'archived' => loanProductText(context, 'archived'),
        _ => loanProductText(context, 'draft'),
      };

  @override
  Widget build(BuildContext context) {
    final name = product['loan_product_categories'] is Map
        ? (product['loan_product_categories'] as Map)['name']?.toString()
        : null;
    final purpose = product['loan_product_purposes'] is Map
        ? (product['loan_product_purposes'] as Map)['name']?.toString()
        : null;
    final status = product['status']?.toString() ?? 'draft';
    final currency = product['currency_code']?.toString() ?? '';
    final min = product['minimum_amount']?.toString() ?? '—';
    final max = product['maximum_amount']?.toString() ?? '—';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product['product_title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(label: _statusLabel(context, status)),
              ],
            ),
            const SizedBox(height: 5),
            Text([name, purpose].whereType<String>().join(' · ')),
            const SizedBox(height: 5),
            Text('$currency $min – $max'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniMetric(
                  icon: Icons.visibility_outlined,
                  label:
                      '${loanProductText(context, 'views')}: ${product['views_count'] ?? 0}',
                ),
                _MiniMetric(
                  icon: Icons.mark_email_unread_outlined,
                  label:
                      '${loanProductText(context, 'enquiries')}: ${product['enquiries_count'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(loanProductText(context, 'edit')),
                ),
                if (status == 'draft' ||
                    status == 'paused' ||
                    status == 'unavailable')
                  TextButton.icon(
                    onPressed: () => onAction('active'),
                    icon: const Icon(Icons.publish_outlined, size: 18),
                    label: Text(status == 'draft'
                        ? loanProductText(context, 'publish')
                        : loanProductText(context, 'resume')),
                  ),
                if (status == 'active')
                  TextButton.icon(
                    onPressed: () => onAction('paused'),
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: Text(loanProductText(context, 'pause')),
                  ),
                if (status == 'active' || status == 'paused')
                  TextButton.icon(
                    onPressed: () => onAction('unavailable'),
                    icon: const Icon(Icons.block_outlined, size: 18),
                    label: Text(loanProductText(context, 'unavailable')),
                  ),
                if (status != 'archived')
                  TextButton.icon(
                    onPressed: () => onAction('archived'),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: Text(loanProductText(context, 'archive')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: .4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class LoanProductFormPage extends StatefulWidget {
  const LoanProductFormPage({super.key, this.productId});
  final String? productId;

  @override
  State<LoanProductFormPage> createState() => _LoanProductFormPageState();
}

class _LoanProductFormPageState extends State<LoanProductFormPage> {
  final _repository = getIt<LoanProductRepository>();
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _purposes = [];
  List<Map<String, dynamic>> _capabilities = [];
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _methods = [];
  List<Map<String, dynamic>> _frequencies = [];
  String? _identityType;
  String? _capabilityId;
  String? _category;
  String? _purpose;
  String? _currency;
  String? _interestMethod;
  String? _frequency;
  String? _periodUnit;
  String? _enquiryPreference;
  bool? _interestFree;
  bool? _secured;
  bool? _guarantorRequired;
  bool _featured = false;
  String? _productId;
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  TextEditingController _c(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repository.getCatalog('loan_product_categories'),
        _repository.getProviderCapabilities(),
        _repository.getCurrencies(),
        _repository.getCatalog('loan_product_interest_methods'),
        _repository.getCatalog('loan_product_repayment_frequencies'),
        _repository.getSelectedIdentity(),
      ]);
      _categories = results[0] as List<Map<String, dynamic>>;
      _capabilities = results[1] as List<Map<String, dynamic>>;
      _currencies = results[2] as List<Map<String, dynamic>>;
      _methods = results[3] as List<Map<String, dynamic>>;
      _frequencies = results[4] as List<Map<String, dynamic>>;
      _identityType = results[5] as String?;
      _category = _categories.firstOrNull?['slug']?.toString();
      _currency = _currencies
          .firstWhere(
            (row) => row['code'] == 'UGX',
            orElse: () => _currencies.firstOrNull ?? const {},
          )['code']
          ?.toString();
      _capabilityId = _capabilities
          .where((row) => row['identity_type'] == _identityType)
          .firstOrNull?['id']
          ?.toString();
      if (widget.productId != null) await _loadExistingProduct();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadExistingProduct() async {
    final rows = await _repository.getMyProducts();
    final product =
        rows.where((row) => row['id'] == widget.productId).firstOrNull;
    if (product == null)
      throw const ValidationException('Loan product not found.');
    _identityType = product['identity_type']?.toString();
    _capabilityId = product['provider_capability_id']?.toString();
    _category = product['category_slug']?.toString();
    _purpose = product['purpose_slug']?.toString();
    _currency = product['currency_code']?.toString();
    _productId = product['id']?.toString();
    _featured = product['is_featured'] == true;
    _c('product_title').text = product['product_title']?.toString() ?? '';
    _c('short_description').text =
        product['short_description']?.toString() ?? '';
    _c('minimum_amount').text = product['minimum_amount']?.toString() ?? '';
    _c('maximum_amount').text = product['maximum_amount']?.toString() ?? '';
    final terms = Map<String, dynamic>.from(product['terms'] as Map? ?? {});
    _interestMethod = terms['interest_method']?.toString();
    _frequency = terms['repayment_frequency']?.toString();
    _periodUnit = terms['period_unit']?.toString();
    _interestFree = terms['interest_free'] as bool?;
    _secured = terms['secured'] as bool?;
    _guarantorRequired = terms['guarantor_required'] as bool?;
    _enquiryPreference = terms['enquiry_preference']?.toString();
    _step = (terms['_draft_step'] as num?)?.toInt().clamp(0, 6) ?? 0;
    for (final key in [
      'lending_capacity',
      'interest_rate',
      'minimum_period',
      'maximum_period',
      'late_fee',
      'extra_fees',
      'collateral_type',
      'minimum_age',
      'employment_requirement',
      'minimum_income',
      'required_documents_text',
      'eligible_locations_text',
      'other_conditions',
      'promo_material_url',
      'additional_terms',
      'custom_repayment_frequency',
      'custom_period_unit',
    ]) {
      _c(key).text = terms[key]?.toString() ?? '';
    }
    await _loadPurposes();
  }

  Future<void> _loadPurposes() async {
    if (_category == null) {
      _purposes = [];
      _purpose = null;
      return;
    }
    _purposes = (await _repository.getCatalog('loan_product_purposes'))
        .where((row) => row['category_slug'] == _category)
        .toList();
    if (_purpose != null && !_purposes.any((row) => row['slug'] == _purpose)) {
      _purpose = null;
    }
  }

  List<Map<String, dynamic>> get _identityCapabilities => _capabilities
      .where((row) => row['identity_type'] == _identityType)
      .map((row) => {...row, '_display_name': _label(row)})
      .toList();

  String _label(Map<String, dynamic> row) {
    final nested = row['need_capabilities'];
    if (nested is Map) return nested['name']?.toString() ?? '';
    return row['name']?.toString() ?? '';
  }

  Map<String, dynamic> _terms({int? step}) => {
        'interest_method': _interestMethod,
        'interest_rate':
            _interestFree == true ? '0' : _c('interest_rate').text.trim(),
        'interest_free': _interestFree,
        'repayment_frequency': _frequency,
        'custom_repayment_frequency':
            _c('custom_repayment_frequency').text.trim(),
        'minimum_period': _c('minimum_period').text.trim(),
        'maximum_period': _c('maximum_period').text.trim(),
        'period_unit': _periodUnit,
        'custom_period_unit': _c('custom_period_unit').text.trim(),
        'extra_fees': _c('extra_fees').text.trim(),
        'late_fee': _c('late_fee').text.trim(),
        'secured': _secured,
        'collateral_type': _c('collateral_type').text.trim(),
        'guarantor_required': _guarantorRequired,
        'minimum_age': _c('minimum_age').text.trim(),
        'employment_requirement': _c('employment_requirement').text.trim(),
        'minimum_income': _c('minimum_income').text.trim(),
        'required_documents': _c('required_documents_text')
            .text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'eligible_locations': _c('eligible_locations_text')
            .text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'eligible_locations_text': _c('eligible_locations_text').text.trim(),
        'other_conditions': _c('other_conditions').text.trim(),
        'promo_material_url': _c('promo_material_url').text.trim(),
        'additional_terms': _c('additional_terms').text.trim(),
        'enquiry_preference': _enquiryPreference,
        'featured': _featured,
        if (step != null) '_draft_step': step,
      };

  Map<String, dynamic> _payload({int? step}) => {
        'identity_type': _identityType,
        'provider_capability_id': _capabilityId,
        'category_slug': _category,
        'purpose_slug': _purpose,
        'product_title': _c('product_title').text.trim(),
        'short_description': _c('short_description').text.trim(),
        'minimum_amount': _c('minimum_amount').text.replaceAll(',', '').trim(),
        'maximum_amount': _c('maximum_amount').text.replaceAll(',', '').trim(),
        'currency_code': _currency,
        'terms': _terms(step: step),
      };

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _identityType != null &&
            _capabilityId != null &&
            _category != null;
      case 1:
        return _purpose != null;
      case 2:
        final min = int.tryParse(_c('minimum_amount').text.replaceAll(',', ''));
        final max = int.tryParse(_c('maximum_amount').text.replaceAll(',', ''));
        return _c('product_title').text.trim().length >= 3 &&
            _c('short_description').text.trim().length >= 10 &&
            min != null &&
            max != null &&
            min > 0 &&
            max >= min &&
            _currency != null;
      case 3:
        final rate = double.tryParse(_c('interest_rate').text);
        final min = num.tryParse(_c('minimum_period').text);
        final max = num.tryParse(_c('maximum_period').text);
        return _interestMethod != null &&
            _interestFree != null &&
            (_interestFree == true ||
                (rate != null && rate >= 0 && rate <= 100)) &&
            _frequency != null &&
            min != null &&
            max != null &&
            max >= min &&
            _periodUnit != null;
      case 4:
        final age = int.tryParse(_c('minimum_age').text);
        return _secured != null &&
            _guarantorRequired != null &&
            age != null &&
            age >= 18 &&
            (_secured != true ||
                _c('collateral_type').text.trim().isNotEmpty) &&
            _c('eligible_locations_text').text.trim().isNotEmpty;
      case 5:
        return _enquiryPreference != null;
      default:
        return _validateAll();
    }
  }

  bool _validateAll() => List<int>.generate(6, (index) => index).every((index) {
        final prior = _step;
        _step = index;
        final valid = _validateCurrentStep();
        _step = prior;
        return valid;
      });

  Future<void> _saveStep(int nextStep) async {
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loanProductText(context, 'validation'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      _productId = await _repository.saveDraft(
        productId: _productId,
        payload: _payload(step: nextStep),
      );
      if (!mounted) return;
      if (_step == 0) await _loadPurposes();
      setState(() {
        _step = nextStep;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loanProductText(context, 'draft_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _saveDraftAndExit() async {
    if (_productId == null && (_category == null || _capabilityId == null)) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      _productId = await _repository.saveDraft(
        productId: _productId,
        payload: _payload(step: _step),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _publish() async {
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loanProductText(context, 'validation'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      _productId = await _repository.saveDraft(
        productId: _productId,
        payload: _payload(step: 6),
      );
      await _repository.publish(_productId!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _textField(
    String key,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c(key),
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : maxLines,
          decoration: InputDecoration(labelText: label, hintText: hint),
          textInputAction:
              maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        ),
      );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> rows,
    required String valueKey,
    required String labelKey,
    required ValueChanged<String?> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: rows
              .map((row) => DropdownMenuItem(
                    value: row[valueKey].toString(),
                    child: Text(
                        row[labelKey]?.toString() ?? row[valueKey].toString(),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget _choice(String title, bool? value, ValueChanged<bool?> changed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<bool>(
          initialValue: value,
          decoration: InputDecoration(labelText: title),
          items: [
            DropdownMenuItem(
                value: true, child: Text(loanProductText(context, 'required'))),
            DropdownMenuItem(value: false, child: Text('No')),
          ],
          onChanged: changed,
        ),
      );

  Widget _stepContent() {
    final t = (String key) => loanProductText(context, key);
    switch (_step) {
      case 0:
        return Column(children: [
          if (_identityType != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: Text(t('identity')),
              subtitle:
                  Text(_identityType == 'company' ? 'Company' : 'Individual'),
            ),
          if (_identityCapabilities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(t('no_capability'), textAlign: TextAlign.center),
            )
          else
            _dropdown(
              label: t('capability'),
              value: _capabilityId,
              rows: _identityCapabilities,
              valueKey: 'id',
              labelKey: '_display_name',
              onChanged: (value) => setState(() => _capabilityId = value),
            ),
          _dropdown(
            label: t('category'),
            value: _category,
            rows: _categories,
            valueKey: 'slug',
            labelKey: 'name',
            onChanged: (value) => setState(() {
              _category = value;
              _purpose = null;
            }),
          ),
        ]);
      case 1:
        return _dropdown(
            label: t('purpose'),
            value: _purpose,
            rows: _purposes,
            valueKey: 'slug',
            labelKey: 'name',
            onChanged: (value) => setState(() => _purpose = value));
      case 2:
        return Column(children: [
          _textField('product_title', t('name')),
          _textField('short_description', t('description'), maxLines: 3),
          _textField('minimum_amount', t('minimum'),
              keyboardType: TextInputType.number),
          _textField('maximum_amount', t('maximum'),
              keyboardType: TextInputType.number),
          _dropdown(
              label: t('currency'),
              value: _currency,
              rows: _currencies,
              valueKey: 'code',
              labelKey: 'code',
              onChanged: (value) => setState(() => _currency = value)),
          _textField('lending_capacity', t('capacity'),
              keyboardType: TextInputType.number, hint: t('capacity_hint')),
        ]);
      case 3:
        return Column(children: [
          _dropdown(
              label: t('method'),
              value: _interestMethod,
              rows: _methods,
              valueKey: 'slug',
              labelKey: 'name',
              onChanged: (value) => setState(() => _interestMethod = value)),
          _choice(t('interest_free'), _interestFree,
              (value) => setState(() => _interestFree = value)),
          if (_interestFree != true)
            _textField('interest_rate', t('interest'),
                keyboardType: TextInputType.number),
          _dropdown(
              label: t('frequency'),
              value: _frequency,
              rows: _frequencies,
              valueKey: 'slug',
              labelKey: 'name',
              onChanged: (value) => setState(() => _frequency = value)),
          if (_frequency == 'custom')
            _textField('custom_repayment_frequency', t('custom')),
          _textField('minimum_period', t('minimum_period'),
              keyboardType: TextInputType.number),
          _textField('maximum_period', t('maximum_period'),
              keyboardType: TextInputType.number),
          _dropdown(
              label: t('period_unit'),
              value: _periodUnit,
              rows: ['day', 'week', 'month', 'year']
                  .map((slug) => {'slug': slug, 'name': t(slug)})
                  .toList(),
              valueKey: 'slug',
              labelKey: 'name',
              onChanged: (value) => setState(() => _periodUnit = value)),
          _textField('extra_fees', 'Extra fees', maxLines: 3),
          _textField('late_fee', 'Late fee',
              keyboardType: TextInputType.number),
        ]);
      case 4:
        return Column(children: [
          _choice(t('secured'), _secured,
              (value) => setState(() => _secured = value)),
          if (_secured == true)
            _textField('collateral_type', t('collateral'), maxLines: 2),
          _choice(t('guarantor'), _guarantorRequired,
              (value) => setState(() => _guarantorRequired = value)),
          _textField('minimum_age', t('age'),
              keyboardType: TextInputType.number),
          _textField('employment_requirement', t('employment'), maxLines: 2),
          _textField('minimum_income', t('income'),
              keyboardType: TextInputType.number),
          _textField('required_documents_text', t('documents'), maxLines: 4),
          _textField('eligible_locations_text', t('locations'), maxLines: 4),
          _textField('other_conditions', t('conditions'), maxLines: 3),
        ]);
      case 5:
        return Column(children: [
          _textField('promo_material_url', t('promo')),
          _textField('additional_terms', t('terms'), maxLines: 4),
          _dropdown(
              label: t('enquiry'),
              value: _enquiryPreference,
              rows: const [
                {'slug': 'in_app', 'name': 'In-app enquiry'},
                {'slug': 'phone', 'name': 'Phone contact'},
                {'slug': 'both', 'name': 'In-app and phone'},
              ],
              valueKey: 'slug',
              labelKey: 'name',
              onChanged: (value) => setState(() => _enquiryPreference = value)),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _featured,
            title: Text(t('featured')),
            onChanged: (value) => setState(() => _featured = value),
          ),
        ]);
      default:
        return _ProductPreview(
          payload: _payload(),
          categoryName: _categories
                  .where((row) => row['slug'] == _category)
                  .firstOrNull?['name']
                  ?.toString() ??
              '',
          purposeName: _purposes
                  .where((row) => row['slug'] == _purpose)
                  .firstOrNull?['name']
                  ?.toString() ??
              '',
          capabilityName: _identityCapabilities
                  .where((row) => row['id'] == _capabilityId)
                  .map(_label)
                  .firstOrNull ??
              '',
        );
    }
  }

  String _stepTitle(BuildContext context) => switch (_step) {
        0 => loanProductText(context, 'category'),
        1 => loanProductText(context, 'purpose'),
        2 => 'Loan information',
        3 => 'Interest and repayment',
        4 => 'Security and eligibility',
        5 => 'Additional information',
        _ => loanProductText(context, 'preview'),
      };

  @override
  Widget build(BuildContext context) {
    final t = (String key) => loanProductText(context, key);
    return Scaffold(
      appBar: AppBar(title: Text(t('new'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _identityType == null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(t('no_capability'),
                              textAlign: TextAlign.center)))
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                        children: [
                          Row(children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                  child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i == 6 ? 0 : 6),
                                decoration: BoxDecoration(
                                    color: i <= _step
                                        ? AppColors.accent
                                        : Theme.of(context).dividerColor,
                                    borderRadius: BorderRadius.circular(4)),
                              )),
                          ]),
                          const SizedBox(height: 12),
                          Text('${t('step')} ${_step + 1} of 7',
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text(_stepTitle(context),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 18),
                          _stepContent(),
                          if (_step == 6) ...[
                            const SizedBox(height: 8),
                            Text(t('publish_gate'),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
      bottomNavigationBar: _loading || _error != null || _identityType == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(children: [
                if (_step > 0)
                  Expanded(
                      child: OutlinedButton(
                    onPressed: _saving ? null : () => setState(() => _step--),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: Text(t('back')),
                  )),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : _step == 6
                              ? _publish
                              : () => _saveStep(_step + 1),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_step == 6 ? t('publish') : t('next')),
                    )),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: t('save'),
                  onPressed: _saving ? null : _saveDraftAndExit,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.save_outlined),
                ),
              ]),
            ),
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview(
      {required this.payload,
      required this.categoryName,
      required this.purposeName,
      required this.capabilityName});
  final Map<String, dynamic> payload;
  final String categoryName;
  final String purposeName;
  final String capabilityName;

  @override
  Widget build(BuildContext context) {
    final terms = Map<String, dynamic>.from(payload['terms'] as Map? ?? {});
    final currency = payload['currency_code']?.toString() ?? '';
    final values = <String, String>{
      'Product': payload['product_title']?.toString() ?? '',
      'Financial service': capabilityName,
      'Category': categoryName,
      'Purpose': purposeName,
      'Amount range':
          '$currency ${payload['minimum_amount']} – $currency ${payload['maximum_amount']}',
      'Interest method': terms['interest_method']?.toString() ?? '',
      'Interest rate': terms['interest_free'] == true
          ? 'Interest-free'
          : '${terms['interest_rate']}%',
      'Repayment': terms['repayment_frequency']?.toString() ?? '',
      'Eligibility locations':
          (terms['eligible_locations'] as List? ?? const []).join(', '),
      'Security': terms['secured'] == true ? 'Secured' : 'Unsecured',
    };
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payload['product_title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(payload['short_description']?.toString() ?? ''),
                const Divider(height: 24),
                for (final entry in values.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text(entry.value)),
                        ]),
                  ),
              ],
            )));
  }
}

class LoanProductMarketplacePage extends StatefulWidget {
  const LoanProductMarketplacePage({super.key});
  @override
  State<LoanProductMarketplacePage> createState() =>
      _LoanProductMarketplacePageState();
}

class _LoanProductMarketplacePageState
    extends State<LoanProductMarketplacePage> {
  final _repository = getIt<LoanProductRepository>();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await _repository.getMarketplaceProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(loanProductText(context, 'browse'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _products.isEmpty
                    ? Center(child: Text(loanProductText(context, 'none')))
                    : ListView(padding: const EdgeInsets.all(14), children: [
                        for (final product in _products)
                          Card(
                              child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                            product['product_title']
                                                    ?.toString() ??
                                                '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium)),
                                    if (product['provider_verified'] == true)
                                      const Chip(
                                          avatar: Icon(Icons.verified_outlined,
                                              size: 16),
                                          label: Text('Verified')),
                                  ]),
                                  Text(
                                      '${product['provider_name'] ?? ''} · ${product['identity_type'] == 'company' ? 'Company' : 'Individual'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${product['category_name'] ?? ''} · ${product['purpose_name'] ?? ''}'),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${product['currency_code'] ?? ''} ${product['minimum_amount'] ?? ''} – ${product['maximum_amount'] ?? ''}'),
                                  const SizedBox(height: 8),
                                  Text(product['short_description']
                                          ?.toString() ??
                                      ''),
                                ]),
                          )),
                      ]),
      );
}
