import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../data/verification_service.dart';

class MarketplaceAccessWidget extends StatefulWidget {
  const MarketplaceAccessWidget({super.key, required this.user});

  final NipanzeUser user;

  @override
  State<MarketplaceAccessWidget> createState() =>
      _MarketplaceAccessWidgetState();
}

class _MarketplaceAccessWidgetState extends State<MarketplaceAccessWidget> {
  static const _activities = <(String, String)>[
    ('Loan Requests', 'loan_request'),
    ('Forex Requests', 'forex_request'),
    ('Need Requests', 'need_request'),
    ('Make Offers', 'make_offers'),
    ('Offer a Service', 'service_offer'),
  ];

  List<bool>? _access;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final service = getIt<VerificationService>();
    final results = await Future.wait(
      _activities.map((entry) async {
        if (entry.$2 == 'make_offers') {
          final offers = await Future.wait([
            service.canPerform(action: 'loan_offer', user: widget.user),
            service.canPerform(action: 'forex_offer', user: widget.user),
            service.canPerform(action: 'need_offer', user: widget.user),
          ]);
          return offers.every((result) => result.allowed);
        }
        final result = await service.canPerform(
          action: entry.$2,
          user: widget.user,
        );
        return result.allowed;
      }),
    );
    if (mounted) setState(() => _access = results);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final access = _access;
    final unlockedCount = access?.where((allowed) => allowed).length ?? 0;
    final allUnlocked = access != null && unlockedCount == _activities.length;
    final green = isDark ? const Color(0xFF45E99A) : const Color(0xFF119B5A);
    final panel = allUnlocked
        ? (isDark ? const Color(0xFF0B2B27) : const Color(0xFFEAF8F1))
        : (isDark ? AppColors.bg2Dark : AppColors.bg2Light);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: allUnlocked
              ? green.withValues(alpha: 0.55)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allUnlocked ? Icons.verified_rounded : Icons.lock_outline,
                size: 16,
                color: allUnlocked ? green : AppColors.accent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Marketplace Access',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF172033),
                  ),
                ),
              ),
              if (access != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unlockedCount of ${_activities.length}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            allUnlocked
                ? 'Identity verified. You can now create listings.'
                : 'Access depends on your verification and activity requirements.',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.text2Dark : AppColors.text2Light,
            ),
          ),
          const SizedBox(height: 7),
          if (access == null)
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(_activities.length, (index) {
                final allowed = access[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: allowed
                        ? green.withValues(alpha: 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: allowed
                          ? green.withValues(alpha: 0.25)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    ),
                  ),
                  child: Text(
                    _activities[index].$1,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: allowed
                          ? green
                          : (isDark
                              ? AppColors.text2Dark
                              : AppColors.text2Light),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
