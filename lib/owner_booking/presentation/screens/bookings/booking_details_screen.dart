import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  Color _statusColor(String status) {
    return AppColors.bookingStatusColor(status);
  }

  Color _statusBgColor(String status) {
    return AppColors.bookingStatusBgColor(status);
  }

  String _formatSportSlug(String slug) {
    if (slug.isEmpty) return 'Box Cricket';
    return slug
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  void _showUnblockDialog(BuildContext context, String dateStr, String timeStr, String? blockReason, String bookingId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Unblock Slot",
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + (curved.value.clamp(0.0, 1.2) * 0.15),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.xxl,
                        AppSizes.xl,
                        AppSizes.xl,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textSecondaryLight,
                            Color(0xFF78909C),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusXxl),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_open_rounded,
                              color: AppColors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            "Unblock This Slot",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 20,
                                  color: AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: AppSizes.sm + 2),
                                Expanded(
                                  child: Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            "Reason: ${blockReason ?? 'Booked by owner'}\n\nMake this slot available for booking again?",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.sm,
                        AppSizes.xl,
                        AppSizes.xl,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.lg - 2,
                                ),
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.lg - 2,
                                ),
                                backgroundColor: AppColors.primaryDarkGreen,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await context
                                    .read<SlotCubit>()
                                    .unbookOwnerSlot(bookingId);
                                if (context.mounted) {
                                  toastification.show(
                                    context: context,
                                    title: const Text("Slot Unblocked"),
                                    type: ToastificationType.success,
                                    autoCloseDuration: const Duration(seconds: 3),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_open_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Unblock",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'pending').toString();

    final playerName = booking['player_name']?.toString() ?? 'Player';
    final groundName = booking['ground_name']?.toString() ?? 'Court';

    final rawSport = booking['sport_name']?.toString() ?? booking['sport']?.toString() ?? '';
    final sportName = _formatSportSlug(rawSport);

    // Slot date
    final slotTimeStr = booking['slot_time']?.toString() ?? '';
    DateTime? slotTime;
    if (slotTimeStr.isNotEmpty) slotTime = DateTime.tryParse(slotTimeStr)?.toLocal();
    final dateFormatted =
        slotTime != null ? DateFormat('EEEE, MMM d, yyyy').format(slotTime) : 'N/A';

    // Use period from DB; fall back to computing from slot_time
    final periodFromDb = booking['period']?.toString() ?? '';
    final String timeFormatted;
    if (periodFromDb.isNotEmpty) {
      timeFormatted = periodFromDb.split('|').first;
    } else if (slotTime != null) {
      timeFormatted =
          "${DateFormat('h:mm a').format(slotTime)} – ${DateFormat('h:mm a').format(slotTime.add(const Duration(hours: 1)))}";
    } else {
      timeFormatted = 'N/A';
    }

    // Booking ID
    final rawDisplayId = booking['display_id'];
    String displayId = (rawDisplayId != null && rawDisplayId.toString() != '0')
        ? rawDisplayId.toString()
        : '';
    if (displayId.isEmpty) {
      final fullId = booking['id']?.toString() ?? '';
      displayId = fullId.length > 5 ? fullId.substring(0, 5).toUpperCase() : fullId.toUpperCase();
    }

    // Amount & Fee Snapshot — stored in rupees per booking
    final platformFee = (booking['platform_fee'] as num?)?.toDouble() ?? AppConfigService.instance.platformFee;
    final commissionRate = (booking['commission_rate'] as num?)?.toDouble() ?? AppConfigService.instance.commissionRate;
    final commissionIsPercentage = booking['commission_is_percentage'] != null 
        ? (booking['commission_is_percentage'] == true) 
        : AppConfigService.instance.commissionIsPercentage;

    final rawAmount = (booking['amount'] as num?) ?? (booking['total_amount'] as num?) ?? 0;
    final totalAmount = rawAmount.toDouble();
    final baseAmount = (booking['base_amount'] as num?)?.toDouble() ?? (totalAmount - platformFee).clamp(0.0, totalAmount);

    final commissionFee = commissionIsPercentage
        ? baseAmount * commissionRate / 100
        : commissionRate;
    final groundRate = (booking['owner_earnings'] as num?)?.toDouble() ?? (baseAmount - commissionFee).clamp(0.0, baseAmount);

    // Player info
    final playerImage = booking['player_image']?.toString() ?? '';
    final memberSinceStr = booking['member_since']?.toString() ?? '';
    String memberSinceFormatted = '';
    if (memberSinceStr.isNotEmpty) {
      final msDate = DateTime.tryParse(memberSinceStr)?.toLocal();
      if (msDate != null) memberSinceFormatted = DateFormat('MMM yyyy').format(msDate);
    }
    // Check-in
    final isCheckedIn = booking['checked_in'] == true;
    final checkedInAtStr = booking['checked_in_at']?.toString() ?? '';
    String? checkedInFormatted;
    if (checkedInAtStr.isNotEmpty) {
      final ciDate = DateTime.tryParse(checkedInAtStr)?.toLocal();
      if (ciDate != null) checkedInFormatted = DateFormat('d MMM yyyy, h:mm a').format(ciDate);
    }

    // Booked on date
    final createdAtStr = booking['created_at']?.toString() ?? '';
    String bookedOnFormatted = '';
    if (createdAtStr.isNotEmpty) {
      final caDate = DateTime.tryParse(createdAtStr)?.toLocal();
      if (caDate != null) bookedOnFormatted = DateFormat('d MMM yyyy, h:mm a').format(caDate);
    }

    // Payment reference
    final paymentId = booking['razorpay_payment_id']?.toString() ?? '';

    final isOwnerBooking = booking['user_id'] == null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: AppText(
          text: isOwnerBooking ? "Blocked Slot Details" : "Booking Details",
          size: 16,
          weight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleSpacing: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green gradient header with status badge glow
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDarkGreen,
                    Color(0xFF0FA968),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppSizes.xl,
                MediaQuery.of(context).padding.top + 60,
                AppSizes.xl,
                AppSizes.xl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "Booking #CB$displayId",
                          size: 20,
                          weight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        if (bookedOnFormatted.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.xxs),
                          AppText(
                            text: "Booked on $bookedOnFormatted",
                            size: 11,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor(status)
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppText(
                      text: status[0].toUpperCase() + status.substring(1),
                      color: _statusColor(status),
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.xxxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check-in banner
                  _CheckInBanner(
                      isCheckedIn: isCheckedIn,
                      checkedInAt: checkedInFormatted),
                  const SizedBox(height: AppSizes.lg),

                  // Player card or Owner Block Reason
                  if (isOwnerBooking)
                    _SectionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.lock,
                                  color: AppColors.white, size: 24),
                            ),
                            const SizedBox(width: AppSizes.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const AppText(
                                    text: "Booked by Owner",
                                    size: 15,
                                    weight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: AppSizes.xxs),
                                  AppText(
                                    text: "Reason: ${booking['notes']?.toString().isNotEmpty == true ? booking['notes'] : 'No reason provided'}",
                                    size: 13,
                                    color:
                                        AppColors.textSecondaryLight,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _SectionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        child: Row(
                          children: [
                            // Avatar with ring border
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryDarkGreen,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    AppColors.primaryDarkGreen,
                                backgroundImage: playerImage.isNotEmpty
                                    ? NetworkImage(playerImage)
                                    : null,
                                child: playerImage.isEmpty
                                    ? AppText(
                                        text: playerName.isNotEmpty
                                            ? playerName[0]
                                                .toUpperCase()
                                            : 'P',
                                        color: AppColors.white,
                                        size: 20,
                                        weight: FontWeight.bold,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppSizes.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: playerName,
                                    size: 15,
                                    weight: FontWeight.bold,
                                  ),
                                  if (memberSinceFormatted
                                      .isNotEmpty) ...[
                                    const SizedBox(height: AppSizes.xxs),
                                    AppText(
                                      text:
                                          "Member since $memberSinceFormatted",
                                      size: 12,
                                      color:
                                          AppColors.textSecondaryLight,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSizes.xl),
                  const _SectionLabel(title: "BOOKING DETAILS"),
                  const SizedBox(height: AppSizes.sm),

                  _SectionCard(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: "Court",
                          value: groundName,
                          iconData: Icons.sports_tennis_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Sport",
                          value: sportName,
                          icon: sportIcon(rawSport.isNotEmpty
                              ? rawSport
                              : sportName),
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Date",
                          value: dateFormatted,
                          iconData: Icons.calendar_today_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Time",
                          value: timeFormatted,
                          iconData: Icons.access_time_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Booking ID",
                          value: "CB$displayId",
                          iconData: Icons.tag_rounded,
                        ),
                      ],
                    ),
                  ),

                  if (!isOwnerBooking) ...[
                    const SizedBox(height: AppSizes.xl),
                    const _SectionLabel(title: "PAYMENT SUMMARY"),
                    const SizedBox(height: AppSizes.sm),

                    _SectionCard(
                      child: Column(
                        children: [
                          _PaymentRow(
                            label: "Customer Paid",
                            value: "₹${totalAmount.toStringAsFixed(0)}",
                          ),
                          const _RowDivider(),
                          _PaymentRow(
                            label: "Platform Fee",
                            value: "– ₹${platformFee.toStringAsFixed(0)}",
                            valueColor: AppColors.error,
                          ),
                          if (commissionRate > 0) ...[
                            const _RowDivider(),
                            _PaymentRow(
                              label: commissionIsPercentage
                                  ? "Commission (${commissionRate.toStringAsFixed(commissionRate % 1 == 0 ? 0 : 1)}%)"
                                  : "Commission Fee",
                              value:
                                  "– ₹${commissionFee.toStringAsFixed(0)}",
                              valueColor: AppColors.error,
                            ),
                          ],
                          const _RowDivider(),
                          _PaymentRow(
                            label: "Taxes & Charges",
                            value: "Included",
                            valueColor: AppColors.textSecondaryLight,
                          ),
                          const _RowDivider(),
                          // You earn — highlighted section
                          Container(
                            margin: const EdgeInsets.only(
                                top: AppSizes.sm, bottom: AppSizes.xxs),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.md),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8F5E9),
                                  Color(0xFFF1F8E9),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              border: Border.all(
                                color: AppColors.primaryDarkGreen
                                    .withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDarkGreen
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppSizes.radiusSm),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 18,
                                        color:
                                            AppColors.primaryDarkGreen,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    const AppText(
                                      text: "You Earn",
                                      size: 14,
                                      weight: FontWeight.bold,
                                      color:
                                          AppColors.primaryDarkGreen,
                                    ),
                                  ],
                                ),
                                AppText(
                                  text:
                                      "₹${groundRate.toStringAsFixed(0)}",
                                  size: 20,
                                  weight: FontWeight.w800,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ],
                            ),
                          ),
                          if (paymentId.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.xs),
                            const _RowDivider(),
                            _PaymentRow(
                              label: "Payment Ref.",
                              value: paymentId,
                              valueColor: AppColors.textSecondaryLight,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (isOwnerBooking) ...[
                    const SizedBox(height: AppSizes.xxxxl),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightLg,
                      child: ElevatedButton(
                        onPressed: () {
                          _showUnblockDialog(context, dateFormatted, timeFormatted, booking['notes']?.toString(), booking['id'].toString());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.accentOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            side: const BorderSide(
                                color: AppColors.accentOrange,
                                width: 1.5),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_open_rounded, size: 18),
                            SizedBox(width: AppSizes.sm),
                            AppText(
                              text: "Unblock Slot",
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInBanner extends StatelessWidget {
  final bool isCheckedIn;
  final String? checkedInAt;

  const _CheckInBanner({required this.isCheckedIn, this.checkedInAt});

  @override
  Widget build(BuildContext context) {
    final color = isCheckedIn
        ? AppColors.primaryDarkGreen
        : AppColors.statusPending;
    final bg = isCheckedIn
        ? AppColors.statusConfirmedBg
        : AppColors.statusPendingBg;
    final border = isCheckedIn
        ? const Color(0xFF81C784)
        : AppColors.statusPendingBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg, vertical: AppSizes.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              isCheckedIn
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: isCheckedIn
                      ? "Checked In"
                      : "Not Yet Checked In",
                  size: 13,
                  weight: FontWeight.w700,
                  color: color,
                ),
                if (isCheckedIn && checkedInAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xxs),
                    child: AppText(
                      text: checkedInAt!,
                      size: 11,
                      color: AppColors.textSecondaryLight,
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

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          text: title,
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final IconData? iconData;

  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon + label
          if (iconData != null) ...[
            Icon(
              iconData,
              size: 16,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: AppSizes.sm),
          ] else if (icon != null) ...[
            HugeIcon(
              icon: icon,
              size: 16,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            flex: 2,
            child: AppText(
              text: label,
              size: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: AppText(
                    text: value,
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                    align: TextAlign.right,
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

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PaymentRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            text: label,
            size: 13,
            color: AppColors.textSecondaryLight,
          ),
          AppText(
            text: value,
            size: 13,
            weight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimaryLight,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.borderLight,
      height: 1,
      thickness: 1,
    );
  }
}
