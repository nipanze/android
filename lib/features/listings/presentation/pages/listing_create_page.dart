// lib/features/listings/presentation/pages/listing_create_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/form_suggestion_strip.dart';
import '../../../../shared/widgets/kyc_gate_screen.dart';
import '../../../../shared/widgets/post_duration_info_card.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/data/system_settings_repository.dart';
import '../../data/listing_repository.dart';
import '../../../needs/data/need_draft_exit_guard.dart';
import '../../../needs/data/need_draft_store.dart';
import '../../domain/models/borrower_information.dart';
import '../../domain/models/my_listing.dart';
import '../../domain/models/repayment_calculator.dart';
import '../widgets/listing_create_widgets.dart';

// ─── Purpose options ──────────────────────────────────────────────────────────
const _purposes = [
  'Agricultural equipment',
  'Business expansion',
  'Education / School fees',
  'Emergency medical',
  'Greenhouse / Farming',
  'Home improvement',
  'Inventory / Stock',
  'Land purchase',
  'Livestock',
  'Solar / Energy',
  'Transport / Vehicle',
  'Water & Sanitation',
  'Wedding / Event',
  'Other',
];

const _employmentStatuses = [
  ('government_employed', 'Government employed'),
  ('private_sector', 'Private sector'),
  ('self_employed', 'Self-employed'),
  ('business_owner', 'Business owner'),
  ('student', 'Student'),
  ('retired', 'Retired'),
  ('unemployed', 'Unemployed'),
];

const _monthlyIncomeRanges = [
  'no_regular_income',
  'under_500k',
  '500k_1m',
  '1m_2m',
  '2m_3m',
  'over_3m',
];

const _repaymentPlans = [
  {'value': 'monthly', 'label': 'Monthly'},
  {'value': 'weekly', 'label': 'Weekly'},
  {'value': 'daily', 'label': 'Daily'},
  {'value': 'one_time', 'label': 'One-time payment'},
];

const _dailyDueDayOptions = ['Every day'];

const _monthlyDueDayOptions = [
  '1st of every month',
  '5th of every month',
  '10th of every month',
  '15th of every month',
  '20th of every month',
  '25th of every month',
  'Last day of every month',
  'Custom day',
];

const _weeklyDueDayOptions = [
  'Every Monday',
  'Every Wednesday',
  'Every Friday',
  'Every Sunday',
  'Custom day',
];

const _oneTimeDueDayOptions = [
  'Maturity date / End of term',
  '1st of target month',
  '15th of target month',
  'Custom day',
];

const _dueTimeOptions = [
  '5:00 PM (End of business day)',
  '12:00 PM (Noon)',
  '8:00 PM (Evening)',
  '11:59 PM (End of day)',
  'Custom time',
];

const _descriptionPromptPool = [
  'I need this loan for [purpose]. It will help me [expected outcome], and I will repay from [income source].',
  'I am requesting funds to [specific need]. This will allow me to [goal]. My repayments will come from [income source].',
  'The loan will support [project or expense]. I expect it to [benefit], and I plan to repay using [income source].',
  'I plan to use the funds for [purpose]. This matters because [reason], and I can repay from [income source].',
  'I am seeking financing for [item or activity]. It should help me [result]. I will make repayments from [income source].',
  'These funds will help me [goal]. I will spend them on [purpose] and repay with income from [income source].',
  'I need support with [expense or project]. The funds will be used to [plan], with repayments made from [income source].',
  'This loan will help me [plan or opportunity]. I expect [result], and my repayment source will be [income source].',
  'I am applying for a loan to [purpose]. It will make it possible to [specific result], and I will repay from [income source].',
  'I would use these funds to [activity]. This should improve [part of my life or business], and I will repay with [income source].',
  'The money will go toward [item or cost]. It will help me [goal], and I expect to make repayments from [income source].',
  'I need [amount or support] to [purpose]. This will help me [expected change], and my repayments will come from [income source].',
  'I plan to invest the loan in [project]. I expect [benefit], and I will use income from [source] to repay it.',
  'This request will cover [expense]. Paying for it will help me [goal], and I plan to repay from [income source].',
  'I am seeking a loan for [need]. The funds will be used for [plan], with repayment supported by [income source].',
  'The loan will help me take the next step with [business or personal goal]. I will use the funds for [purpose] and repay from [income source].',
  'I need financing to [action]. This is expected to [outcome], and I can make repayments using [income source].',
  'I would like to borrow for [purpose] so I can [expected outcome]. I plan to repay the loan through [income source].',
  'These funds will cover [specific cost] and help me [goal]. My repayment plan is based on income from [income source].',
  'I am requesting support for [purpose]. With this loan, I can [next step] and repay from [income source].',
  'The funds will help me purchase [item]. This will allow me to [benefit], and I will repay using [income source].',
  'I need a loan to manage [expense]. It will help me [goal], and I plan to make payments from [income source].',
  'I want to use the loan for [project]. I expect it to [outcome], and my repayments will come from [income source].',
  'This loan will cover [need] and help me [result]. I will repay it with income from [source].',
  'I am seeking funds to expand [business or activity]. The expansion should [benefit], and I will repay from [income source].',
  'I plan to pay for [purpose] with this loan. It will help me [goal], and I can repay through [income source].',
  'The loan will support [important expense]. I expect this to help me [outcome], with repayments from [income source].',
  'I need funds for [specific purpose] so I can [planned action]. I will make repayments using [income source].',
  'I would use the loan to improve [business, home, or activity]. This should [expected result], and I will repay from [income source].',
  'This request is for [purpose]. The funds will help me reach [goal], and repayment will come from [income source].',
  'I am borrowing to meet [need]. This will help me [benefit], and I plan to repay the loan from [income source].',
  'The loan will help cover [cost] while I [plan]. I expect to repay it using income from [income source].',
  'I need financing for [activity or item]. It will help me [specific outcome], and I will repay through [income source].',
  'I plan to use this loan to [action]. This will support [goal], and my repayments will be funded by [income source].',
  'The funds will be used for [purpose] to help me [expected benefit]. I will repay from [income source].',
  'I am applying so I can afford [expense or item]. This will help me [goal], and I will repay with [income source].',
  'This loan will let me [planned action] for [purpose]. I expect [result] and will repay from [income source].',
  'I am requesting a loan for [project or expense]. It should help me [benefit], and I can repay from [income source].',
  'I need funds to continue [activity]. The loan will help me [goal], with repayments coming from [income source].',
  'I will use the loan to address [need]. This should make it easier to [outcome], and I plan to repay from [income source].',
  'The money will support [purpose] and help me achieve [goal]. My repayment source will be [income source].',
  'I am seeking financing to [planned action]. It will help me [expected result], and I will repay using [income source].',
  'This loan will help with [expense] so I can focus on [goal]. I plan to repay from [income source].',
  'I want to invest in [item or project]. It should help me [benefit], and I will use [income source] for repayments.',
  'The purpose of this request is [purpose]. The funds will enable me to [action], and I will repay from [income source].',
  'I need help funding [specific need]. This will allow me to [goal], and I expect to repay through [income source].',
  'I am requesting a loan to [purpose]. I believe it will [expected benefit], and I will make repayments from [income source].',
  'The loan will help me prepare for [event or expense]. I will use it to [plan] and repay from [income source].',
  'I need this loan to [purpose] at this time because [reason]. I plan to repay it from [income source].',
  'These funds will help me move forward with [goal]. I will use them for [purpose] and repay from [income source].',
];

class ListingCreatePage extends StatefulWidget {
  const ListingCreatePage({super.key, this.draftId});

  final String? draftId;
  @override
  State<ListingCreatePage> createState() => _ListingCreatePageState();
}

