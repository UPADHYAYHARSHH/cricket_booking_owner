import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/utils/booking_financial_util.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

class TodayBookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;

  const TodayBookingCard({super.key, required this.booking});

  @override
  State<TodayBookingCard> createState() => _TodayBookingCardState();
}

class _TodayBookingCardState extends State<TodayBookingCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isProcessing = false;

  String _formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _simplifyPeriod(String period) {
    if (!period.contains(',')) return period;
    
    final parts = period.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return period;
    
    List<String> merged = [];
    String? currentStart;
    String? currentEnd;
    
    for (final p in parts) {
      final range = p.split('-').map((e) => e.trim()).toList();
      if (range.length != 2) return period;
      
      final start = range[0];
      final end = range[1];
      
      if (currentStart == null) {
        currentStart = start;
        currentEnd = end;
      } else {
        if (currentEnd == start) {
          currentEnd = end;
        } else {
          merged.add('$currentStart - $currentEnd');
          currentStart = start;
          currentEnd = end;
        }
      }
    }
    if (currentStart != null) {
      merged.add('$currentStart - $currentEnd');
    }
    
    return merged.join(', ');
  }

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client.rpc('approve_booking', params: {
        'p_booking_id': widget.booking['id'].toString()
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Approved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDecline() async {
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client.rpc('delete_or_expire_booking', params: {
        'p_booking_id': widget.booking['id'].toString(),
        'p_reason': 'declined_by_owner'
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Declined')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.booking['status'] ?? 'pending').toString();
    final playerName = widget.booking['player_name'] ?? 'Customer';
    final groundName = widget.booking['ground_name'] ?? 'Court';
    final rawPeriod = (widget.booking['period'] ?? 'Time').toString();
    String period = rawPeriod;
    
    String dateLabel = "Date";
    final slotTimeStr = widget.booking['slot_time']?.toString() ?? widget.booking['created_at']?.toString() ?? '';
    if (slotTimeStr.isNotEmpty) {
      try {
        final d = DateTime.parse(slotTimeStr).toLocal();
        dateLabel = DateFormat('d MMM').format(d);
      } catch (_) {}
    }

    if (rawPeriod.contains('|')) {
      final parts = rawPeriod.split('|');
      final times = parts[1].replaceAll(',', ', ');
      period = "$dateLabel - $times";
    } else {
      String simplified = _simplifyPeriod(rawPeriod);
      simplified = simplified.replaceAll(RegExp(r'^(Day|Night|Midnight)\s*-\s*'), '');
      period = "$dateLabel - $simplified";
    }
    final sportName = _formatLabel((widget.booking['sport_name'] ?? 'Sport').toString());
    final ownerEarnings = BookingFinancialUtil.getOwnerEarnings(widget.booking);
    final displayAmount = BookingFinancialUtil.formatAmount(ownerEarnings);
    
    final slotTime = widget.booking['slot_time']?.toString() ?? widget.booking['created_at']?.toString() ?? '';
    String dateStr = '';
    if (slotTime.isNotEmpty) {
      try {
        final d = DateTime.parse(slotTime).toLocal();
        final now = DateTime.now();
        if (d.year != now.year || d.month != now.month || d.day != now.day) {
           dateStr = "${d.day}/${d.month} • ";
        }
      } catch (_) {}
    }

    final isRequested = status == 'requested' || status == 'pending';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(booking: widget.booking),
        ),
      ),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.bookingStatusBorderColor(status),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bookingStatusBgColor(status),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: sportIcon((widget.booking['sport_name'] ?? '').toString()),
                              size: 18,
                              color: AppColors.bookingStatusColor(status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: playerName,
                                size: 15,
                                weight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                text: "$groundName • $dateStr$period",
                                size: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bookingStatusBgColor(status),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: AppText(
                      text: _formatLabel(status),
                      color: AppColors.bookingStatusColor(status),
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    _InfoChip(
                      icon: HugeIcons.strokeRoundedMoneyBag01,
                      text: "₹$displayAmount",
                    ),
                    const SizedBox(width: 16),
                    _InfoChip(
                      icon: sportIcon((widget.booking['sport_name'] ?? '').toString()),
                      text: sportName,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailsScreen(booking: widget.booking),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            text: "Details",
                            color: AppColors.primaryDarkGreen,
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isRequested) ...[
                const SizedBox(height: 12),
                _isProcessing
                  ? const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                  : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        AppText(
          text: text,
          size: 12,
          color: AppColors.textSecondaryLight,
          weight: FontWeight.w500,
        ),
      ],
    );
  }
}

