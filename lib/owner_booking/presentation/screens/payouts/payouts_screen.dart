import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/utils/booking_id_util.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _walletData;
  List<dynamic> _withdrawals = [];
  bool _isLoadingWallet = true;
  bool _isRequesting = false;

  // Filter states
  String _withdrawalFilter = 'all'; // 'all', 'pending', 'success', 'failed'
  String _revenueFilter = 'all'; // 'all', 'settled', 'pending'

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    context.read<BookingsCubit>().fetchBookings();
    _fetchWalletAndHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletAndHistory() async {
    setState(() => _isLoadingWallet = true);
    try {
      final ownerId = FirebaseAuth.instance.currentUser?.uid;
      if (ownerId == null) {
        setState(() => _isLoadingWallet = false);
        return;
      }
      final walletResponse = await _supabase
          .rpc('get_owner_wallet', params: {'p_owner_id': ownerId});
      final withdrawalsResponse = await _supabase
          .from('withdrawals')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _walletData = walletResponse as Map<String, dynamic>?;
          _withdrawals = withdrawalsResponse as List<dynamic>;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _requestWithdrawal(double amount) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      await _supabase.rpc('request_withdrawal', params: {
        'p_owner_id': FirebaseAuth.instance.currentUser?.uid,
        'p_amount': amount,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Withdrawal request for ${_currencyFormat.format(amount)} submitted successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchWalletAndHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Request failed: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _showWithdrawBottomSheet() {
    final available = (_walletData?['available_balance'] ?? 0.0) as num;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('No available balance to withdraw.'),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: available.toStringAsFixed(0));
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentInput = double.tryParse(controller.text) ?? 0.0;
          final isExceeded = currentInput > available;
          final isZeroOrLess = currentInput <= 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primaryDarkGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: 'Request Payout',
                                size: 18,
                                weight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                              AppText(
                                text: 'Transfer funds to registered bank',
                                size: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Available Balance Indicator Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slotAvailableBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryDarkGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 12),
                            ),
                            const SizedBox(width: 10),
                            const AppText(
                              text: 'Available for Payout',
                              size: 13,
                              color: AppColors.primaryDarkGreen,
                              weight: FontWeight.w600,
                            ),
                          ],
                        ),
                        AppText(
                          text: _currencyFormat.format(available),
                          size: 15,
                          weight: FontWeight.bold,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Amount Input Field
                  const AppText(
                    text: 'Enter Amount',
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExceeded
                            ? AppColors.error
                            : AppColors.primaryDarkGreen.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: 0.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                final parsed = double.tryParse(val);
                                if (parsed == null || parsed <= 0) {
                                  validationError = 'Please enter a valid amount';
                                } else if (parsed > available) {
                                  validationError = 'Amount exceeds available balance';
                                } else {
                                  validationError = null;
                                }
                              });
                            },
                          ),
                        ),
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                            onPressed: () {
                              setModalState(() {
                                controller.clear();
                                validationError = 'Please enter an amount';
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  if (validationError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        validationError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quick Percentage Chips
                  Row(
                    children: [
                      _QuickChip(
                        label: '25%',
                        onTap: () {
                          setModalState(() {
                            controller.text = (available * 0.25).round().toString();
                            validationError = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: '50%',
                        onTap: () {
                          setModalState(() {
                            controller.text = (available * 0.50).round().toString();
                            validationError = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: '75%',
                        onTap: () {
                          setModalState(() {
                            controller.text = (available * 0.75).round().toString();
                            validationError = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: 'Max (100%)',
                        isHighlighted: true,
                        onTap: () {
                          setModalState(() {
                            controller.text = available.toStringAsFixed(0);
                            validationError = null;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Trust & Timeline Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                text: 'Processing Timeline',
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Payouts are verified and transferred within 24-48 business hours to your verified account.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                          ),
                          child: const AppText(
                            text: 'Cancel',
                            color: AppColors.textSecondaryLight,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_isRequesting || isExceeded || isZeroOrLess)
                              ? null
                              : () {
                                  final amt = double.tryParse(controller.text);
                                  if (amt != null && amt > 0 && amt <= available) {
                                    _requestWithdrawal(amt);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGreen,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isRequesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    AppText(
                                      text: 'Confirm Withdrawal',
                                      color: Colors.white,
                                      weight: FontWeight.bold,
                                      size: 15,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawalDetailsSheet(dynamic w) {
    final amount = (w['amount'] ?? 0) as num;
    final rawStatus = w['status']?.toString().toLowerCase() ?? 'pending';
    final date = DateTime.tryParse(w['created_at']?.toString() ?? '')?.toLocal();
    final updatedDate = DateTime.tryParse(w['updated_at']?.toString() ?? '')?.toLocal();
    final dateFormatted =
        date != null ? DateFormat('MMMM d, yyyy • h:mm a').format(date) : '—';
    final id = w['id']?.toString() ?? '—';
    final transferId = w['cashfree_transfer_id']?.toString();
    final failureReason = w['failure_reason']?.toString();

    final (statusLabel, statusColor, statusBg, statusIcon) =
        _withdrawalStatusStyle(rawStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  text: 'Transaction Receipt',
                  size: 18,
                  weight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount & Status Badge
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '- ${_currencyFormat.format(amount)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step Progress Indicator
            _buildStatusTimeline(rawStatus),

            const SizedBox(height: 20),

            // Metadata card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _ReceiptRow(
                    label: 'Transaction ID',
                    value: id.length > 12 ? '${id.substring(0, 12)}...' : id,
                    fullValueToCopy: id,
                  ),
                  const Divider(height: 20, color: AppColors.borderLight),
                  _ReceiptRow(
                    label: 'Requested On',
                    value: dateFormatted,
                  ),
                  if (transferId != null && transferId.isNotEmpty) ...[
                    const Divider(height: 20, color: AppColors.borderLight),
                    _ReceiptRow(
                      label: 'Transfer Ref ID',
                      value: transferId,
                      fullValueToCopy: transferId,
                    ),
                  ],
                  if (updatedDate != null && rawStatus == 'success') ...[
                    const Divider(height: 20, color: AppColors.borderLight),
                    _ReceiptRow(
                      label: 'Completed On',
                      value: DateFormat('MMM d, yyyy • h:mm a').format(updatedDate),
                    ),
                  ],
                ],
              ),
            ),

            // Failure Banner if applicable
            if (rawStatus == 'rejected' || rawStatus == 'failed') ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusCancelledBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            text: 'Failure Reason',
                            weight: FontWeight.bold,
                            size: 13,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            failureReason != null && failureReason.isNotEmpty
                                ? failureReason
                                : 'The withdrawal could not be completed. The requested amount has been restored to your available balance.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[800],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const AppText(
                  text: 'Close Receipt',
                  color: Colors.white,
                  weight: FontWeight.bold,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    int currentStep = 1; // 1: Requested, 2: Processing, 3: Completed
    bool isFailed = status == 'rejected' || status == 'failed';

    if (status == 'processing' || status == 'approved') {
      currentStep = 2;
    } else if (status == 'success') {
      currentStep = 3;
    }

    return Row(
      children: [
        _TimelineStep(
          title: 'Requested',
          isActive: currentStep >= 1,
          isCompleted: currentStep > 1 || (!isFailed && currentStep == 3),
        ),
        _TimelineLine(isActive: currentStep >= 2),
        _TimelineStep(
          title: 'Processing',
          isActive: currentStep >= 2,
          isCompleted: currentStep > 2,
        ),
        _TimelineLine(isActive: currentStep >= 3 || isFailed),
        _TimelineStep(
          title: isFailed ? 'Failed' : 'Completed',
          isActive: currentStep >= 3 || isFailed,
          isCompleted: currentStep == 3,
          isError: isFailed,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableBalance = (_walletData?['available_balance'] ?? 0.0) as num;
    final totalEarnings = (_walletData?['total_earnings'] ?? 0.0) as num;
    final totalWithdrawn = _withdrawals
        .where((w) =>
            w['status']?.toString().toLowerCase() == 'success' ||
            w['status']?.toString().toLowerCase() == 'pending')
        .fold<num>(0, (sum, w) => sum + ((w['amount'] ?? 0) as num));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF07482D),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const AppText(
                text: 'Earnings & Payouts',
                size: 18,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: _isLoadingWallet ? null : _fetchWalletAndHistory,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildModernHeroHeader(
                  availableBalance,
                  totalEarnings,
                  totalWithdrawn,
                ),
              ),
            ),

            // Persistent Pill Tabs Header
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabHeaderDelegate(
                child: Container(
                  color: const Color(0xFFF7F9FA),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primaryDarkGreen,
                      unselectedLabelColor: AppColors.textSecondaryLight,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.outbox_rounded, size: 16),
                              const SizedBox(width: 6),
                              const Text('Withdrawals'),
                              if (_withdrawals.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 0
                                        ? AppColors.primaryDarkGreen.withValues(alpha: 0.12)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_withdrawals.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _tabController.index == 0
                                          ? AppColors.primaryDarkGreen
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_rounded, size: 16),
                              const SizedBox(width: 6),
                              const Text('Revenue Stream'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWithdrawalsTab(),
            _buildBookingsRevenueTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomWithdrawBar(availableBalance),
    );
  }

  Widget _buildModernHeroHeader(
    num available,
    num totalEarned,
    num totalWithdrawn,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B25),
            Color(0xFF095A39),
            Color(0xFF0B8457),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle background decorative radial glow
          Positioned(
            right: -40,
            top: 20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLightGreen.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Header Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Available Balance Badge & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF80E5B1), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(
                                color: Color(0xFFC8F2DD),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF34D399), size: 7),
                            SizedBox(width: 5),
                            Text(
                              'Live Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Main Big Balance Display
                  _isLoadingWallet
                      ? Shimmer.fromColors(
                          baseColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.4),
                          child: Container(
                            width: 180,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${available.toStringAsFixed(2).split('.').first}',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '.${available.toStringAsFixed(2).split('.').last}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 18),

                  // Sub-Cards: Total Earned & Withdrawn
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up_rounded,
                          iconColor: const Color(0xFF34D399),
                          label: 'Total Earned',
                          value: _isLoadingWallet
                              ? '—'
                              : _currencyFormat.format(totalEarned),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.arrow_upward_rounded,
                          iconColor: const Color(0xFFFCD34D),
                          label: 'Withdrawn',
                          value: _isLoadingWallet
                              ? '—'
                              : _currencyFormat.format(totalWithdrawn),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTab() {
    if (_isLoadingWallet) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, index) => const _WithdrawalSkeletonCard(),
      );
    }

    // Filter withdrawals
    final filtered = _withdrawals.where((w) {
      if (_withdrawalFilter == 'all') return true;
      final status = w['status']?.toString().toLowerCase() ?? '';
      if (_withdrawalFilter == 'pending') return status == 'pending' || status == 'processing' || status == 'approved';
      if (_withdrawalFilter == 'success') return status == 'success';
      if (_withdrawalFilter == 'failed') return status == 'failed' || status == 'rejected';
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primaryDarkGreen,
      onRefresh: _fetchWalletAndHistory,
      child: CustomScrollView(
        slivers: [
          // Filter Chips Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusFilterChip(
                      label: 'All (${_withdrawals.length})',
                      isSelected: _withdrawalFilter == 'all',
                      onTap: () => setState(() => _withdrawalFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'Pending',
                      icon: Icons.access_time_filled_rounded,
                      iconColor: AppColors.statusPending,
                      isSelected: _withdrawalFilter == 'pending',
                      onTap: () => setState(() => _withdrawalFilter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'Success',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      isSelected: _withdrawalFilter == 'success',
                      onTap: () => setState(() => _withdrawalFilter = 'success'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'Failed',
                      icon: Icons.cancel_rounded,
                      iconColor: AppColors.error,
                      isSelected: _withdrawalFilter == 'failed',
                      onTap: () => setState(() => _withdrawalFilter = 'failed'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: _withdrawalFilter == 'all'
                    ? 'No withdrawals yet'
                    : 'No $_withdrawalFilter withdrawals',
                subtitle: _withdrawalFilter == 'all'
                    ? 'When you withdraw your earnings, your transaction history will appear here.'
                    : 'There are no transactions matching the selected filter.',
                actionLabel: _withdrawalFilter != 'all' ? 'Reset Filters' : null,
                onAction: _withdrawalFilter != 'all'
                    ? () => setState(() => _withdrawalFilter = 'all')
                    : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final w = filtered[index];
                    return _buildWithdrawalCard(w);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(dynamic w) {
    final amount = (w['amount'] ?? 0) as num;
    final rawStatus = w['status']?.toString().toLowerCase() ?? 'pending';
    final date = DateTime.tryParse(w['created_at']?.toString() ?? '')?.toLocal();
    final dateStr = date != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(date)
        : '—';

    final (statusLabel, statusColor, statusBg, statusIcon) =
        _withdrawalStatusStyle(rawStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showWithdrawalDetailsSheet(w),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Circular status icon container
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Title and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          AppText(
                            text: 'Withdrawal Payout',
                            weight: FontWeight.bold,
                            size: 15,
                            color: AppColors.textPrimaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount and status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${_currencyFormat.format(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color, Color, IconData) _withdrawalStatusStyle(String status) {
    return switch (status) {
      'success' => (
          'SUCCESS',
          AppColors.success,
          AppColors.slotAvailableBg,
          Icons.check_circle_rounded
        ),
      'rejected' || 'failed' => (
          status.toUpperCase(),
          AppColors.error,
          AppColors.statusCancelledBg,
          Icons.cancel_rounded
        ),
      _ => (
          'PENDING',
          AppColors.statusPending,
          AppColors.statusPendingBg,
          Icons.access_time_filled_rounded
        ),
    };
  }

  Widget _buildBookingsRevenueTab() {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        if (state is BookingsLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, index) => const _WithdrawalSkeletonCard(),
          );
        } else if (state is BookingsError) {
          return _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load bookings',
            subtitle: state.message,
            isError: true,
            actionLabel: 'Retry',
            onAction: () => context.read<BookingsCubit>().fetchBookings(),
          );
        } else if (state is BookingsLoaded) {
          final revenueBookings = state.allBookings.where((b) {
            final status = b['status']?.toString().toLowerCase();
            return status == 'paid' ||
                status == 'confirmed' ||
                status == 'completed';
          }).toList();

          if (revenueBookings.isEmpty) {
            return const _EmptyState(
              icon: Icons.payments_outlined,
              title: 'No revenue yet',
              subtitle: 'Completed booking earnings will automatically be credited and displayed here.',
            );
          }

          final totalRevenue = revenueBookings.fold<num>(
              0, (sum, b) => sum + ((b['owner_earnings'] ?? 0) as num));
          final settledCount = revenueBookings
              .where((b) =>
                  b['payout_status']?.toString().toLowerCase() == 'settled')
              .length;
          final pendingCount = revenueBookings.length - settledCount;

          // Filter by status if applied
          final filteredBookings = revenueBookings.where((b) {
            if (_revenueFilter == 'all') return true;
            final isSettled = b['payout_status']?.toString().toLowerCase() == 'settled';
            if (_revenueFilter == 'settled') return isSettled;
            if (_revenueFilter == 'pending') return !isSettled;
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Summary Banner Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEF0F2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              text: 'Net Earned Revenue',
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalRevenue),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDarkGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _MiniSummaryPill(
                              label: 'Settled',
                              value: '$settledCount',
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _MiniSummaryPill(
                              label: 'Pending',
                              value: '$pendingCount',
                              color: AppColors.statusPending,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      _StatusFilterChip(
                        label: 'All (${revenueBookings.length})',
                        isSelected: _revenueFilter == 'all',
                        onTap: () => setState(() => _revenueFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Settled ($settledCount)',
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        isSelected: _revenueFilter == 'settled',
                        onTap: () => setState(() => _revenueFilter = 'settled'),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Pending ($pendingCount)',
                        icon: Icons.hourglass_top_rounded,
                        iconColor: AppColors.statusPending,
                        isSelected: _revenueFilter == 'pending',
                        onTap: () => setState(() => _revenueFilter = 'pending'),
                      ),
                    ],
                  ),
                ),
              ),

              // List of Revenue Bookings
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final b = filteredBookings[index];
                      return _buildRevenueBookingCard(b);
                    },
                    childCount: filteredBookings.length,
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRevenueBookingCard(dynamic b) {
    final earnings = (b['owner_earnings'] ?? 0) as num;
    final totalAmount = (b['amount'] ?? 0) as num;
    final payoutStatus = b['payout_status']?.toString().toLowerCase() ?? 'pending';
    final isSettled = payoutStatus == 'settled';

    final rawPeriod = b['period']?.toString() ?? '';
    final slotTime = b['slot_time']?.toString() ?? '';
    final sportName = b['sport_name']?.toString() ?? 'Cricket';

    final String displayId = BookingIdUtil.formatBookingId(
      b['display_id'],
      b['id'],
    );
    final bookingIdText = '#CB$displayId';

    String dateStr = '';
    String timeDisplay = '';
    if (slotTime.isNotEmpty) {
      try {
        final d = DateTime.parse(slotTime).toLocal();
        dateStr = DateFormat('MMM d, yyyy').format(d);

        if (!rawPeriod.contains('|')) {
          final end = d.add(const Duration(hours: 1));
          timeDisplay = '${DateFormat('h:mm a').format(d)} - ${DateFormat('h:mm a').format(end)}';
        }
      } catch (_) {}
    }

    if (rawPeriod.contains('|')) {
      timeDisplay = rawPeriod.split('|').last.trim();
    }
    if (timeDisplay.isEmpty) {
      timeDisplay = rawPeriod;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(booking: b),
              ),
            );
            if (result == true && mounted) {
              context.read<BookingsCubit>().fetchBookings();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top row: ID & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bookingIdText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatSportName(sportName),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSettled
                            ? AppColors.slotAvailableBg
                            : AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSettled
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_top_rounded,
                            size: 11,
                            color: isSettled
                                ? AppColors.success
                                : AppColors.statusPending,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSettled ? 'SETTLED' : 'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSettled
                                  ? AppColors.success
                                  : AppColors.statusPending,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Middle row: Timing and Earning
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SportIcon(
                        sport: sportName,
                        size: 20,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Date & Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: dateStr.isNotEmpty ? dateStr : 'Booking Slot',
                            weight: FontWeight.w600,
                            size: 14,
                            color: AppColors.textPrimaryLight,
                          ),
                          const SizedBox(height: 2),
                          if (timeDisplay.isNotEmpty)
                            Text(
                              timeDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Amount breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+ ${_currencyFormat.format(earnings)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.success,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gross: ${_currencyFormat.format(totalAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomWithdrawBar(num availableBalance) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'Withdrawable Balance',
                  size: 11,
                  color: AppColors.textSecondaryLight,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(availableBalance),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: (_isLoadingWallet || availableBalance <= 0)
                ? null
                : _showWithdrawBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                AppText(
                  text: 'Withdraw Funds',
                  color: Colors.white,
                  weight: FontWeight.bold,
                  size: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets & Delegates ──────────────────────────────────────────

class _SliverTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabHeaderDelegate({required this.child});

  @override
  double get minExtent => 64.0;
  @override
  double get maxExtent => 64.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverTabHeaderDelegate oldDelegate) {
    return false;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFBBE5D0),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDarkGreen : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (iconColor ?? Colors.grey[700]),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _QuickChip({
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primaryDarkGreen.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.primaryDarkGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted
                    ? AppColors.primaryDarkGreen
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniSummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniSummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final String? fullValueToCopy;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.fullValueToCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: label,
          size: 13,
          color: AppColors.textSecondaryLight,
          weight: FontWeight.w500,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text: value,
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            if (fullValueToCopy != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: fullValueToCopy!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isCompleted;
  final bool isError;

  const _TimelineStep({
    required this.title,
    required this.isActive,
    this.isCompleted = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    Color stepColor = Colors.grey[400]!;
    if (isError) {
      stepColor = AppColors.error;
    } else if (isActive) {
      stepColor = AppColors.primaryDarkGreen;
    }

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive ? stepColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 2),
          ),
          child: Center(
            child: isError
                ? const Icon(Icons.close, size: 12, color: Colors.white)
                : isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.textPrimaryLight : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final bool isActive;
  const _TimelineLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppColors.primaryDarkGreen : Colors.grey[300],
      ),
    );
  }
}

class _WithdrawalSkeletonCard extends StatelessWidget {
  const _WithdrawalSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primaryDarkGreen;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 18),
            AppText(
              text: title,
              size: 17,
              weight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
