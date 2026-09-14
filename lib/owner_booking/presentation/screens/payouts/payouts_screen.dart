import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingsCubit>().fetchBookings();
    _fetchWalletAndHistory();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal requested successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
        _fetchWalletAndHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _showWithdrawDialog() {
    final available = (_walletData?['available_balance'] ?? 0.0) as num;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available balance to withdraw.')),
      );
      return;
    }
    final controller = TextEditingController(text: available.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.primaryDarkGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const AppText(
                      text: 'Request Withdrawal',
                      size: 17,
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.slotAvailableBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primaryDarkGreen, size: 16),
                      const SizedBox(width: 8),
                      AppText(
                        text: 'Available balance: ₹$available',
                        color: AppColors.primaryDarkGreen,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded,
                        color: AppColors.primaryDarkGreen, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryDarkGreen, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        child: const AppText(text: 'Cancel', color: AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRequesting
                            ? null
                            : () {
                                final amount =
                                    double.tryParse(controller.text);
                                if (amount == null ||
                                    amount <= 0 ||
                                    amount > available) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text('Invalid amount')),
                                  );
                                  return;
                                }
                                _requestWithdrawal(amount);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const AppText(
                                text: 'Withdraw',
                                color: AppColors.white,
                                weight: FontWeight.bold,
                              ),
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableBalance =
        (_walletData?['available_balance'] ?? 0.0) as num;
    final totalEarnings = (_walletData?['total_earnings'] ?? 0.0) as num;
    final totalWithdrawn = _withdrawals
        .where((w) =>
            w['status']?.toString().toLowerCase() == 'success' ||
            w['status']?.toString().toLowerCase() == 'pending')
        .fold<num>(0, (sum, w) => sum + ((w['amount'] ?? 0) as num));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B8457), // AppColors.primaryDarkGreen
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: 'Earnings & Payouts',
          size: 18,
          weight: FontWeight.bold,
          color: AppColors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.white, size: 22),
            onPressed: _isLoadingWallet ? null : _fetchWalletAndHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeroHeader(availableBalance, totalEarnings, totalWithdrawn),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryDarkGreen,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primaryDarkGreen,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Withdrawals'),
                Tab(text: 'Booking Revenue'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWithdrawalsTab(),
                _buildBookingsRevenueTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoadingWallet ? null : _showWithdrawDialog,
          icon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.white),
          label: const AppText(
            text: 'Withdraw Funds',
            color: AppColors.white,
            weight: FontWeight.bold,
            size: 16,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDarkGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
      num available, num totalEarned, num totalWithdrawn) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B8457), // AppColors.primaryDarkGreen
            Color(0xFF065C3A), // Darker shade
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Available Balance',
            size: 13,
            color: Color(0xFFB2DFDB),
          ),
          const SizedBox(height: 4),
          _isLoadingWallet
              ? const _SkeletonBox(width: 160, height: 36)
              : AppText(
                  text: '₹${available.toStringAsFixed(2)}',
                  size: 34,
                  weight: FontWeight.bold,
                  color: AppColors.white,
                ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: Icons.trending_up_rounded,
                  label: 'Total Earned',
                  value: _isLoadingWallet
                      ? '—'
                      : '₹${totalEarned.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Withdrawn',
                  value: _isLoadingWallet
                      ? '—'
                      : '₹${totalWithdrawn.toStringAsFixed(0)}',
                ),
              ),
            ],
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
        itemBuilder: (_, _i) => const _WithdrawalSkeleton(),
      );
    }
    if (_withdrawals.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No withdrawals yet',
        subtitle: 'Your withdrawal history will appear here.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryDarkGreen,
      onRefresh: _fetchWalletAndHistory,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: _withdrawals.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: AppColors.borderLight),
        itemBuilder: (context, index) {
          final w = _withdrawals[index];
          final amount = (w['amount'] ?? 0) as num;
          final rawStatus = w['status']?.toString().toLowerCase() ?? 'pending';
          final date =
              DateTime.tryParse(w['created_at'].toString())?.toLocal();
          final dateStr = date != null
              ? DateFormat('MMM d, yyyy • h:mm a').format(date)
              : '';

          final (statusLabel, statusColor, statusBg, statusIcon) =
              _withdrawalStatusStyle(rawStatus);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Withdrawal',
                        weight: FontWeight.w600,
                        size: 15,
                        color: AppColors.textPrimaryLight,
                      ),
                      const SizedBox(height: 3),
                      AppText(
                        text: dateStr,
                        size: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      text: '- ₹${amount.toStringAsFixed(0)}',
                      weight: FontWeight.bold,
                      size: 15,
                      color: AppColors.textPrimaryLight,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      text: statusLabel,
                      color: statusColor,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  (String, Color, Color, IconData) _withdrawalStatusStyle(String status) {
    return switch (status) {
      'success' => (
          'SUCCESS',
          AppColors.success,
          AppColors.slotAvailableBg,
          Icons.check_rounded
        ),
      'rejected' || 'failed' => (
          status.toUpperCase(),
          AppColors.error,
          AppColors.statusCancelledBg,
          Icons.close_rounded
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
            itemBuilder: (_, _i) => const _WithdrawalSkeleton(),
          );
        } else if (state is BookingsError) {
          return _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.message,
            isError: true,
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
              subtitle: 'Completed booking revenues will show here.',
            );
          }

          final totalRevenue = revenueBookings.fold<num>(
              0, (sum, b) => sum + ((b['owner_earnings'] ?? 0) as num));
          final settledCount = revenueBookings
              .where((b) =>
                  b['payout_status']?.toString().toLowerCase() == 'settled')
              .length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: 'Net Revenue',
                            size: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            text: '₹${totalRevenue.toStringAsFixed(0)}',
                            size: 20,
                            weight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _MiniStat(label: 'Bookings', value: '${revenueBookings.length}'),
                          const SizedBox(width: 16),
                          _MiniStat(label: 'Settled', value: '$settledCount'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const Divider(height: 1, color: AppColors.borderLight),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final b = revenueBookings[index];
                    final amount = (b['owner_earnings'] ?? 0) as num;
                    final payoutStatus =
                        b['payout_status']?.toString().toLowerCase() ??
                            'pending';
                    final rawPeriod = b['period']?.toString() ?? '';
                    final slotTime = b['slot_time']?.toString() ?? '';
                    
                    String displayId = b['display_id']?.toString() ?? '';
                    if (displayId.isEmpty) {
                      final fullId = b['id']?.toString() ?? '';
                      displayId = fullId.length > 5
                          ? fullId.substring(0, 5).toUpperCase()
                          : fullId;
                    }
                    final bookingIdText = displayId.isNotEmpty ? '#$displayId' : 'Booking';

                    String dateStr = '';
                    String timeDisplay = '';
                    if (slotTime.isNotEmpty) {
                      try {
                        final d = DateTime.parse(slotTime).toLocal();
                        dateStr = DateFormat('MMM d').format(d);
                        
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
                    
                    final isSettled = payoutStatus == 'settled';

                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(booking: b),
                          ),
                        );
                        if (result == true && context.mounted) {
                          context.read<BookingsCubit>().fetchBookings();
                        }
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppColors.primaryDarkGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: bookingIdText,
                                        weight: FontWeight.w600,
                                        size: 15,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                      const SizedBox(height: 2),
                                      AppText(
                                        text: timeDisplay.isNotEmpty && dateStr.isNotEmpty
                                            ? '$dateStr • $timeDisplay'
                                            : dateStr,
                                        size: 13,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(
                                      text: '+ ₹${amount.toStringAsFixed(0)}',
                                      weight: FontWeight.bold,
                                      size: 15,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(height: 4),
                                    AppText(
                                      text: isSettled ? 'SETTLED' : 'PENDING',
                                      color: isSettled ? AppColors.textSecondaryLight : AppColors.statusPending,
                                      size: 11,
                                      weight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 70, color: AppColors.borderLight),
                        ],
                      ),
                    );
                  },
                  childCount: revenueBookings.length,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText(text: label, size: 11, color: AppColors.textSecondaryLight),
        AppText(text: value, size: 15, weight: FontWeight.w700, color: AppColors.textPrimaryLight),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB2DFDB),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            color: highlight
                ? AppColors.primaryDarkGreen
                : AppColors.textSecondaryLight,
            size: 16),
        const SizedBox(height: 4),
        AppText(
          text: value,
          size: 14,
          weight: FontWeight.bold,
          color: highlight
              ? AppColors.primaryDarkGreen
              : AppColors.textPrimaryLight,
        ),
        AppText(
          text: label,
          size: 10,
          color: AppColors.textSecondaryLight,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.textSecondaryLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            AppText(
              text: title,
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(height: 6),
            AppText(
              text: subtitle,
              size: 13,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _WithdrawalSkeleton extends StatelessWidget {
  const _WithdrawalSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    )),
                const SizedBox(height: 6),
                Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  height: 14,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  )),
              const SizedBox(height: 6),
              Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