class _ListingCreatePageState extends State<ListingCreatePage>
    with WidgetsBindingObserver {
  final _descriptionPromptSuggestions = _descriptionPromptPool.toList()
    ..shuffle();
  final _pageController = PageController();
  int _step = 0;
  bool _descriptionIsAutoGenerated = false;
  String? _draftId;
  bool _allowExit = false;
  bool _savingDraft = false;
  bool _draftLoading = false;
  Timer? _draftSaveTimer;
  int _draftRevision = 0;

  // Step 1 fields
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customPurposeController = TextEditingController();
  final _collateralDetailsController = TextEditingController();
  final _collateralValueController = TextEditingController();
  final _collateralLocationController = TextEditingController();
  String? _selectedPurpose;
  String? _customPurpose;
  String? _district;
  bool _hasCollateral = false;

  // Step 2 fields
  final _incomeSourceController = TextEditingController();
  final _repaymentAmountController = TextEditingController();
  final _repaymentTimelineController = TextEditingController();
  final _suggestedInterestController = TextEditingController();
  final _suggestedLateFeeController = TextEditingController();
  final _suggestedInstallmentController = TextEditingController();
  String? _preferredRepaymentPlan;
  String? _suggestedRepaymentPlan;
  String? _selectedDueDay;
  String? _selectedDueTime;

  // Step 3: reusable borrower information, requested only in the Loan flow.
  final _employerBusinessNameController = TextEditingController();
  final _otherIncomeSourceController = TextEditingController();
  final _preferredBankController = TextEditingController();
  final _borrowerInformationFormKey = GlobalKey<FormState>();
  String? _employmentStatus;
  String? _monthlyIncomeRange;
  String? _incomeRangeCurrency;
  BorrowerInformation? _savedBorrowerInformation;
  bool _borrowerInformationLoading = true;
  String? _borrowerInformationLoadError;

  void _updateRepaymentTimeline() {
    final parts = <String>[];

    if (_selectedDueDay != null && _selectedDueDay != 'Custom day') {
      if (_preferredRepaymentPlan == 'weekly') {
        parts.add('Paid $_selectedDueDay');
      } else if (_preferredRepaymentPlan == 'daily') {
        parts.add('Paid every day');
      } else if (_preferredRepaymentPlan == 'one_time') {
        parts.add('Paid on $_selectedDueDay');
      } else {
        parts.add('Paid by the $_selectedDueDay');
      }
    }

    if (_selectedDueTime != null && _selectedDueTime != 'Custom time') {
      final cleanTime = _selectedDueTime!.split(' (').first;
      parts.add('by $cleanTime');
    }

    final durationMonths = int.tryParse(_durationController.text) ?? 0;
    if (durationMonths > 0) {
      parts.add('for $durationMonths months');
    }

    if (parts.isNotEmpty) {
      _repaymentTimelineController.text = parts.join(' ');
    }
  }

  final _loanDetailsFormKey = GlobalKey<FormState>();
  final _repaymentFormKey = GlobalKey<FormState>();

  bool _submitting = false;
  PlatformLimits _limits = PlatformLimits.defaults;
  List<MyListing> _recentRequests = const [];
  String? _recentRequestsLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftId = widget.draftId;
    _draftLoading = _draftId != null;
    NeedDraftExitGuard.register(
      this,
      hasChanges: () => _hasDraftContent,
      saveDraft: _saveLoanDraft,
    );
    for (final controller in [
      _titleController,
      _amountController,
      _durationController,
      _descriptionController,
      _customPurposeController,
      _collateralDetailsController,
      _collateralValueController,
      _collateralLocationController,
      _incomeSourceController,
      _repaymentAmountController,
      _repaymentTimelineController,
      _suggestedInterestController,
      _suggestedLateFeeController,
      _suggestedInstallmentController,
      _employerBusinessNameController,
      _otherIncomeSourceController,
      _preferredBankController,
    ]) {
      controller.addListener(_refreshButtonState);
    }
    _loadLimits();
    _loadBorrowerInformation();
    _loadRecentRequests();
    if (_draftId != null) _loadLoanDraft();
  }

  Future<void> _loadRecentRequests() async {
    try {
      final requests =
          await getIt<ListingRepository>().getMyListings(limit: 12);
      if (!mounted) return;
      setState(() {
        _recentRequests = requests;
        _recentRequestsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentRequestsLoadError = parseSupabaseError(e).message;
      });
    }
  }

  bool get _hasDraftContent =>
      _draftId != null ||
      _selectedPurpose != null ||
      _titleController.text.trim().isNotEmpty ||
      _amountController.text.trim().isNotEmpty ||
      _durationController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _customPurposeController.text.trim().isNotEmpty ||
      _collateralDetailsController.text.trim().isNotEmpty ||
      _collateralValueController.text.trim().isNotEmpty ||
      _collateralLocationController.text.trim().isNotEmpty ||
      _incomeSourceController.text.trim().isNotEmpty ||
      _repaymentAmountController.text.trim().isNotEmpty ||
      _employmentStatus != null ||
      _employerBusinessNameController.text.trim().isNotEmpty ||
      _otherIncomeSourceController.text.trim().isNotEmpty ||
      _preferredBankController.text.trim().isNotEmpty;

  void _scheduleDraftSave() {
    if (!mounted || _draftLoading || _submitting || !_hasDraftContent) return;
    _draftRevision++;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 250), _autoSaveDraft);
  }

  Future<void> _autoSaveDraft() async {
    if (!mounted || _draftLoading || !_hasDraftContent) return;
    if (_savingDraft) {
      _draftSaveTimer = Timer(const Duration(milliseconds: 250), _autoSaveDraft);
      return;
    }
    final revision = _draftRevision;
    final saved = await _saveLoanDraft();
    if (saved && mounted && revision != _draftRevision) {
      _scheduleDraftSave();
    }
  }

  Future<void> _loadLoanDraft() async {
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is! AuthAuthenticated || _draftId == null) return;
      final draft = await NeedDraftStore.find(auth.user.id, _draftId!);
      if (!mounted || draft == null || draft['kind'] != 'loan_request') return;

      setState(() {
      _titleController.text = draft['request_title']?.toString() ?? '';
      final savedPurpose = draft['purpose']?.toString();
      _selectedPurpose = _purposes.contains(savedPurpose) ? savedPurpose : null;
      _customPurpose = draft['custom_purpose']?.toString();
      _customPurposeController.text = _customPurpose ?? '';
      _amountController.text = draft['amount']?.toString() ?? '';
      _durationController.text = draft['duration']?.toString() ?? '';
      _descriptionController.text = draft['description']?.toString() ?? '';
      _descriptionIsAutoGenerated = false;
      _district = draft['district']?.toString();
      _hasCollateral = draft['has_collateral'] == true;
      _collateralDetailsController.text =
          draft['collateral_details']?.toString() ?? '';
      _collateralValueController.text =
          draft['collateral_value']?.toString() ?? '';
      _collateralLocationController.text =
          draft['collateral_location']?.toString() ?? '';
      _incomeSourceController.text = draft['income_source']?.toString() ?? '';
      _repaymentAmountController.text =
          draft['repayment_amount']?.toString() ?? '';
      _repaymentTimelineController.text =
          draft['repayment_timeline']?.toString() ?? '';
      _preferredRepaymentPlan = draft['repayment_plan']?.toString();
      _suggestedInterestController.text =
          draft['suggested_interest']?.toString() ?? '';
      _suggestedLateFeeController.text =
          draft['suggested_late_fee']?.toString() ?? '';
      _suggestedInstallmentController.text =
          draft['suggested_installment']?.toString() ?? '';
      _suggestedRepaymentPlan = draft['suggested_repayment_plan']?.toString();
      _selectedDueDay = draft['due_day']?.toString();
      _selectedDueTime = draft['due_time']?.toString();
      final savedStatus = draft['employment_status']?.toString();
      _employmentStatus = _employmentStatuses.any((s) => s.$1 == savedStatus)
          ? savedStatus
          : null;
      _employerBusinessNameController.text =
          draft['employer']?.toString() ?? '';
      _monthlyIncomeRange = draft['monthly_income_range']?.toString();
      _incomeRangeCurrency = draft['income_currency']?.toString();
      _otherIncomeSourceController.text =
          draft['other_income_source']?.toString() ?? '';
      _preferredBankController.text = draft['preferred_bank']?.toString() ?? '';
      final savedStep = draft['step'] as int? ?? 0;
      _step = savedStep < 0 ? 0 : savedStep > 3 ? 3 : savedStep;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pageController.jumpToPage(_step);
      });
    } catch (_) {
      // An unreadable draft should not block starting a new request.
    } finally {
      _draftLoading = false;
    }
  }

  Future<bool> _saveLoanDraft() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || !_hasDraftContent || _savingDraft) {
      return false;
    }
    _draftSaveTimer?.cancel();
    setState(() => _savingDraft = true);
    try {
      final draft = await NeedDraftStore.save(
        auth.user.id,
        {
          'kind': 'loan_request',
          'category_slug': 'loan_request',
          'title': _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : _purposeValue.trim().isEmpty
                  ? 'Loan request draft'
                  : '${_getLocalizedPurpose(_purposeValue)} loan',
          'step': _step,
          'request_title': _titleController.text,
          'purpose': _selectedPurpose,
          'custom_purpose': _customPurpose,
          'amount': _amountController.text,
          'duration': _durationController.text,
          'description': _descriptionController.text,
          'district': _district,
          'has_collateral': _hasCollateral,
          'collateral_details': _collateralDetailsController.text,
          'collateral_value': _collateralValueController.text,
          'collateral_location': _collateralLocationController.text,
          'income_source': _incomeSourceController.text,
          'repayment_amount': _repaymentAmountController.text,
          'repayment_timeline': _repaymentTimelineController.text,
          'repayment_plan': _preferredRepaymentPlan,
          'suggested_interest': _suggestedInterestController.text,
          'suggested_late_fee': _suggestedLateFeeController.text,
          'suggested_installment': _suggestedInstallmentController.text,
          'suggested_repayment_plan': _suggestedRepaymentPlan,
          'due_day': _selectedDueDay,
          'due_time': _selectedDueTime,
          'employment_status': _employmentStatus,
          'employer': _employerBusinessNameController.text,
          'monthly_income_range': _monthlyIncomeRange,
          'income_currency': _incomeRangeCurrency,
          'other_income_source': _otherIncomeSourceController.text,
          'preferred_bank': _preferredBankController.text,
        },
        id: _draftId,
      );
      _draftId = draft['draft_id']?.toString();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _confirmLoanExit() async {
    if (!await NeedDraftExitGuard.confirmExit(context) || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.needsCreate);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _draftSaveTimer?.cancel();
      unawaited(_saveLoanDraft());
    }
  }

  List<String> _recentValues(String Function(MyListing) select) {
    final values = <String>[];
    final seen = <String>{};
    for (final request in _recentRequests) {
      final value = select(request).trim();
      if (value.isNotEmpty && seen.add(value)) {
        values.add(value);
        if (values.length == 3) break;
      }
    }
    return values;
  }

  List<String> _uniqueSuggestions(Iterable<String> suggestions) => suggestions
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _loadBorrowerInformation() async {
    try {
      final information =
          await getIt<ListingRepository>().getBorrowerInformation();
      if (!mounted) return;
      _savedBorrowerInformation = information;
      if (information != null && widget.draftId == null) {
        _applyBorrowerInformation(information);
      }
      setState(() {
        _borrowerInformationLoading = false;
        _borrowerInformationLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _borrowerInformationLoading = false;
        _borrowerInformationLoadError = parseSupabaseError(e).message;
      });
    }
  }

  void _applyBorrowerInformation(BorrowerInformation information) {
    _employmentStatus = _employmentStatuses
            .any((status) => status.$1 == information.employmentStatus)
        ? information.employmentStatus
        : null;
    _employerBusinessNameController.text =
        information.employerBusinessName ?? '';
    _monthlyIncomeRange = information.monthlyIncomeRange;
    _incomeRangeCurrency = information.incomeCurrency;
    _otherIncomeSourceController.text = information.otherIncomeSource ?? '';
    _preferredBankController.text = information.preferredBank ?? '';
  }

  void _useSavedBorrowerInformation() {
    final information = _savedBorrowerInformation;
    if (information == null) return;
    _applyBorrowerInformation(information);
    setState(() {});
  }

  Future<void> _retryBorrowerInformationLoad() async {
    setState(() {
      _borrowerInformationLoading = true;
      _borrowerInformationLoadError = null;
    });
    await _loadBorrowerInformation();
  }

  BorrowerInformation get _borrowerInformation => BorrowerInformation(
        employmentStatus: _employmentStatus!,
        employerBusinessName: _employerBusinessNameController.text,
        isGovernmentEmployee: _employmentStatus == 'government_employed',
        monthlyIncomeRange: _monthlyIncomeRange!,
        incomeCurrency: _incomeRangeCurrency ?? _currencyCode,
        otherIncomeSource: _otherIncomeSourceController.text,
        preferredBank: _preferredBankController.text,
      );

  bool get _borrowerInformationReady {
    final status = _employmentStatus;
    final requiresEmployer = status == 'government_employed' ||
        status == 'private_sector' ||
        status == 'self_employed' ||
        status == 'business_owner';
    return !_borrowerInformationLoading &&
        status != null &&
        _monthlyIncomeRange != null &&
        (!requiresEmployer ||
            _employerBusinessNameController.text.trim().isNotEmpty);
  }

  bool get _borrowerInformationValid {
    final formValid = _borrowerInformationFormKey.currentState?.validate() ??
        _borrowerInformationReady;
    return formValid && _borrowerInformationReady;
  }

  Future<void> _loadLimits() async {
    final limits = await getIt<SystemSettingsRepository>().getLimits();
    if (mounted) {
      setState(() {
        _limits = limits;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NeedDraftExitGuard.unregister(this);
    _draftSaveTimer?.cancel();
    for (final controller in [
      _titleController,
      _amountController,
      _durationController,
      _descriptionController,
      _customPurposeController,
      _collateralDetailsController,
      _collateralValueController,
      _collateralLocationController,
      _incomeSourceController,
      _repaymentAmountController,
      _repaymentTimelineController,
      _suggestedInterestController,
      _suggestedLateFeeController,
      _suggestedInstallmentController,
      _employerBusinessNameController,
      _otherIncomeSourceController,
      _preferredBankController,
    ]) {
      controller.removeListener(_refreshButtonState);
    }
    _pageController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _customPurposeController.dispose();
    _collateralDetailsController.dispose();
    _collateralValueController.dispose();
    _collateralLocationController.dispose();
    _incomeSourceController.dispose();
    _repaymentAmountController.dispose();
    _repaymentTimelineController.dispose();
    _employerBusinessNameController.dispose();
    _otherIncomeSourceController.dispose();
    _preferredBankController.dispose();
    _suggestedInterestController.dispose();
    _suggestedLateFeeController.dispose();
    _suggestedInstallmentController.dispose();
    super.dispose();
  }

  void _refreshButtonState() {
    if (!mounted) return;
    setState(() {});
    _scheduleDraftSave();
  }

  bool get _loanDetailsReady {
    final amount = int.tryParse(_amountController.text);
    final duration = int.tryParse(_durationController.text);
    final purposeReady = _selectedPurpose != null &&
        (_selectedPurpose != 'Other' ||
            ((_customPurpose?.trim().isNotEmpty ?? false) &&
                _titleController.text.trim().length >= 4));
    final collateralReady =
        !_hasCollateral || _collateralDetailsController.text.trim().isNotEmpty;
    final locationReady = _district?.trim().isNotEmpty ?? false;
    return amount != null &&
        amount > 0 &&
        duration != null &&
        duration > 0 &&
        purposeReady &&
        collateralReady &&
        locationReady;
  }

  bool get _repaymentReady {
    final amount = int.tryParse(_repaymentAmountController.text);
    return _incomeSourceController.text.trim().isNotEmpty &&
        _preferredRepaymentPlan != null &&
        amount != null &&
        amount > 0 &&
        _selectedDueDay != null &&
        _selectedDueTime != null &&
        _repaymentTimelineController.text.trim().length >= 10;
  }

  bool get _currentStepReady => switch (_step) {
        0 => _loanDetailsReady,
        1 => _repaymentReady,
        2 => _borrowerInformationReady,
        _ => _loanDetailsReady && _repaymentReady && _borrowerInformationReady,
      };

  String get _purposeValue => _selectedPurpose == 'Other'
      ? (_customPurpose ?? '')
      : (_selectedPurpose ?? '');

  int? get _suggestedPrincipalInstallment =>
      RepaymentCalculator.principalInstallment(
        principal: int.tryParse(_amountController.text) ?? 0,
        durationMonths: int.tryParse(_durationController.text) ?? 0,
        repaymentPlan: _preferredRepaymentPlan,
      );

  int? get _monthlyPrincipalEstimate =>
      RepaymentCalculator.principalInstallment(
        principal: int.tryParse(_amountController.text) ?? 0,
        durationMonths: int.tryParse(_durationController.text) ?? 0,
        repaymentPlan: 'monthly',
      );

  List<int> get _quickLoanAmounts {
    final minimum = _limits.minLoanAmount;
    final maximum = _limits.maxLoanAmount;
    if (minimum <= 0 || maximum < minimum) return const [];
    return {
      minimum,
      (minimum > maximum ~/ 5 ? maximum : minimum * 5),
      (minimum > maximum ~/ 10 ? maximum : minimum * 10),
    }.toList()
      ..sort();
  }

  void _applySuggestedInstallment() {
    final suggestion = _suggestedPrincipalInstallment;
    if (suggestion != null) {
      _repaymentAmountController.text = suggestion.toString();
    }
  }

  bool get _loanDetailsValid {
    // currentState may be null when PageView has disposed the page (step 3 view).
    // Fall back to the field-level readiness check so validation still works.
    final formValid =
        _loanDetailsFormKey.currentState?.validate() ?? _loanDetailsReady;
    if (!formValid) return false;
    if (_selectedPurpose == null) return false;
    if (_selectedPurpose == 'Other' &&
        (_customPurpose == null || _customPurpose!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  bool get _repaymentValid {
    // Same null-safe guard as _loanDetailsValid above.
    final formValid =
        _repaymentFormKey.currentState?.validate() ?? _repaymentReady;
    if (!formValid) return false;
    if (_preferredRepaymentPlan == null) return false;
    if (_selectedDueDay == null) return false;
    if (_selectedDueTime == null) return false;
    return true;
  }

  void _next() {
    final l10n = AppLocalizations.of(context);
    if (_step == 0 && !_loanDetailsValid) {
      _loanDetailsFormKey.currentState?.validate();
      if (_selectedPurpose == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.validationPurposeContinue ??
                  'Select a purpose to continue.',
            ),
          ),
        );
      }
      return;
    }
    if (_step == 1 && !_repaymentValid) {
      _repaymentFormKey.currentState?.validate();
      if (_preferredRepaymentPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.validationRepaymentPlanContinue ??
                  'Select a repayment plan to continue.',
            ),
          ),
        );
      }
      return;
    }
    if (_step == 2 && !_borrowerInformationValid) {
      _borrowerInformationFormKey.currentState?.validate();
      return;
    }
    if (_step >= 3) return;
    setState(() => _step += 1);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Affordability gate: mirrors MakeOfferSheet's _showLossWarningDialog ──
  Future<bool> _showAffordabilityDialog() async {
    final l10n = AppLocalizations.of(context);
    final currency = _currencyCode;
    final principal = int.tryParse(_amountController.text) ?? 0;
    final installment = int.tryParse(_repaymentAmountController.text) ?? 0;
    final periods = _preferredRepaymentPlan == null
        ? 0
        : RepaymentCalculator.paymentCount(
            durationMonths: int.tryParse(_durationController.text) ?? 0,
            repaymentPlan: _preferredRepaymentPlan!,
          );
    final totalRepayment = installment * periods;

    if (principal <= 0 || totalRepayment >= principal) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 34,
        ),
        title: Text(l10n?.affordabilityDialogTitle ?? 'Publish anyway?'),
        content: Text(
          l10n?.affordabilityDialogBody ??
              'Your repayment terms appear lower than what most Providers will accept. '
                  'Total repayment of $currency ${fmtAmount(totalRepayment)} is below your requested $currency ${fmtAmount(principal)}. '
                  'You can still publish, but you may not receive offers. Consider adjusting your installment amount.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.btnBack ?? 'Go back & adjust'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.btnPublishToMarketplace ?? 'Publish anyway'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    if (!await ensureOnlineForAction(context) || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!_loanDetailsValid || !_repaymentValid || !_borrowerInformationValid) {
      _loanDetailsFormKey.currentState?.validate();
      _repaymentFormKey.currentState?.validate();
      _borrowerInformationFormKey.currentState?.validate();
      if (!mounted) return;

      if (!_loanDetailsValid) {
        _pageController.jumpToPage(0);
        setState(() => _step = 0);
        _showGate(
          l10n?.validationPurposeContinue ??
              'Please fix your loan details before publishing.',
        );
      } else if (!_repaymentValid) {
        _pageController.jumpToPage(1);
        setState(() => _step = 1);
        _showGate(
          l10n?.validationRepaymentPlanContinue ??
              'Please fix your repayment details before publishing.',
        );
      } else if (!_borrowerInformationValid) {
        _pageController.jumpToPage(2);
        setState(() => _step = 2);
        _showGate(
          'Please complete your employment and income information.',
        );
      }
      return;
    }

    // ── Affordability gate ────────────────────────────────────────────────────
    if (!await _showAffordabilityDialog()) return;
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (!authState.user.kycApproved) {
      _showGate(
        l10n?.kycGateListing ??
            'Complete KYC verification before posting a listing.',
      );
      return;
    }
    if (!authState.user.canBorrow) {
      _showGate(
        l10n?.notAllowedListing ??
            'Your account is not allowed to post a listing.',
      );
      return;
    }

    final canSuggestTerms = authState.user.canSuggestBorrowerTerms;
    final collateralDetails = _collateralDetailsController.text.trim();
    final collateralLocation = _collateralLocationController.text.trim();
    _draftSaveTimer?.cancel();
    setState(() => _submitting = true);
    try {
      final listingRepository = getIt<ListingRepository>();
      await listingRepository.saveBorrowerInformation(_borrowerInformation);
      await listingRepository.createListing(
        title: _listingTitle,
        purpose: _purposeValue.trim(),
        requestedAmount: int.parse(_amountController.text),
        durationMonths: int.parse(_durationController.text),
        district: _selectedRegion,
        description: _descriptionController.text,
        incomeSource: _incomeSourceController.text.trim(),
        preferredRepaymentPlan: _preferredRepaymentPlan!,
        repaymentAmountPerPeriod: int.parse(_repaymentAmountController.text),
        repaymentTimeline: _repaymentTimelineController.text.trim(),
        suggestedInterestRatePct: canSuggestTerms
            ? double.tryParse(_suggestedInterestController.text)
            : null,
        suggestedLateFeePct: canSuggestTerms
            ? double.tryParse(_suggestedLateFeeController.text)
            : null,
        suggestedRepaymentFrequency:
            canSuggestTerms ? _suggestedRepaymentPlan : null,
        suggestedInstallmentAmount: canSuggestTerms
            ? int.tryParse(_suggestedInstallmentController.text)
            : null,
        hasCollateral: _hasCollateral,
        collateralDetails: _hasCollateral ? collateralDetails : null,
        collateralEstimatedValue: _hasCollateral
            ? int.tryParse(_collateralValueController.text)
            : null,
        collateralLocation: _hasCollateral && collateralLocation.isNotEmpty
            ? collateralLocation
            : null,
        country: authState.user.country,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _scheduleDraftSave();
      _showGate(
        e is AppException
            ? e.message
            : (l10n?.couldNotPublishRequest ??
                'Could not publish this request. Try again.'),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (_draftId != null) {
      try {
        await NeedDraftStore.delete(authState.user.id, _draftId!);
      } catch (_) {
        // Publishing succeeded; a stale local draft can be removed later.
      }
      _draftId = null;
    }

    // Take the user directly to their requests so the newly published item is
    // visible immediately, without an extra confirmation step.
    if (mounted) context.go(AppRoutes.myListings);
  }

  void _showGate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // ── KYC / eligibility gate ─────────────────────────────────────────────
    // Check before rendering the form so users are never blocked mid-flow.
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (!authState.user.kycApproved) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n?.requestALoan ?? 'Request a loan',
        );
      }
      if (!authState.user.canBorrow) {
        return KycGateScreen(
          kycStatus: authState.user.kycStatus,
          pageTitle: l10n?.requestALoan ?? 'Request a loan',
          reason: l10n?.notAllowedListing ??
              'Your account is not eligible to post a listing.',
        );
      }
    }
    // ── Normal multi-step form ─────────────────────────────────────────────

    return PopScope<Object?>(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLoanExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ListingStepHeader(
                title: l10n?.requestALoan ?? 'Request a loan',
                subtitle: l10n?.stepCounter(
                      _step + 1,
                      4,
                      _subtitleForStep(),
                    ) ??
                    'Step ${_step + 1} of 4 · ${_subtitleForStep()}',
                progress: (_step + 1) / 4,
                onBack: _step > 0 ? _back : _confirmLoanExit,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  String get _currencyCode {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return 'UGX';
    if (authState.user.incomeCurrency.isNotEmpty) {
      return authState.user.incomeCurrency;
    }
    return EastAfricaCountries.findByCode(authState.user.country).currency;
  }

  CountryInfo get _countryInfo {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return EastAfricaCountries.defaultCountry;
    }
    return EastAfricaCountries.findByCode(authState.user.country);
  }

  String get _selectedRegion {
    return _district?.trim() ?? '';
  }

  String get _listingTitle => _selectedPurpose == 'Other'
      ? _titleController.text.trim()
      : '${_getLocalizedPurpose(_purposeValue)} loan';

  bool get _descriptionCanBeAutoFilled =>
      _descriptionController.text.trim().isEmpty ||
      _descriptionIsAutoGenerated;

  String _randomPurposeDescription(String purpose) {
    final templates = [
      'I need this loan for {purpose}. It will help me [expected outcome], and I will repay from [income source].',
      'I plan to use the funds for {purpose}. This matters because [reason], and I can repay from [income source].',
      'These funds will support my {purpose}. I will use them to [planned activity] and repay from [income source].',
      'The loan will help me with {purpose}. I expect it to [benefit], and I will repay using [income source].',
      'This request is for {purpose}. The funds will help me [goal], with repayments from [income source].',
      'I am requesting this loan for {purpose}. It will allow me to [next step], and I will repay from [income source].',
    ]..shuffle();
    return templates.first.replaceAll('{purpose}', purpose);
  }

  void _fillDescriptionForPurpose(String purpose) {
    _descriptionController.text = _randomPurposeDescription(purpose);
    _descriptionIsAutoGenerated = true;
  }

  void _selectPurpose(String? purpose) {
    setState(() {
      _selectedPurpose = purpose;
      if (purpose != 'Other') {
        _customPurpose = null;
        _customPurposeController.clear();
      }
      if (purpose != null &&
          purpose != 'Other' &&
          _descriptionCanBeAutoFilled) {
        _fillDescriptionForPurpose(_getLocalizedPurpose(purpose));
      }
    });
    _scheduleDraftSave();
  }

  String _subtitleForStep() {
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 1:
        return l10n?.subtitleRepaymentContext ?? 'repayment context';
      case 2:
        return 'borrower information';
      case 3:
        return l10n?.subtitleReview ?? 'review';
      default:
        return l10n?.subtitleLoanDetails ?? 'loan details';
    }
  }

  String _getLocalizedPurpose(String purpose) {
    final l10n = AppLocalizations.of(context);
    switch (purpose) {
      case 'Agricultural equipment':
        return l10n?.purposeAgri ?? purpose;
      case 'Business expansion':
        return l10n?.purposeBusiness ?? purpose;
      case 'Education / School fees':
        return l10n?.purposeEdu ?? purpose;
      case 'Emergency medical':
        return l10n?.purposeMedical ?? purpose;
      case 'Greenhouse / Farming':
        return l10n?.purposeFarming ?? purpose;
      case 'Home improvement':
        return l10n?.purposeHome ?? purpose;
      case 'Inventory / Stock':
        return l10n?.purposeStock ?? purpose;
      case 'Land purchase':
        return l10n?.purposeLand ?? purpose;
      case 'Livestock':
        return l10n?.purposeLivestock ?? purpose;
      case 'Solar / Energy':
        return l10n?.purposeEnergy ?? purpose;
      case 'Transport / Vehicle':
        return l10n?.purposeVehicle ?? purpose;
      case 'Water & Sanitation':
        return l10n?.purposeWater ?? purpose;
      case 'Wedding / Event':
        return l10n?.purposeWedding ?? purpose;
      case 'Other':
        return l10n?.purposeOther ?? purpose;
      default:
        return purpose;
    }
  }

  String _getLocalizedRepaymentPlan(String? value) {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'monthly':
        return l10n?.planMonthly ?? 'Monthly';
      case 'weekly':
        return l10n?.planWeekly ?? 'Weekly';
      case 'daily':
        return l10n?.daily ?? 'Daily';
      case 'one_time':
        return l10n?.planOneTime ?? 'One-time payment';
      default:
        return '';
    }
  }

  // ─── Step 1: Loan details ───────────────────────────────────────────────────

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context);
    final currency = _currencyCode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _loanDetailsFormKey,
        onChanged: _scheduleDraftSave,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListingInfoBanner(
            text: l10n?.infoBannerText(
                  currency,
                  fmtAmount(_limits.minLoanAmount),
                  fmtAmount(_limits.maxLoanAmount),
                ) ??
                '$currency ${fmtAmount(_limits.minLoanAmount)}-${fmtAmount(_limits.maxLoanAmount)} · Up to 60 months · terms lock on publish',
          ),
          if (_recentRequestsLoadError != null) ...[
            const SizedBox(height: 6),
            Text(
              'Previous request suggestions unavailable: '
              '$_recentRequestsLoadError',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ListingFormPanel(
            title: l10n?.panelTheBasics ?? 'The basics',
            isComplete: _selectedPurpose != null &&
                (_selectedPurpose != 'Other' ||
                    ((_customPurpose?.trim().isNotEmpty ?? false) &&
                        _titleController.text.trim().length >= 4)),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPurpose,
                decoration: InputDecoration(
                  labelText: l10n?.purposeLabel ?? 'Purpose',
                ),
                hint: Text(l10n?.selectPurposeHint ?? 'Select purpose'),
                items: _purposes
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(_getLocalizedPurpose(p)),
                        ))
                    .toList(),
                onChanged: _selectPurpose,
                validator: (v) => v == null
                    ? (l10n?.validationPurposeRequired ?? 'Select a purpose')
                    : null,
              ),
              FormSuggestionStrip(
                label: 'Recent',
                suggestions: _uniqueSuggestions(
                  _recentValues((request) => request.purpose).isEmpty
                      ? const [
                          'Business expansion',
                          'Education / School fees',
                          'Emergency medical',
                          'Inventory / Stock',
                          'Transport / Vehicle',
                        ]
                      : _recentValues((request) => request.purpose),
                ),
                onSelected: (value) {
                  if (_purposes.contains(value)) {
                    _selectPurpose(value);
                  } else {
                    setState(() {
                      _selectedPurpose = 'Other';
                      _customPurpose = value;
                      _customPurposeController.text = value;
                      if (_descriptionCanBeAutoFilled) {
                        _fillDescriptionForPurpose(value);
                      }
                    });
                  }
                },
              ),
              if (_selectedPurpose == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n?.requestTitleLabel ?? 'Request title',
                    hintText: l10n?.requestTitleHint ??
                        'e.g. Delivery van for Kampala route',
                  ),
                  validator: (value) {
                    if (_selectedPurpose != 'Other') return null;
                    final title = value?.trim() ?? '';
                    if (title.isEmpty) {
                      return l10n?.validationTitleRequired ?? 'Enter a title';
                    }
                    if (title.length < 4) {
                      return l10n?.validationTitleMinLength ??
                          'Use at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customPurposeController,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.describePurposeLabel ?? 'Describe your purpose',
                  ),
                  onChanged: (v) => setState(() {
                    _customPurpose = v;
                    if (v.trim().isNotEmpty && _descriptionCanBeAutoFilled) {
                      _descriptionController.text =
                          _randomPurposeDescription(v.trim());
                    }
                  }),
                  validator: (v) {
                    if (_selectedPurpose == 'Other' &&
                        (v == null || v.trim().isEmpty)) {
                      return l10n?.describePurposeLabel ??
                          'Describe your purpose';
                    }
                    return null;
                  },
                ),
                FormSuggestionStrip(
                  label: 'Previous',
                  suggestions: _recentValues((request) => request.purpose)
                      .where((purpose) => !_purposes.contains(purpose))
                      .toList(),
                  onSelected: (value) => setState(() {
                    _customPurpose = value;
                    _customPurposeController.text = value;
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ListingFormPanel(
            title: l10n?.panelTheNumbers ?? 'The numbers',
            isComplete: (int.tryParse(_amountController.text) ?? 0) >=
                    _limits.minLoanAmount &&
                (int.tryParse(_amountController.text) ?? 0) <=
                    _limits.maxLoanAmount &&
                (int.tryParse(_durationController.text) ?? 0) >= 1 &&
                (int.tryParse(_durationController.text) ?? 0) <= 60,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(currency),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n?.validationAmountRequired ??
                                  'Enter an amount';
                            }
                            final n = int.tryParse(v);
                            if (n == null) {
                              return l10n?.validationValidNumber ??
                                  'Enter a valid number';
                            }
                            if (n < _limits.minLoanAmount) {
                              return l10n?.validationMinAmount(
                                    currency,
                                    fmtAmount(_limits.minLoanAmount),
                                  ) ??
                                  'Minimum $currency ${fmtAmount(_limits.minLoanAmount)}';
                            }
                            if (n > _limits.maxLoanAmount) {
                              return l10n?.validationMaxAmount(
                                    currency,
                                    fmtAmount(_limits.maxLoanAmount),
                                  ) ??
                                  'Maximum $currency ${fmtAmount(_limits.maxLoanAmount)}';
                            }
                            return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.durationLabel ?? 'Duration',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _durationController,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '12',
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n?.validationDurationRequired ??
                                  'Enter duration';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n < 1 || n > 60) {
                              return l10n?.validationDurationRange ??
                                  '1 to 60 months';
                            }
                            return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'months',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormSuggestionStrip(
                      label: '',
                      suggestions: _quickLoanAmounts
                          .take(3)
                          .map((amount) => '$currency ${fmtAmount(amount)}')
                          .toList(),
                      onSelected: (value) => setState(() {
                        _amountController.text =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                      }),
                      selectedValue: _quickLoanAmounts
                              .take(3)
                              .contains(int.tryParse(_amountController.text))
                          ? '$currency ${fmtAmount(int.parse(_amountController.text))}'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormSuggestionStrip(
                      label: '',
                      suggestions: const ['3 months', '6 months', '12 months'],
                      onSelected: (value) => setState(() {
                        _durationController.text =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                      }),
                      selectedValue: [3, 6, 12]
                              .contains(int.tryParse(_durationController.text))
                          ? '${int.parse(_durationController.text)} months'
                          : null,
                    ),
                  ),
                ],
              ),
              if (_monthlyPrincipalEstimate case final estimate?) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Monthly principal-only guide: $currency '
                    '${fmtAmount(estimate)} × '
                    '${int.tryParse(_durationController.text)} months. '
                    'Interest and fees are not included.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ListingFormPanel(
            title: 'Where Do You Work/ Stay?',
            isComplete: (_district?.trim().isNotEmpty ?? false) &&
                (_descriptionController.text.isEmpty ||
                    !RegExp(r'\[[^\]]+\]')
                        .hasMatch(_descriptionController.text)),
            children: [
              TextFormField(
                initialValue: _district ?? '',
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Kampala, Central',
                ),
                onChanged: (value) => setState(() => _district = value),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter where you work or stay'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 3,
                maxLength: 500,
                  onChanged: (_) => setState(() {
                    _descriptionIsAutoGenerated = false;
                  }),
                decoration: InputDecoration(
                  labelText: l10n?.descriptionOptionalLabel ??
                      'Description (optional)',
                  hintText: l10n?.descriptionOptionalHint ??
                      'Add any context Providers should know',
                  helperText:
                      'If you use the draft below, replace every bracketed prompt with your details. Avoid private information.',
                  helperStyle:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                  counterStyle:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (RegExp(r'\[[^\]]+\]').hasMatch(value ?? '')) {
                    return 'Replace the bracketed prompts with your details before continuing.';
                  }
                  return null;
                },
              ),
              FormSuggestionStrip(
                label: 'Draft',
                suggestions: _uniqueSuggestions([
                  _descriptionPromptSuggestions.first,
                ]),
                onSelected: (value) => setState(() {
                  _descriptionController.text = value;
                  _descriptionIsAutoGenerated = true;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListingFormPanel(
            title: l10n?.collateralLabel ?? 'Collateral',
            isComplete: !_hasCollateral ||
                _collateralDetailsController.text.trim().length >= 3,
            subtitle: l10n?.collateralPromptText ??
                'Choose whether this request is backed by an asset.',
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      icon: const Icon(Icons.block_rounded),
                      label: Text(
                        l10n?.noCollateralLabel ?? 'No collateral',
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(
                        l10n?.hasCollateralLabel ?? 'Has collateral',
                      ),
                    ),
                  ],
                  selected: {_hasCollateral},
                  onSelectionChanged: (selection) {
                    final hasCollateral = selection.first;
                    setState(() {
                      _hasCollateral = hasCollateral;
                      if (!hasCollateral) {
                        _collateralDetailsController.clear();
                        _collateralValueController.clear();
                        _collateralLocationController.clear();
                      }
                    });
                    _scheduleDraftSave();
                  },
                ),
              ),
              if (_hasCollateral) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _collateralDetailsController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.collateralDetailsLabel ?? 'Collateral details',
                    hintText: l10n?.collateralDetailsHint ??
                        'e.g. Land title, car, electronics, equipment',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if (!_hasCollateral) return null;
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) {
                      return l10n?.collateralAssetRequired ??
                          'Describe the collateral asset';
                    }
                    if (value.length < 3) {
                      return l10n?.collateralAssetDetailShort ??
                          'Add a little more detail';
                    }
                    return null;
                  },
                ),
                FormSuggestionStrip(
                  label: 'Recent',
                  suggestions: _recentValues(
                    (request) => request.collateralDetails ?? '',
                  ),
                  onSelected: (value) => setState(
                    () => _collateralDetailsController.text = value,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _collateralValueController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n?.collateralValueLabel(currency) ??
                              'Est. value ($currency)',
                          hintText: 'Optional',
                          prefixIcon: const Icon(
                            Icons.price_check_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _collateralLocationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n?.locationLabel ?? 'Location',
                          hintText: 'Optional',
                          prefixIcon: const Icon(
                            Icons.place_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                FormSuggestionStrip(
                  label: 'Value',
                  suggestions: _recentValues(
                    (request) => request.collateralEstimatedValue == null
                        ? ''
                        : request.currency != currency
                            ? ''
                            : '$currency ${fmtAmount(request.collateralEstimatedValue!)}',
                  ),
                  onSelected: (value) => setState(
                    () => _collateralValueController.text =
                        value.replaceAll(RegExp(r'[^0-9]'), ''),
                  ),
                ),
                FormSuggestionStrip(
                  label: 'Location',
                  suggestions: _recentValues(
                    (request) => request.collateralLocation ?? '',
                  ),
                  onSelected: (value) => setState(
                    () => _collateralLocationController.text = value,
                  ),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }

  // ─── Step 2: Income & repayment ─────────────────────────────────────────────

  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final canSuggestTerms = authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;
    final currency = _currencyCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _repaymentFormKey,
        onChanged: _scheduleDraftSave,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListingFormPanel(
            title: l10n?.panelRepaymentSource ?? 'Repayment source',
            isComplete: _incomeSourceController.text.trim().length >= 6 &&
                _preferredRepaymentPlan != null,
            children: [
              TextFormField(
                controller: _incomeSourceController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: l10n?.incomeSourceLabel ?? 'Income source',
                  hintText: l10n?.incomeSourceHint ??
                      'e.g. Salary, shop income, farming, side work',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return l10n?.validationIncomeSourceRequired ??
                        'Enter your repayment source';
                  }
                  if (value.length < 6) {
                    return l10n?.validationIncomeSourceDetail ??
                        'Add a little more detail';
                  }
                  return null;
                },
              ),
              FormSuggestionStrip(
                label: 'Recent',
                suggestions: _uniqueSuggestions([
                  ..._recentValues((request) => request.incomeSource),
                  'Monthly salary',
                  'Business income',
                  'Farming income',
                  'Rental income',
                  'Contract work',
                ]),
                onSelected: (value) =>
                    setState(() => _incomeSourceController.text = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _preferredRepaymentPlan,
                decoration: InputDecoration(
                  labelText: l10n?.preferredRepaymentPlanLabel ??
                      'Preferred repayment plan',
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                ),
                hint: Text(
                    l10n?.selectRepaymentPlanHint ?? 'Select repayment plan'),
                items: _repaymentPlans
                    .map((p) => DropdownMenuItem(
                          value: p['value'],
                          child: Text(_getLocalizedRepaymentPlan(p['value'])),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _preferredRepaymentPlan = v;
                  _selectedDueDay = null;
                  _updateRepaymentTimeline();
                }),
                validator: (v) => v == null
                    ? (l10n?.validationRepaymentPlanRequired ??
                        'Select a repayment plan')
                    : null,
              ),
              FormSuggestionStrip(
                label: 'Recent',
                suggestions: _recentValues(
                  (request) => _getLocalizedRepaymentPlan(
                      request.preferredRepaymentPlan),
                ),
                onSelected: (value) => setState(() {
                  _preferredRepaymentPlan =
                      _repaymentPlans.map((plan) => plan['value']!).firstWhere(
                            (plan) => _getLocalizedRepaymentPlan(plan) == value,
                            orElse: () => _preferredRepaymentPlan ?? 'monthly',
                          );
                  _selectedDueDay = null;
                  _updateRepaymentTimeline();
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListingFormPanel(
            title: l10n?.panelAbilityToRepay ?? 'Ability to repay',
            isComplete: (int.tryParse(_repaymentAmountController.text) ?? 0) >
                    0 &&
                _selectedDueDay != null &&
                _selectedDueTime != null &&
                _repaymentTimelineController.text.trim().length >= 10,
            children: [
              TextFormField(
                controller: _repaymentAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: l10n?.repaymentAmountHint ?? 'e.g. 250,000',
                  prefixIcon: const Icon(Icons.savings_outlined, size: 20),
                ).copyWith(
                  labelText: l10n?.repaymentAmountPerPeriodLabel(currency) ??
                      'Repayment amount per period ($currency)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n?.validationRepaymentAmountRequired ??
                        'Enter repayment amount';
                  }
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) {
                    return l10n?.validationRepaymentAmountValid ??
                        'Enter a valid amount';
                  }
                  return null;
                },
              ),
              FormSuggestionStrip(
                label: 'Recent',
                suggestions: _recentValues(
                  (request) => request.currency == currency
                      ? '$currency '
                          '${fmtAmount(request.repaymentAmountPerPeriod)}'
                      : '',
                ),
                onSelected: (value) => setState(() {
                  _repaymentAmountController.text =
                      value.replaceAll(RegExp(r'[^0-9]'), '');
                }),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _suggestedPrincipalInstallment == null
                      ? null
                      : _applySuggestedInstallment,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(
                    _suggestedPrincipalInstallment == null
                        ? 'Enter amount, duration, and repayment plan to calculate'
                        : 'Calculate for me · $currency '
                            '${fmtAmount(_suggestedPrincipalInstallment!)} per payment',
                  ),
                ),
              ),
              Text(
                'Estimate divides the requested principal across the selected '
                'payments. Interest and fees are not included.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDueDay,
                decoration: InputDecoration(
                  labelText: l10n?.dueDayLabel ?? 'Due day / frequency',
                  prefixIcon: const Icon(Icons.today_outlined, size: 20),
                ),
                hint: Text(l10n?.dueDayHint ??
                    'Select due day (e.g. 5th of every month)'),
                items: (_preferredRepaymentPlan == 'daily'
                        ? _dailyDueDayOptions
                        : _preferredRepaymentPlan == 'weekly'
                            ? _weeklyDueDayOptions
                            : _preferredRepaymentPlan == 'one_time'
                                ? _oneTimeDueDayOptions
                                : _monthlyDueDayOptions)
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedDueDay = v;
                  _updateRepaymentTimeline();
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDueTime,
                decoration: InputDecoration(
                  labelText: l10n?.dueCutoffTimeLabel ??
                      'Due cutoff time (for late fee timing)',
                  prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
                ),
                hint: Text(l10n?.dueCutoffTimeHint ??
                    'Select due time (e.g. 5:00 PM)'),
                items: _dueTimeOptions
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedDueTime = v;
                  _updateRepaymentTimeline();
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repaymentTimelineController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n?.repaymentTimelineLabel ??
                      'Repayment timeline & schedule',
                  hintText: l10n?.repaymentTimelineHint ??
                      'e.g. Paid by the 5th of every month by 5:00 PM for 8 months',
                  alignLabelWithHint: true,
                  helperText: l10n?.timelineHelperText ??
                      'Exact day & cutoff time used for late fee calculations',
                  prefixIcon: const Icon(Icons.event_repeat_outlined, size: 20),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return l10n?.validationRepaymentTimelineRequired ??
                        'Enter repayment timeline';
                  }
                  if (value.length < 10) {
                    return l10n?.validationRepaymentTimelineDetail ??
                        'Add a clearer timeline';
                  }
                  return null;
                },
              ),
              FormSuggestionStrip(
                label: 'Recent',
                suggestions:
                    _recentValues((request) => request.repaymentTimeline),
                onSelected: (value) => setState(
                  () => _repaymentTimelineController.text = value,
                ),
              ),
            ],
          ),
          // ── Affordability warning (borrower mirror of lender loss-alert) ──
          Builder(builder: (context) {
            final principal = int.tryParse(_amountController.text) ?? 0;
            final installment =
                int.tryParse(_repaymentAmountController.text) ?? 0;
            final periods = _preferredRepaymentPlan == null
                ? 0
                : RepaymentCalculator.paymentCount(
                    durationMonths: int.tryParse(_durationController.text) ?? 0,
                    repaymentPlan: _preferredRepaymentPlan!,
                  );
            final totalRepayment = installment * periods;
            if (installment <= 0 || principal <= 0)
              return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 10),
                AffordabilityWarningBanner(
                  currency: currency,
                  principal: principal,
                  totalRepayment: totalRepayment,
                  installmentAmount: installment,
                ),
              ],
            );
          }),
          const SizedBox(height: 10),
          LiveRepaymentMathPanel(
            currency: currency,
            principal: int.tryParse(_amountController.text) ?? 0,
            durationMonths: int.tryParse(_durationController.text) ?? 0,
            repaymentPlan: _preferredRepaymentPlan,
            installmentAmount:
                int.tryParse(_repaymentAmountController.text) ?? 0,
          ),
          const SizedBox(height: 10),
          ListingFormPanel(
            title: l10n?.panelPreferredTerms ?? 'Preferred terms',
            isComplete: !canSuggestTerms ||
                (_suggestedInterestController.text.isNotEmpty &&
                    _suggestedLateFeeController.text.isNotEmpty &&
                    _suggestedRepaymentPlan != null &&
                    _suggestedInstallmentController.text.isNotEmpty),
            subtitle: canSuggestTerms
                ? (l10n?.termsLockedNotice ??
                    'Locked when the request is published.')
                : null,
            children: canSuggestTerms
                ? [
                    // ── Quick Term Guide chips (Pro borrowers only) ──
                    TermGuideChips(
                      onPresetSelected: (interest, lateFee) {
                        setState(() {
                          _suggestedInterestController.text =
                              interest.toStringAsFixed(0);
                          _suggestedLateFeeController.text =
                              lateFee.toStringAsFixed(0);
                          // Recalculate installment suggestion based on interest
                          final principal =
                              int.tryParse(_amountController.text) ?? 0;
                          final periods = _preferredRepaymentPlan == null
                              ? 0
                              : RepaymentCalculator.paymentCount(
                                  durationMonths:
                                      int.tryParse(_durationController.text) ??
                                          0,
                                  repaymentPlan: _preferredRepaymentPlan!,
                                );
                          if (principal > 0 && periods > 0) {
                            final target = principal +
                                (principal * (interest / 100)).ceil();
                            _suggestedInstallmentController.text =
                                ((target / periods).ceil()).toString();
                          }
                        });
                      },
                    ),
                    TextFormField(
                      controller: _suggestedInterestController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n?.suggestedInterestRateLabel ??
                            'Suggested interest rate (%)',
                        prefixIcon: const Icon(Icons.percent_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n < 0 || n > 100) {
                          return l10n?.validationPercentRange ?? 'Use 0 to 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _suggestedLateFeeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n?.suggestedLateFeeLabel ??
                            'Suggested late payment fee (%)',
                        prefixIcon:
                            const Icon(Icons.warning_amber_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n < 0 || n > 100) {
                          return l10n?.validationPercentRange ?? 'Use 0 to 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _suggestedRepaymentPlan,
                      decoration: InputDecoration(
                        labelText: l10n?.suggestedRepaymentScheduleLabel ??
                            'Suggested repayment schedule',
                        prefixIcon: const Icon(Icons.event_available_outlined,
                            size: 20),
                      ),
                      items: _repaymentPlans
                          .map((p) => DropdownMenuItem(
                                value: p['value'],
                                child: Text(
                                    _getLocalizedRepaymentPlan(p['value'])),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _suggestedRepaymentPlan = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _suggestedInstallmentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.price_check_outlined, size: 20),
                      ).copyWith(
                        labelText:
                            l10n?.suggestedInstallmentAmountLabel(currency) ??
                                'Suggested installment amount ($currency)',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) {
                          return l10n?.validationRepaymentAmountValid ??
                              'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ]
                : [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n?.freeTermsBanner ??
                                  'Leave this blank — Providers will propose their own terms. Upgrade to Pro to suggest rates.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
          ),
        ]),
      ),
    );
  }

  // ─── Step 3: Reusable borrower information ──────────────────────────────────

  Widget _buildStep3() {
    final currency = _currencyCode;
    final employerRequired = _employmentStatus == 'government_employed' ||
        _employmentStatus == 'private_sector' ||
        _employmentStatus == 'business_owner';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _borrowerInformationFormKey,
        onChanged: _scheduleDraftSave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This information is private and used only for your loan requests. '
              'It is not added to your public listing or general profile.',
            ),
            if (_borrowerInformationLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_borrowerInformationLoadError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load your saved information: '
                      '$_borrowerInformationLoadError',
                    ),
                    TextButton(
                      onPressed: _retryBorrowerInformationLoad,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
            if (_savedBorrowerInformation case final saved?) ...[
              const SizedBox(height: 14),
              ListingFormPanel(
                title: 'Your saved information',
                isComplete: true,
                children: [
                  Text(
                    [
                      'Employment status: '
                          '${_employmentStatusLabel(saved.employmentStatus)}',
                      if (saved.employerBusinessName?.isNotEmpty == true)
                        'Employer / business: ${saved.employerBusinessName}',
                      'Monthly income range: '
                          '${_incomeRangeLabel(saved.monthlyIncomeRange, saved.incomeCurrency)}',
                      if (saved.preferredBank?.isNotEmpty == true)
                        'Preferred bank: ${saved.preferredBank}',
                    ].join('\n'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _useSavedBorrowerInformation,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Use saved information'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            ListingFormPanel(
              title: 'Employment & income',
              isComplete: _borrowerInformationReady,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _employmentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Employment status',
                  ),
                  items: _employmentStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status.$1,
                          child: Text(status.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _employmentStatus = value),
                  validator: (value) =>
                      value == null ? 'Select your employment status' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employerBusinessNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: employerRequired
                        ? 'Employer / business name'
                        : 'Employer / business name (optional)',
                  ),
                  validator: (value) {
                    if (employerRequired && (value?.trim().isEmpty ?? true)) {
                      return 'Enter your employer or business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _monthlyIncomeRange,
                  decoration: const InputDecoration(
                    labelText: 'Monthly income range',
                  ),
                  items: _monthlyIncomeRanges
                      .map(
                        (range) => DropdownMenuItem(
                          value: range,
                          child: Text(
                            _incomeRangeLabel(
                              range,
                              _incomeRangeCurrency ?? currency,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _monthlyIncomeRange = value;
                    _incomeRangeCurrency = currency;
                  }),
                  validator: (value) =>
                      value == null ? 'Select a monthly income range' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherIncomeSourceController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Other income source (optional)',
                    hintText: 'e.g. Farming, rent, or side business',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListingFormPanel(
              title: 'Banking',
              isComplete: _preferredBankController.text.trim().isNotEmpty,
              children: [
                TextFormField(
                  controller: _preferredBankController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Preferred bank (optional)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Changes to this information are saved for your next Loan Request '
              'when you publish this one.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _employmentStatusLabel(String value) {
    if (value == 'other') return 'Choose one of the listed statuses';
    return _employmentStatuses
        .firstWhere(
          (status) => status.$1 == value,
          orElse: () => (value, value),
        )
        .$2;
  }

  String _incomeRangeLabel(String value, String currency) {
    return switch (value) {
      'no_regular_income' => 'No regular income',
      'under_500k' => 'Under $currency 500,000',
      '500k_1m' => '$currency 500,000–1,000,000',
      '1m_2m' => '$currency 1,000,000–2,000,000',
      '2m_3m' => '$currency 2,000,000–3,000,000',
      'over_3m' => 'Over $currency 3,000,000',
      _ => value,
    };
  }

  // ─── Step 4: Review & publish ───────────────────────────────────────────────

  Widget _buildStep4() {
    final l10n = AppLocalizations.of(context);
    final amount = int.tryParse(_amountController.text) ?? 0;
    final duration = _durationController.text;
    final repaymentAmount = int.tryParse(_repaymentAmountController.text) ?? 0;
    final description = _descriptionController.text.trim();
    final collateralDetails = _collateralDetailsController.text.trim();
    final collateralValue = int.tryParse(_collateralValueController.text);
    final collateralLocation = _collateralLocationController.text.trim();
    final authState = context.watch<AuthBloc>().state;
    final canSuggestTerms = authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;
    final currency = _currencyCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          l10n?.reviewYourRequest ?? 'Review your request',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n?.reviewConfirmDetails ??
              'Confirm the details before publishing to the marketplace.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Summary card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(children: [
            ListingReviewRow(
              icon: Icons.title_rounded,
              label: l10n?.reviewTitle ?? 'Title',
              value: _listingTitle,
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n?.reviewAmount ?? 'Amount',
              value: '$currency ${fmtAmount(amount)}',
              highlight: true,
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.calendar_month_outlined,
              label: l10n?.reviewDuration ?? 'Duration',
              value: '$duration ${l10n?.months ?? "months"}',
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.category_outlined,
              label: l10n?.reviewPurpose ?? 'Purpose',
              value: _getLocalizedPurpose(_purposeValue),
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.location_on_outlined,
              label: _countryInfo.regionsLabel,
              value: _selectedRegion,
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.work_outline_rounded,
              label: l10n?.reviewIncomeSource ?? 'Income source',
              value: _incomeSourceController.text.trim(),
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.payments_outlined,
              label: l10n?.reviewPreferredRepaymentPlan ??
                  'Preferred repayment plan',
              value: _getLocalizedRepaymentPlan(_preferredRepaymentPlan),
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.savings_outlined,
              label: l10n?.reviewRepaymentAmount ?? 'Repayment amount',
              value:
                  '$currency ${fmtAmount(repaymentAmount)} ${l10n?.reviewPerPeriod ?? "per period"}',
            ),
            _divider(),
            ListingReviewRow(
              icon: Icons.event_repeat_outlined,
              label: l10n?.reviewRepaymentTimeline ?? 'Repayment timeline',
              value: _repaymentTimelineController.text.trim(),
            ),
            if (description.isNotEmpty) ...[
              _divider(),
              ListingReviewRow(
                icon: Icons.notes_rounded,
                label: l10n?.reviewDescription ?? 'Description',
                value: description,
              ),
            ],
            _divider(),
            ListingReviewRow(
              icon: _hasCollateral
                  ? Icons.verified_user_outlined
                  : Icons.block_rounded,
              label: 'Collateral',
              value: _hasCollateral
                  ? [
                      collateralDetails,
                      if (collateralValue != null)
                        '$currency ${fmtAmount(collateralValue)} estimated value',
                      if (collateralLocation.isNotEmpty) collateralLocation,
                    ].join(' · ')
                  : 'No Collateral',
            ),
            if (canSuggestTerms &&
                (_suggestedInterestController.text.isNotEmpty ||
                    _suggestedLateFeeController.text.isNotEmpty ||
                    _suggestedRepaymentPlan != null ||
                    _suggestedInstallmentController.text.isNotEmpty)) ...[
              _divider(),
              ListingReviewRow(
                icon: Icons.lock_outline_rounded,
                label: l10n?.reviewLockedTerms ?? 'Locked preferred terms',
                value: [
                  if (_suggestedInterestController.text.isNotEmpty)
                    '${_suggestedInterestController.text}% interest',
                  if (_suggestedLateFeeController.text.isNotEmpty)
                    '${_suggestedLateFeeController.text}% late fee on missed installment',
                  if (_suggestedRepaymentPlan != null)
                    _getLocalizedRepaymentPlan(_suggestedRepaymentPlan),
                  if (_suggestedInstallmentController.text.isNotEmpty)
                    '$currency ${fmtAmount(int.tryParse(_suggestedInstallmentController.text) ?? 0)} installment',
                ].join(' · '),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        // ── Repayment math recap (mirrors lender's "Live Return Estimate") ──
        LiveRepaymentMathPanel(
          currency: currency,
          principal: amount,
          durationMonths: int.tryParse(_durationController.text) ?? 0,
          repaymentPlan: _preferredRepaymentPlan,
          installmentAmount: repaymentAmount,
        ),

        const SizedBox(height: 16),

        // Non-custodial note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.verified_outlined,
                size: 14, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.reviewContactPrivacyNotice ??
                    'Your contact details stay hidden until an offer is accepted and the unlock flow is completed.',
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Theme.of(context).dividerColor);

  // ─── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_step == 3) ...[
            PostDurationInfoCard(
              durationDays: _limits.listingDurationDays,
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _submitting || !_currentStepReady
                ? null
                : (_step < 3 ? _next : _submit),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    _step < 3
                        ? (l10n?.btnContinue ?? 'Continue')
                        : (l10n?.btnPublishToMarketplace ??
                            'Publish to marketplace'),
                  ),
          ),
          if (_step > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _back,
              child: Text(l10n?.btnBack ?? 'Back'),
            ),
          ],
        ]),
      ),
    );
  }
}
