import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/verification_gate_modal.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_offer.dart';
import '../../../provider/domain/repositories/provider_repository_interface.dart';
import '../../../provider/presentation/pages/add_service_sheet.dart';
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
    _futureNeed =
        getIt<MarketplaceRepository>().getNeedsDetail(widget.requestId);
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
    final allowed = await VerificationGateModal.checkAndGate(
      context,
      action: 'need_offer',
      categorySlug: need.categorySlug,
      capabilitySlug: need.capabilitySlug,
      customMessage: 'Verify your identity before making an offer on Nipanze.',
    );
    if (!allowed || !mounted) return;

    final priceController = TextEditingController();
    final timelineController = TextEditingController();
    final messageController = TextEditingController();
    final termsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedTimeline = '';
    var selectedStrategy = '';
    var isPreview = false;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return _NeedsOfferSheetLifetime(
          controllers: [
            priceController,
            timelineController,
            messageController,
            termsController,
          ],
          child: StatefulBuilder(builder: (ctx, setSheetState) {
            final price = int.tryParse(priceController.text.trim());
            final isOfferValid = price != null &&
                price > 0 &&
                timelineController.text.trim().isNotEmpty &&
                messageController.text.trim().length >= 5;
            final currencyFormat = NumberFormat.decimalPattern(
              Localizations.localeOf(ctx).toLanguageTag(),
            );
            final priceText = price == null
                ? ''
                : '${need.currency} ${currencyFormat.format(price)}';
            final budgetText = need.budget > 0
                ? '${need.currency} ${currencyFormat.format(need.budget)}'
                : 'Open to suitable proposals';
            final combinedText =
                '${messageController.text} ${termsController.text}'
                    .toLowerCase();
            final suggestions = _offerSuggestions(need.categorySlug);
            final strategyHint = switch (selectedStrategy) {
              'Fastest' => 'Make your earliest realistic delivery point clear.',
              'Best Price' =>
                'Explain the value behind your price; your price is unchanged.',
              'Best Value' =>
                'Clarify how price, quality, and service fit together.',
              _ => 'Review the details that help the requester compare offers.',
            };

            Future<void> submitOffer() async {
              if (!formKey.currentState!.validate()) {
                setSheetState(() {});
                return;
              }
              if (!await ensureOnlineForAction(sheetContext) ||
                  !sheetContext.mounted) {
                return;
              }
              setSheetState(() => _submittingOffer = true);
              try {
                final offerMessage = messageController.text.trim();
                final additionalTerms = termsController.text.trim();
                await getIt<NeedsRepository>().makeOffer(
                  needId: need.requestId,
                  price: int.parse(priceController.text.trim()),
                  currency: need.currency,
                  timelineText: timelineController.text.trim(),
                  message: additionalTerms.isEmpty
                      ? offerMessage
                      : '$offerMessage\n\nAdditional terms:\n$additionalTerms',
                );
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, true);
                }
              } catch (e) {
                if (sheetContext.mounted) {
                  setSheetState(() => _submittingOffer = false);
                }
                final errStr = e.toString();
                final isGatingError = errStr.contains('P0203') ||
                    errStr.toLowerCase().contains('declare a capability');
                if (isGatingError && sheetContext.mounted) {
                  Navigator.pop(sheetContext, false);
                  if (context.mounted) {
                    unawaited(_promptCapabilityDeclaration(need));
                  }
                  return;
                }
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
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    height: constraints.maxHeight * .96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPreview ? 'Preview Offer' : 'Make an Offer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: isPreview
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _offerPreviewSection(
                                        'Need',
                                        need.title,
                                        context: ctx,
                                      ),
                                      _offerPreviewSection(
                                        'Your Offer',
                                        priceText,
                                        context: ctx,
                                      ),
                                      _offerPreviewSection(
                                        'Timeline',
                                        timelineController.text.trim(),
                                        context: ctx,
                                      ),
                                      _offerPreviewSection(
                                        "What's included",
                                        messageController.text.trim(),
                                        context: ctx,
                                      ),
                                      if (termsController.text
                                          .trim()
                                          .isNotEmpty)
                                        _offerPreviewSection(
                                          'Additional terms',
                                          termsController.text.trim(),
                                          context: ctx,
                                        ),
                                      _offerPreviewSection(
                                        'Provider',
                                        'Your Nipanze provider account',
                                        context: ctx,
                                      ),
                                    ],
                                  )
                                : Form(
                                    key: formKey,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "You're offering on",
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                need.title,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '$budgetText · ${need.location} · ${need.timeRemaining ?? need.urgency}',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              if (need.specification
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  need.specification.trim(),
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(height: 1.35),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: priceController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: InputDecoration(
                                            labelText:
                                                'Offer Price (${need.currency})',
                                            hintText: 'e.g. 450000',
                                            border: const OutlineInputBorder(),
                                            helperText: price == null ||
                                                    need.budget <= 0
                                                ? null
                                                : price <= need.budget
                                                    ? "Within the requester's budget"
                                                    : "Above the requester's budget",
                                          ),
                                          validator: (val) {
                                            final value =
                                                int.tryParse(val?.trim() ?? '');
                                            if (value == null || value <= 0) {
                                              return 'Enter a valid offer price';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Delivery / Execution Timeline',
                                          style: theme.textTheme.labelLarge,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 2,
                                          children: [
                                            for (final option in [
                                              '1–3 days',
                                              '1 week',
                                              '2–4 weeks',
                                              'Custom',
                                            ])
                                              ChoiceChip(
                                                label: Text(option),
                                                selected:
                                                    selectedTimeline == option,
                                                onSelected: (_) {
                                                  setSheetState(() {
                                                    selectedTimeline = option;
                                                    timelineController.text =
                                                        option == 'Custom'
                                                            ? ''
                                                            : option;
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                        if (selectedTimeline == 'Custom') ...[
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: timelineController,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            onChanged: (_) =>
                                                setSheetState(() {}),
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Describe your timeline',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (val) =>
                                                (val ?? '').trim().isEmpty
                                                    ? 'Specify your timeline'
                                                    : null,
                                          ),
                                        ],
                                        if (selectedTimeline != 'Custom')
                                          FormField<String>(
                                            initialValue: '',
                                            validator: (_) => timelineController
                                                    .text
                                                    .trim()
                                                    .isEmpty
                                                ? 'Choose a timeline'
                                                : null,
                                            builder: (field) => field.hasError
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 12, top: 4),
                                                    child: Text(
                                                      field.errorText!,
                                                      style: TextStyle(
                                                        color: theme
                                                            .colorScheme.error,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: messageController,
                                          minLines: 3,
                                          maxLines: 5,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Proposal Details & Experience',
                                            hintText:
                                                "Explain what's included, relevant experience, warranty/support, or important conditions.",
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                          ),
                                          validator: (val) => (val ?? '')
                                                      .trim()
                                                      .length <
                                                  5
                                              ? 'Add at least 5 characters of offer details'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: termsController,
                                          minLines: 2,
                                          maxLines: 4,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Additional Terms or Expectations',
                                            hintText:
                                                'Add conditions, requirements, payment expectations, exclusions, or warranty terms.',
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Quick Offer Strategy',
                                          style: theme.textTheme.labelLarge,
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            for (final strategy in [
                                              'Fastest',
                                              'Best Price',
                                              'Best Value',
                                            ])
                                              ChoiceChip(
                                                label: Text(switch (strategy) {
                                                  'Fastest' => '⚡ Fastest',
                                                  'Best Price' =>
                                                    '💰 Best Price',
                                                  _ => '⭐ Best Value',
                                                }),
                                                selected: selectedStrategy ==
                                                    strategy,
                                                onSelected: (_) =>
                                                    setSheetState(
                                                  () => selectedStrategy =
                                                      selectedStrategy ==
                                                              strategy
                                                          ? ''
                                                          : strategy,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (selectedStrategy.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2, bottom: 8),
                                            child: Text(
                                              strategyHint,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        Theme(
                                          data: theme.copyWith(
                                            dividerColor: Colors.transparent,
                                          ),
                                          child: ExpansionTile(
                                            tilePadding: EdgeInsets.zero,
                                            childrenPadding:
                                                const EdgeInsets.only(
                                                    bottom: 8),
                                            title:
                                                const Text('✨ Offer Assistant'),
                                            subtitle: const Text(
                                              'A few details worth checking',
                                            ),
                                            children: [
                                              _assistantRow(
                                                price != null && price > 0,
                                                'Offer price entered',
                                              ),
                                              _assistantRow(
                                                timelineController.text
                                                    .trim()
                                                    .isNotEmpty,
                                                'Timeline entered',
                                              ),
                                              if (selectedStrategy == 'Fastest')
                                                const _AssistantNote(
                                                  text:
                                                      'Confirm the earliest realistic timeline.',
                                                ),
                                              if (selectedStrategy ==
                                                  'Best Price')
                                                const _AssistantNote(
                                                  text:
                                                      'A competitive price can still state what is included.',
                                                ),
                                              if (selectedStrategy ==
                                                  'Best Value')
                                                const _AssistantNote(
                                                  text:
                                                      'Balance price with quality and service details.',
                                                ),
                                              for (final suggestion
                                                  in suggestions)
                                                _assistantRow(
                                                  suggestion.keywords.any(
                                                    combinedText.contains,
                                                  ),
                                                  suggestion.label,
                                                ),
                                              if (need.categorySlug ==
                                                  'travel_international')
                                                const _AssistantNote(
                                                  text:
                                                      'For visa-related services, do not promise approval or a guaranteed outcome.',
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isPreview) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _submittingOffer
                                      ? null
                                      : () => setSheetState(
                                            () => isPreview = false,
                                          ),
                                  child: const Text('Edit Offer'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _submittingOffer ? null : submitOffer,
                                  child: _submittingOffer
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Submit Offer'),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: !_submittingOffer && isOfferValid
                                      ? () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            setSheetState(
                                                () => isPreview = true);
                                          }
                                        }
                                      : null,
                                  child: const Text('Preview Offer'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
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

  List<_OfferSuggestion> _offerSuggestions(String categorySlug) {
    const common = <_OfferSuggestion>[
      _OfferSuggestion('Mention warranty or support', ['warranty', 'support']),
      _OfferSuggestion('Clarify what is included in the price', [
        'included',
        'includes',
        'including',
        'excludes',
        'excluding',
      ]),
    ];
    final category = switch (categorySlug) {
      'machinery_equipment' => const <_OfferSuggestion>[
          _OfferSuggestion(
              'Specify equipment type or model', ['model', 'type']),
          _OfferSuggestion('Say whether an operator is included', ['operator']),
          _OfferSuggestion(
              'Clarify transport arrangements', ['transport', 'delivery']),
          _OfferSuggestion('Mention fuel responsibility', ['fuel']),
          _OfferSuggestion(
              'Confirm availability', ['available', 'availability']),
          _OfferSuggestion(
              'State operating period or hours', ['hours', 'period']),
          _OfferSuggestion(
              'Clarify maintenance responsibility', ['maintenance']),
        ],
      'transport_logistics' => const <_OfferSuggestion>[
          _OfferSuggestion('Specify vehicle type', ['vehicle', 'truck', 'van']),
          _OfferSuggestion(
              'State load or capacity', ['capacity', 'tonne', 'load']),
          _OfferSuggestion('Confirm pickup point', ['pickup', 'pick-up']),
          _OfferSuggestion('Confirm destination', ['destination', 'to ']),
          _OfferSuggestion('Clarify delivery timing', ['delivery', 'deliver']),
          _OfferSuggestion(
              'List what the price includes', ['included', 'includes']),
        ],
      'professional_services' => const <_OfferSuggestion>[
          _OfferSuggestion(
              'Mention relevant experience', ['experience', 'years']),
          _OfferSuggestion(
              'Add relevant qualifications', ['qualification', 'certified']),
          _OfferSuggestion(
              'Define deliverables', ['deliverable', 'report', 'files']),
          _OfferSuggestion('Confirm timeline', ['timeline', 'days', 'weeks']),
          _OfferSuggestion(
              'Clarify what is included', ['included', 'includes']),
          _OfferSuggestion(
              'Reference previous work', ['previous work', 'portfolio']),
        ],
      'specialized_products' => const <_OfferSuggestion>[
          _OfferSuggestion(
              'Specify product or brand', ['product', 'brand', 'model']),
          _OfferSuggestion('State quantity', ['quantity', 'units', 'pieces']),
          _OfferSuggestion(
              'Break out unit price if useful', ['unit price', 'per unit']),
          _OfferSuggestion('Clarify delivery', ['delivery', 'delivered']),
          _OfferSuggestion(
              'Mention condition and availability', ['condition', 'available']),
        ],
      'travel_international' => const <_OfferSuggestion>[
          _OfferSuggestion(
              'Describe the service being provided', ['service', 'assistance']),
          _OfferSuggestion('Specify destination', ['destination', 'travel to']),
          _OfferSuggestion('Clarify timeline', ['timeline', 'days', 'weeks']),
          _OfferSuggestion('List third-party or government fees',
              ['government fee', 'third-party', 'visa fee']),
          _OfferSuggestion('State refund or cancellation conditions',
              ['refund', 'cancellation']),
          _OfferSuggestion(
              'Mention relevant experience', ['experience', 'previous']),
        ],
      _ => const <_OfferSuggestion>[
          _OfferSuggestion(
              'Clarify what is included', ['included', 'includes']),
          _OfferSuggestion(
              'Mention relevant experience', ['experience', 'previous']),
          _OfferSuggestion(
              'Confirm availability and timeline', ['available', 'timeline']),
        ],
    };
    return [...category, ...common];
  }

  Widget _offerPreviewSection(
    String label,
    String value, {
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _assistantRow(bool complete, String text) {
    return _AssistantCheck(complete: complete, text: text);
  }

  Future<void> _promptCapabilityDeclaration(NeedsListing need) async {
    final l10n = AppLocalizations.of(context);
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          l10n?.declareCapabilityToBidTitle ?? 'Service Capability Required',
        ),
        content: Text(
          l10n?.declareCapabilityToBidMessage ??
              'To submit an offer on this request, you must first declare that you offer services in this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l10n?.declareServiceNow ?? 'Add Service & Continue'),
          ),
        ],
      ),
    );

    if (shouldAdd == true && mounted) {
      final provRepo = getIt<IProviderRepository>();
      final existing = await provRepo.getProviderCapabilities();
      if (!mounted) return;
      final existingSlugs = existing.map((c) => c.capabilitySlug).toSet();
      final selection = await AddServiceSheet.show(
        context,
        existingSlugs: existingSlugs,
        preselectedCategorySlug: need.categorySlug,
        needsRepository: getIt<NeedsRepository>(),
      );
      if (selection != null && selection.slugs.isNotEmpty && mounted) {
        await provRepo.addCapabilities(
          selection.slugs,
          metadataBySlug: selection.metadataBySlug,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.servicesCount(selection.slugs.length) ?? 'Services added',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          unawaited(_showMakeOfferSheet(need));
        }
      }
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

    if (confirm != true || !mounted) return;
    if (!await ensureOnlineForAction(context) || !mounted) return;

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
    if (!await ensureOnlineForAction(context)) return;
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

    final detailSurface =
        isDark ? AppColors.bg2Dark : theme.colorScheme.surfaceContainerHighest;

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
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
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
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(need.categoryIcon,
                                  style: const TextStyle(fontSize: 13)),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
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
                ..._offers.asMap().entries.map(
                      (entry) => _OfferCard(
                        offer: entry.value,
                        index: entry.key + 1,
                        capabilityName: need.capabilitySlug != null
                            ? _formatKey(need.capabilitySlug!)
                            : null,
                        onAccept: _actionInProgress
                            ? null
                            : () => _acceptOffer(entry.value.id),
                        onUnlock: _actionInProgress
                            ? null
                            : () => _unlockContact(entry.value.id),
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
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _budget(NeedsListing need) => need.budget > 0
      ? '${need.currency} ${NumberFormat.decimalPattern().format(need.budget)}'
      : 'Open to suitable proposals';
}

class _OfferSuggestion {
  const _OfferSuggestion(this.label, this.keywords);

  final String label;
  final List<String> keywords;
}

class _NeedsOfferSheetLifetime extends StatefulWidget {
  const _NeedsOfferSheetLifetime({
    required this.controllers,
    required this.child,
  });

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_NeedsOfferSheetLifetime> createState() =>
      _NeedsOfferSheetLifetimeState();
}

class _NeedsOfferSheetLifetimeState extends State<_NeedsOfferSheetLifetime> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AssistantCheck extends StatelessWidget {
  const _AssistantCheck({
    required this.complete,
    required this.text,
  });

  final bool complete;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          complete ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 16,
          color: complete
              ? AppColors.success
              : (isDark ? AppColors.text3Dark : AppColors.text3Light),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: complete
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantNote extends StatelessWidget {
  const _AssistantNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.index,
    this.capabilityName,
    this.onAccept,
    this.onUnlock,
  });

  final NeedOffer offer;
  final int index;
  final String? capabilityName;
  final VoidCallback? onAccept;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAccepted = offer.status == 'accepted';
    final isOwn = offer.isOwnOffer;

    final offerTitle = isOwn ? 'Your Offer (#$index)' : 'Offer #$index';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAccepted
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark
                ? AppColors.bg2Dark
                : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? AppColors.success
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isAccepted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Offer Anonymous Header ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    offerTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOwn ? AppColors.accent : null,
                    ),
                  ),
                  if (isAccepted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Accepted',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${offer.currency} ${NumberFormat.decimalPattern().format(offer.price)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Non-identifying Trust Indicators Row ────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (offer.providerRatingAvg != null &&
                  offer.providerRatingAvg! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      offer.providerRatingAvg!.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    if (offer.providerReviewCount > 0)
                      Text(
                        ' (${offer.providerReviewCount})',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              if (offer.providerCompletedDeals > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handshake_outlined,
                        size: 13, color: AppColors.accent),
                    const SizedBox(width: 3),
                    Text(
                      '${offer.providerCompletedDeals} completed',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              if (offer.providerPhoneVerified)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 2),
                    const Text(
                      'Phone verified',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (offer.isProviderVerified
                          ? AppColors.accent
                          : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      offer.isProviderVerified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 11,
                      color: offer.isProviderVerified
                          ? AppColors.accent
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      offer.isProviderVerified
                          ? (capabilityName != null
                              ? '$capabilityName · Provider Verified'
                              : 'Provider Verified')
                          : (capabilityName != null
                              ? '$capabilityName · Self-declared'
                              : 'Self-declared'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: offer.isProviderVerified
                            ? AppColors.accent
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (offer.timelineText.isNotEmpty) ...[
            const SizedBox(height: 6),
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
          if (offer.id.isNotEmpty &&
              offer.status == 'pending' &&
              onAccept != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
