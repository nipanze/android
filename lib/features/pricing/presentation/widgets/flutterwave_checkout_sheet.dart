import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

// ─── Payment step enum ────────────────────────────────────────────────────────

enum _PayStep { details, processing, success, error }

enum PaymentMethod { mobileMoney, card }

// ─── Public sheet ─────────────────────────────────────────────────────────────

class FlutterwaveCheckoutSheet extends StatefulWidget {
  const FlutterwaveCheckoutSheet({
    super.key,
    required this.plan,
    required this.priceFormatted,
    required this.country,
  });

  final SubscriptionPlan plan;
  final String priceFormatted;
  final EastAfricaCountry country;

  static void show(
    BuildContext context, {
    required SubscriptionPlan plan,
    required String priceFormatted,
    required EastAfricaCountry country,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: FlutterwaveCheckoutSheet(
          plan: plan,
          priceFormatted: priceFormatted,
          country: country,
        ),
      ),
    );
  }

  @override
  State<FlutterwaveCheckoutSheet> createState() =>
      _FlutterwaveCheckoutSheetState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _FlutterwaveCheckoutSheetState extends State<FlutterwaveCheckoutSheet>
    with TickerProviderStateMixin {
  _PayStep _step = _PayStep.details;
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;

  late TextEditingController _phoneController;
  late TextEditingController _cardController;
  late TextEditingController _cardNameController;
  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCvvController;

  String? _errorMessage;
  String _txRef = '';
  int _processingStep = 0;
  Timer? _processingTimer;

  late final AnimationController _successAnim;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final initialPhone =
        authState is AuthAuthenticated ? authState.user.phone : '';
    _phoneController = TextEditingController(text: initialPhone ?? '');
    _cardController = TextEditingController(text: '4111 2222 3333 4444');
    _cardNameController = TextEditingController();
    _cardExpiryController = TextEditingController(text: '12/27');
    _cardCvvController = TextEditingController(text: '123');

    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale =
        CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _phoneController.dispose();
    _cardController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  String get _planName => switch (widget.plan) {
        SubscriptionPlan.free => 'Free',
        SubscriptionPlan.lender => 'Lender',
        SubscriptionPlan.pro => 'Pro',
      };

  String _generateTxRef() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'NIPA-$ts-$rand';
  }

  // ─── Payment logic ──────────────────────────────────────────────────────────

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.mobileMoney &&
        _phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number.');
      return;
    }

    _txRef = _generateTxRef();
    setState(() {
      _step = _PayStep.processing;
      _processingStep = 0;
      _errorMessage = null;
    });

    // Animate 3 processing sub-steps, one per second
    _processingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _processingStep = _processingStep + 1);
      if (_processingStep >= 2) t.cancel();
    });

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final userId = authState.user.id;
        final client = Supabase.instance.client;

        // Simulate webhook: upsert subscription as 'active'
        await client.from('subscriptions').upsert({
          'user_id': userId,
          'plan': _planName.toLowerCase(),
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        // Mirror to profiles for fast reads
        await client.from('profiles').update({
          'subscription_plan': _planName.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        if (!mounted) return;
        // Refresh AuthBloc so UI immediately reflects new plan
        context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
      }

      if (!mounted) return;
      setState(() => _step = _PayStep.success);
      unawaited(_successAnim.forward());

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _PayStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFE8480C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('\u26A1', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.flutterwaveCheckoutTitle ?? 'Flutterwave Checkout',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${widget.country.flag} ${widget.country.name}  \u00B7  ${widget.country.currency}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                    ),
                  ],
                ),
              ),
              if (_step == _PayStep.details || _step == _PayStep.error)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Step indicator (only on details / processing)
          if (_step == _PayStep.details || _step == _PayStep.processing)
            _StepIndicator(
              currentStep: _step == _PayStep.details ? 0 : 1,
              labels: [
                l10n?.paymentStep1 ?? 'Details',
                l10n?.paymentStep2 ?? 'Processing',
                l10n?.paymentStep3 ?? 'Done',
              ],
            ),

          if (_step == _PayStep.details || _step == _PayStep.processing)
            Divider(
              height: 24,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),

          // Body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_step) {
              _PayStep.details => _buildDetailsBody(context, l10n),
              _PayStep.processing => _buildProcessingBody(context, l10n),
              _PayStep.success => _buildSuccessBody(context, l10n),
              _PayStep.error => _buildErrorBody(context, l10n),
            },
          ),

          // Footer
          if (_step != _PayStep.success) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u26A1', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  l10n?.poweredByFlutterwave ?? 'Powered by Flutterwave',
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Details body ────────────────────────────────────────────────────────────

  Widget _buildDetailsBody(BuildContext context, AppLocalizations? l10n) {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderSummaryCard(
          planName: _planName,
          priceFormatted: widget.priceFormatted,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.paymentMethod ?? 'Payment Method',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MethodChip(
                icon: Icons.phone_android_rounded,
                label: l10n?.mobileMoney ?? 'Mobile Money',
                selected: _selectedMethod == PaymentMethod.mobileMoney,
                onTap: () => setState(
                    () => _selectedMethod = PaymentMethod.mobileMoney),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MethodChip(
                icon: Icons.credit_card_rounded,
                label: l10n?.creditOrDebitCard ?? 'Card',
                selected: _selectedMethod == PaymentMethod.card,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.card),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_selectedMethod == PaymentMethod.mobileMoney)
          _buildMobileFields(context, l10n)
        else
          _buildCardFields(context),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8480C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _processPayment,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u26A1', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  l10n?.payWithFlutterwave ?? 'Pay with Flutterwave',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFields(BuildContext context, AppLocalizations? l10n) {
    return TextField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: l10n?.enterMobileNumber ?? 'Mobile Money number',
        hintText: '+256 7XX XXX XXX',
        prefixIcon: const Icon(Icons.phone_rounded, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildCardFields(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _cardController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cardNameController,
          decoration: InputDecoration(
            labelText: 'Name on card',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _cardCvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [LengthLimitingTextInputFormatter(4)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Processing body ─────────────────────────────────────────────────────────

  Widget _buildProcessingBody(BuildContext context, AppLocalizations? l10n) {
    final steps = [
      l10n?.paymentProcessingStep1 ?? 'Connecting to Flutterwave\u2026',
      l10n?.paymentProcessingStep2 ?? 'Verifying payment\u2026',
      l10n?.paymentProcessingStep3 ?? 'Activating subscription\u2026',
    ];
    return Padding(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFFE8480C),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (i) {
            final isDone = i < _processingStep;
            final isActive = i == _processingStep;
            return AnimatedOpacity(
              opacity: i <= _processingStep ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isDone
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                              key: ValueKey('done'))
                          : isActive
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE8480C),
                                  ),
                                )
                              : const Icon(Icons.radio_button_unchecked,
                                  size: 18,
                                  color: Colors.grey,
                                  key: ValueKey('idle')),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Do not close this screen',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  // ─── Success body ─────────────────────────────────────────────────────────────

  Widget _buildSuccessBody(BuildContext context, AppLocalizations? l10n) {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 52),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.paymentSuccessful ?? 'Payment Successful!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.subscriptionActivated(_planName) ??
                'Your $_planName subscription is now active.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  l10n?.transactionRef(_txRef) ?? 'Ref: $_txRef',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Recorded in Supabase Cloud',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Closing automatically\u2026',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
          ),
        ],
      ),
    );
  }

  // ─── Error body ──────────────────────────────────────────────────────────────

  Widget _buildErrorBody(BuildContext context, AppLocalizations? l10n) {
    return Padding(
      key: const ValueKey('error'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.paymentFailed ?? 'Payment failed. Please try again.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8480C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      setState(() => _step = _PayStep.details),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.labels});
  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8480C);
    return Row(
      children: List.generate(labels.length, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;
        final color = (isDone || isActive)
            ? orange
            : Theme.of(context).dividerColor;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: (isDone || isActive)
                      ? orange.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 13, color: orange)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? orange : color,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? orange
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: isDone ? 0.7 : 0.35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: isDone
                        ? orange
                        : Theme.of(context).dividerColor,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Order Summary Card ──────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.planName,
    required this.priceFormatted,
    required this.l10n,
  });
  final String planName;
  final String priceFormatted;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5A623), Color(0xFFE8480C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.orderSummary ?? 'Order Summary',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$planName Subscription',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            priceFormatted,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE8480C),
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Method chip ─────────────────────────────────────────────────────────────

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8480C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? orange.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? orange : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected
                    ? orange
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? orange
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
