import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';

class OwnerCancellationHistoryScreen extends StatefulWidget {
  const OwnerCancellationHistoryScreen({super.key});

  @override
  State<OwnerCancellationHistoryScreen> createState() =>
      _OwnerCancellationHistoryScreenState();
}

class _OwnerCancellationHistoryScreenState
    extends State<OwnerCancellationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _cancellations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCancellations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCancellations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'You must be logged in to view cancellations.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = getIt<BookingRepository>();
      final list = await repo.getOwnerCancellations(user.uid);
      if (mounted) {
        setState(() {
          _cancellations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg,
              MediaQuery.of(context).padding.top + AppSizes.md,
              AppSizes.lg,
              AppSizes.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: AppText(
                        text: "Cancellations & Policy",
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amberAccent,
                  indicatorWeight: 3,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      text: _cancellations.isNotEmpty
                          ? "Cancelled Bookings (${_cancellations.length})"
                          : "Cancelled Bookings",
                    ),
                    const Tab(text: "Slot Recovery Policy"),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCancellationsTab(),
                _buildPolicyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDarkGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              AppText(
                text: "Failed to load cancellations",
                size: 16,
                weight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCancellations,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                child: const AppText(text: "Retry", color: Colors.white, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_cancellations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCancellations,
        color: AppColors.primaryDarkGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Center(
              child: AppText(
                text: "No Cancellations Found",
                size: 18,
                weight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: AppText(
                text: "No bookings have been cancelled or declined across your venues.",
                size: 13,
                color: AppColors.textSecondaryLight,
                align: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.info_outline, size: 16, color: AppColors.primaryDarkGreen),
                label: const AppText(
                  text: "View Slot Recovery Policy",
                  color: AppColors.primaryDarkGreen,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCancellations,
      color: AppColors.primaryDarkGreen,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: _cancellations.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          final item = _cancellations[index];
          return _buildCancellationCard(item);
        },
      ),
    );
  }

  Widget _buildCancellationCard(Map<String, dynamic> item) {
    final playerName = item['player_name']?.toString() ?? 'Player';
    final playerPhone = item['player_phone']?.toString() ?? '';
    final groundName = item['ground_name']?.toString() ?? 'Court';
    final sportName = item['sport_name']?.toString() ?? 'Sport';
    final reason = item['cancellation_reason']?.toString() ?? 'Cancelled';
    final cancelledBy = (item['cancelled_by']?.toString() ?? 'user').toLowerCase();
    final isCustomerCancelled = cancelledBy == 'user';
    final bookingId = item['booking_id']?.toString() ?? item['id']?.toString() ?? '';
    final amount = isCustomerCancelled 
        ? ((item['owner_compensation'] as num?)?.toDouble() ?? 0.0)
        : 0.0;

    DateTime? cancelledAt;
    if (item['cancelled_at'] != null) {
      cancelledAt = DateTime.tryParse(item['cancelled_at'].toString())?.toLocal();
    }

    DateTime? slotTime;
    if (item['slot_time'] != null) {
      slotTime = DateTime.tryParse(item['slot_time'].toString())?.toLocal();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.statusCancelled.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Player Name + Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: playerName,
                        size: 16,
                        weight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                      if (playerPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AppText(
                          text: playerPhone,
                          size: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                      const SizedBox(height: 2),
                      AppText(
                        text: "$groundName • $sportName",
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusCancelledBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: AppColors.statusCancelled.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 12, color: AppColors.statusCancelled),
                      const SizedBox(width: 4),
                      AppText(
                        text: isCustomerCancelled
                            ? "Cancelled by Customer"
                            : (cancelledBy.contains('timeout') ? "Timeout" : "Declined by Venue"),
                        size: 11,
                        weight: FontWeight.bold,
                        color: AppColors.statusCancelled,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Slot Date & Cancelled Date
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      AppText(
                        text: slotTime != null
                            ? DateFormat('EEE, d MMM • h:mm a').format(slotTime)
                            : 'Slot Time N/A',
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ],
                  ),
                ),
                if (cancelledAt != null)
                  AppText(
                    text: 'Cancelled ${DateFormat('d MMM, h:mm a').format(cancelledAt)}',
                    size: 11,
                    color: AppColors.textSecondaryLight,
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppText(
                      text: "Reason: $reason",
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Slot Released & Amount Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.slotAvailableBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.slotAvailableBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.slotAvailable),
                      const SizedBox(width: 6),
                      const AppText(
                        text: "Slot Liberated & Open for Rebooking",
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.slotAvailable,
                      ),
                    ],
                  ),
                  if (amount > 0)
                    AppText(
                      text: "₹${amount.toStringAsFixed(0)}",
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                ],
              ),
            ),

            if (bookingId.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppText(
                text: "Booking #CB${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}",
                size: 10,
                weight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyTab() {
    final cfg = AppConfigService.instance;
    final t1h = cfg.cancellationTier1Hours;
    final t1p = cfg.cancellationTier1Percent;
    final t2h = cfg.cancellationTier2Hours;
    final t2p = cfg.cancellationTier2Percent;
    final t3h = cfg.cancellationTier3Hours;
    final t3p = cfg.cancellationTier3Percent;
    final t4p = cfg.cancellationTier4Percent;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    AppText(
                      text: "Venue Protection & Slot Recovery",
                      size: 16,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                AppText(
                  text: "How Playora's dynamic cancellation and instant slot recovery ensure maximum court utilization and zero payment settlement hassles for venue partners.",
                  size: 12.5,
                  color: Colors.white70,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const AppText(
            text: "Dynamic Cancellation Windows & Tiers",
            size: 15,
            weight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
          const SizedBox(height: 10),

          _buildOwnerTierCard(
            tier: "Tier 1: > ${t1h.toStringAsFixed(0)}h before slot",
            refundPercent: "${t1p.toStringAsFixed(0)}% (Playora Coins)",
            ownerImpact: "Full slot liberation. Placed back on the market immediately.",
            color: Colors.green.shade700,
            bgColor: Colors.green.shade50,
          ),
          const SizedBox(height: 8),

          _buildOwnerTierCard(
            tier: "Tier 2: ${t2h.toStringAsFixed(0)}h – ${t1h.toStringAsFixed(0)}h before slot",
            refundPercent: "${t2p.toStringAsFixed(0)}% (Playora Coins)",
            ownerImpact: "Slot freed for re-booking with high recovery likelihood.",
            color: Colors.teal.shade700,
            bgColor: Colors.teal.shade50,
          ),
          const SizedBox(height: 8),

          _buildOwnerTierCard(
            tier: "Tier 3: ${t3h.toStringAsFixed(0)}h – ${t2h.toStringAsFixed(0)}h before slot",
            refundPercent: "${t3p.toStringAsFixed(0)}% (Playora Coins)",
            ownerImpact: "Short notice window. Slot instantly freed for walk-in or app players.",
            color: Colors.amber.shade800,
            bgColor: Colors.amber.shade50,
          ),
          const SizedBox(height: 8),

          _buildOwnerTierCard(
            tier: "Tier 4: < ${t3h.toStringAsFixed(0)}h before slot",
            refundPercent: "${t4p.toStringAsFixed(0)}% (Playora Coins)",
            ownerImpact: "Last-minute window. Venue slot immediately unlocked.",
            color: Colors.deepOrange.shade700,
            bgColor: Colors.deepOrange.shade50,
          ),

          const SizedBox(height: 20),

          const AppText(
            text: "Key Venue Owner Benefits",
            size: 15,
            weight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
          const SizedBox(height: 10),

          _buildBenefitItem(
            icon: Icons.electric_bolt_rounded,
            title: "Instant Real-Time Slot Liberation",
            content: "The exact second a customer cancels, the slot status updates to available across all search results. Another player can book it immediately.",
          ),
          _buildBenefitItem(
            icon: Icons.account_balance_wallet_outlined,
            title: "Closed-Loop Coin Refunds",
            content: "Customer refunds are credited in Playora Coins, not cash. Your venue settlement ledger remains predictable and free from bank chargebacks.",
          ),
          _buildBenefitItem(
            icon: Icons.approval_rounded,
            title: "45-Minute Approval Window",
            content: "When booking approval is enabled, you have 45 minutes to accept or decline. Expired requests automatically release slots without penalty.",
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOwnerTierCard({
    required String tier,
    required String refundPercent,
    required String ownerImpact,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: tier,
                size: 13,
                weight: FontWeight.bold,
                color: color,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppText(
                  text: refundPercent,
                  size: 11,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            text: ownerImpact,
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDarkGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  size: 13,
                  weight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
                const SizedBox(height: 2),
                AppText(
                  text: content,
                  size: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
