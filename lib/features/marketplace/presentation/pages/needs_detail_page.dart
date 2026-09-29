import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_offer.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/marketplace_item.dart';

class NeedsDetailPage extends StatefulWidget {
  const NeedsDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<NeedsDetailPage> createState() => _NeedsDetailPageState();
}

class _NeedsDetailPageState extends State<NeedsDetailPage> {
  late Future<NeedsListing> _futureNeed;
  List<NeedOffer> _offers = [];
  bool _loadingOffers = false;
  bool _submittingOffer = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadNeed();
  }

  void _loadNeed() {
    _futureNeed = getIt<MarketplaceRepository>().getNeedsDetail(widget.requestId);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _loadingOffers = true);
    try {
      final offers = await getIt<NeedsRepository>().getOffers(widget.requestId);
      if (mounted) {
        setState(() {
          _offers = offers;
          _loadingOffers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  Future<void> _showMakeOfferSheet(NeedsListing need) async {
    final priceController = TextEditingController();
    final timelineController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make an Offer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit your proposal directly to the requester.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Offer Price (${need.currency})',
                        hintText: 'e.g. 450000',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) return 'Enter your proposed price';
                        final numVal = int.tryParse(text);
                        if (numVal == null || numVal <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: timelineController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Delivery / Execution Timeline',
                        hintText: 'e.g. In 3 days, Immediate, Within 2 weeks',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if ((val ?? '').trim().isEmpty) {
                          return 'Specify your timeline';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: messageController,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Proposal Details & Experience',
                        hintText: 'Describe how you will fulfill this need...',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if ((val ?? '').trim().length < 5) {
                          return 'Add some details to your offer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submittingOffer
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => _submittingOffer = true);
                                try {
                                  final price = int.parse(priceController.text.trim());
                                  await getIt<NeedsRepository>().makeOffer(
                                    needId: need.requestId,
                                    price: price,
                                    currency: need.currency,
                                    timelineText: timelineController.text.trim(),
                                    message: messageController.text.trim(),
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext, true);
                                  }
                                } catch (e) {
                                  setSheetState(() => _submittingOffer = false);
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is AppException
                                              ? e.message
                                              : 'Could not submit offer',
                                        ),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: _submittingOffer
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadOffers();
    }
  }

  Future<void> _acceptOffer(String offerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Accept Offer?'),
        content: const Text(
          'Accepting this offer will reject any competing offers and unlock direct contact details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Accept Offer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionInProgress = true);
    try {
      await getIt<NeedsRepository>().acceptOffer(
        needId: widget.requestId,
        offerId: offerId,
      );
      if (mounted) {
        setState(() => _actionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer accepted! Contact details unlocked.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadNeed();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'Failed to accept offer',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _unlockContact(String offerId) async {
    setState(() => _actionInProgress = true);
    try {
      await getIt<NeedsRepository>().unlockContact(offerId: offerId);
      if (mounted) {
        setState(() => _actionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact details confirmed!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'Failed to unlock contact',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final detailSurface = isDark
        ? AppColors.bg2Dark
        : theme.colorScheme.surfaceContainerHighest;

    return FutureBuilder<NeedsListing>(
      future: _futureNeed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Unable to load this Need.')),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final need = snapshot.data!;
        final hasAlreadyOffered = _offers.any((o) => o.isOwnOffer);
        final acceptedOffer = _offers.cast<NeedOffer?>().firstWhere(
              (o) => o?.status == 'accepted',
              orElse: () => null,
            );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text('Need details'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: detailSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(need.categoryIcon, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                need.category,
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _UrgencyBadge(urgency: need.urgency),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      need.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _budget(need),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _NeedFact(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: need.location,
                        ),
                        _NeedFact(
                          icon: Icons.local_offer_rounded,
                          label: 'Offers',
                          value: '${need.numberOfOffers} offers',
                        ),
                        if (need.timeRemaining != null)
                          _NeedFact(
                            icon: Icons.schedule_rounded,
                            label: 'Timeline',
                            value: need.timeRemaining!,
                          ),
                        if (need.trustIsVerified)
                          const _NeedFact(
                            icon: Icons.verified_user_rounded,
                            label: 'Trust',
                            value: 'Verified requester',
                          ),
                      ],
                    ),
                    if (need.details.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'CATEGORY DETAILS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in need.details.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatKey(entry.key)}: ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Expanded(
                                child: Text('${entry.value}'),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (need.specification.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'ABOUT THE NEED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        need.specification,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Offers Section ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Provider Offers (${_offers.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_loadingOffers)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_offers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: detailSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'No offers placed yet. Be the first provider to quote!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._offers.map(
                  (offer) => _OfferCard(
                    offer: offer,
                    onAccept: _actionInProgress
                        ? null
                        : () => _acceptOffer(offer.id),
                    onUnlock: _actionInProgress
                        ? null
                        : () => _unlockContact(offer.id),
                  ),
                ),
              const SizedBox(height: 24),
              // ── Make Offer Action Button ─────────────────────────────────
              if (!hasAlreadyOffered && acceptedOffer == null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Make an Offer on this Need'),
                  onPressed: () => _showMakeOfferSheet(need),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _budget(NeedsListing need) => need.budget > 0
      ? '${need.currency} ${NumberFormat.decimalPattern().format(need.budget)}'
      : 'Open to suitable proposals';
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    this.onAccept,
    this.onUnlock,
  });

  final NeedOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAccepted = offer.status == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAccepted
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark ? AppColors.bg2Dark : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAccepted
              ? AppColors.success
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${offer.currency} ${NumberFormat.decimalPattern().format(offer.price)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              if (offer.isProviderVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Verified Provider',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          if (offer.timelineText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Timeline: ${offer.timelineText}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          if (offer.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              offer.message,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          if (offer.id.isNotEmpty && offer.status == 'pending' && onAccept != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Accept Offer'),
              ),
            ),
          if (isAccepted && onUnlock != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, size: 14),
                label: const Text('View Contact Details'),
                onPressed: onUnlock,
              ),
            ),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.urgency});

  final String urgency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 11,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            urgency,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedFact extends StatelessWidget {
  const _NeedFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
