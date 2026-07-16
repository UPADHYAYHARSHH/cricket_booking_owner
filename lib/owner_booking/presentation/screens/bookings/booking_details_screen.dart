import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/fee_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'confirmed':
      case 'completed':
        return const Color(0xFF2E6A4F);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'confirmed':
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatSportSlug(String slug) {
    if (slug.isEmpty) return 'Box Cricket';
    return slug
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
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
      timeFormatted = periodFromDb;
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

    // Amount — stored in rupees
    final rawAmount = (booking['amount'] as num?) ?? (booking['total_amount'] as num?) ?? 0;
    final totalAmount = rawAmount.toDouble();
    final commissionFee = kCommissionIsPercentage
        ? totalAmount * kCommissionRate / 100
        : kCommissionRate;
    final groundRate = (totalAmount - kPlatformFee - commissionFee).clamp(0.0, double.infinity);

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: isOwnerBooking ? "Blocked Slot Details" : "Booking Details",
          size: 16,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green header extension
            Container(
              width: double.infinity,
              color: AppColors.primaryDarkGreen,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
                          color: Colors.white,
                        ),
                        if (bookedOnFormatted.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          AppText(
                            text: "Booked on $bookedOnFormatted",
                            size: 11,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check-in banner
                  _CheckInBanner(isCheckedIn: isCheckedIn, checkedInAt: checkedInFormatted),
                  const SizedBox(height: 16),

                  // Player card or Owner Block Reason
                  if (isOwnerBooking)
                    _SectionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.lock, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppText(
                                    text: "Booked by Owner",
                                    size: 15,
                                    weight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: 3),
                                  AppText(
                                    text: "Reason: ${booking['notes']?.toString().isNotEmpty == true ? booking['notes'] : 'No reason provided'}",
                                    size: 13,
                                    color: Colors.grey.shade600,
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryDarkGreen,
                            backgroundImage:
                                playerImage.isNotEmpty ? NetworkImage(playerImage) : null,
                            child: playerImage.isEmpty
                                ? AppText(
                                    text: playerName.isNotEmpty
                                        ? playerName[0].toUpperCase()
                                        : 'P',
                                    color: Colors.white,
                                    size: 20,
                                    weight: FontWeight.bold,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: playerName,
                                  size: 15,
                                  weight: FontWeight.bold,
                                ),
                                if (memberSinceFormatted.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  AppText(
                                    text: "Member since $memberSinceFormatted",
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  const _SectionLabel(title: "BOOKING DETAILS"),
                  const SizedBox(height: 8),

                  _SectionCard(
                    child: Column(
                      children: [
                        _DetailRow(label: "Court", value: groundName),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Sport",
                          value: sportName,
                          icon: sportIcon(rawSport.isNotEmpty ? rawSport : sportName),
                        ),
                        const _RowDivider(),
                        _DetailRow(label: "Date", value: dateFormatted),
                        const _RowDivider(),
                        _DetailRow(label: "Time", value: timeFormatted),
                        const _RowDivider(),
                        _DetailRow(label: "Booking ID", value: "CB$displayId"),
                      ],
                    ),
                  ),

                  if (!isOwnerBooking) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel(title: "PAYMENT SUMMARY"),
                    const SizedBox(height: 8),

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
                            value: "– ₹${kPlatformFee.toStringAsFixed(0)}",
                            valueColor: AppColors.error,
                          ),
                          if (kCommissionRate > 0) ...[
                            const _RowDivider(),
                            _PaymentRow(
                              label: kCommissionIsPercentage
                                  ? "Commission (${kCommissionRate.toStringAsFixed(kCommissionRate % 1 == 0 ? 0 : 1)}%)"
                                  : "Commission Fee",
                              value: "– ₹${commissionFee.toStringAsFixed(0)}",
                              valueColor: AppColors.error,
                            ),
                          ],
                          const _RowDivider(),
                          _PaymentRow(
                            label: "Taxes & Charges",
                            value: "Included",
                            valueColor: Colors.grey.shade500,
                          ),
                          const _RowDivider(),
                          // You earn row — highlighted
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const AppText(
                                  text: "You Earn",
                                  size: 14,
                                  weight: FontWeight.bold,
                                  color: AppColors.primaryDarkGreen,
                                ),
                                AppText(
                                  text: "₹${groundRate.toStringAsFixed(0)}",
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ],
                            ),
                          ),
                          if (paymentId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            const _RowDivider(),
                            _PaymentRow(
                              label: "Payment Ref.",
                              value: paymentId,
                              valueColor: Colors.grey.shade500,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (isOwnerBooking) ...[
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<SlotCubit>().unbookOwnerSlot(booking['id'].toString());
                          toastification.show(
                            context: context,
                            title: const Text("Slot Unblocked"),
                            type: ToastificationType.success,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue.shade200, width: 1.5),
                          ),
                          elevation: 0,
                        ),
                        child: const AppText(
                          text: "Unblock Slot",
                          size: 16,
                          weight: FontWeight.w700,
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
    final color = isCheckedIn ? AppColors.primaryDarkGreen : const Color(0xFFF57C00);
    final bg = isCheckedIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final border = isCheckedIn ? const Color(0xFF81C784) : const Color(0xFFFFCA28);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isCheckedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: isCheckedIn ? "Checked In" : "Not Yet Checked In",
                  size: 13,
                  weight: FontWeight.w700,
                  color: color,
                ),
                if (isCheckedIn && checkedInAt != null)
                  AppText(
                    text: checkedInAt!,
                    size: 11,
                    color: Colors.grey.shade600,
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
    return AppText(
      text: title,
      size: 11,
      weight: FontWeight.w700,
      color: Colors.grey.shade500,
      letterSpacing: 1.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;

  const _DetailRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: AppText(text: label, size: 13, color: Colors.grey.shade500),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  HugeIcon(icon: icon, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: AppText(
                    text: value,
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.grey.shade800,
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

  const _PaymentRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 13, color: Colors.grey.shade500),
          AppText(
            text: value,
            size: 13,
            weight: FontWeight.w600,
            color: valueColor ?? Colors.grey.shade800,
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
    return Divider(color: Colors.grey.shade100, height: 1, thickness: 1);
  }
}
