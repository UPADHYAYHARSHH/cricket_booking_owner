import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF57C00); // Amber text
      case 'confirmed':
      case 'completed':
        return const Color(0xFF2E6A4F); // Green text
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red text
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF8E1); // Light amber
      case 'confirmed':
      case 'completed':
        return const Color(0xFFE8F5E9); // Light green
      case 'cancelled':
        return const Color(0xFFFFEBEE); // Light red
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);

    final playerName = booking['player_name'] ?? 'Player Name';
    final groundName = booking['ground_name'] ?? 'Court';
    final sportName = booking['sport_name'] ?? 'Box Cricket'; // Default to something realistic
    
    final slotTimeStr = booking['slot_time']?.toString() ?? booking['created_at']?.toString() ?? '';
    DateTime? slotTime;
    if (slotTimeStr.isNotEmpty) {
      slotTime = DateTime.tryParse(slotTimeStr)?.toLocal();
    }
    
    final date = slotTime != null ? DateFormat('EEEE, MMM d, yyyy').format(slotTime) : 'Date';
    final period = slotTime != null 
        ? "${DateFormat('h:mm a').format(slotTime)} - ${DateFormat('h:mm a').format(slotTime.add(const Duration(hours: 1)))} (1 hr)"
        : 'Time';

    final amount = (booking['amount'] as num?)?.toInt() ?? (booking['total_amount'] as num?)?.toInt() ?? 0;
    


    String displayId = booking['display_id']?.toString() ?? '';
    if (displayId.isEmpty) {
      final fullId = booking['id']?.toString() ?? '';
      displayId = fullId.length > 5 ? fullId.substring(0, 5).toUpperCase() : fullId;
    }

    final playerImage = booking['player_image']?.toString() ?? '';
    final memberSinceStr = booking['member_since']?.toString() ?? '';
    String memberSinceFormat = "Jan 2024";
    if (memberSinceStr.isNotEmpty) {
      final msDate = DateTime.tryParse(memberSinceStr)?.toLocal();
      if (msDate != null) {
        memberSinceFormat = DateFormat('MMM yyyy').format(msDate);
      }
    }
    final pastBookings = booking['past_bookings'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: "Bookings", 
          size: 16, 
          weight: FontWeight.w600, 
          color: Colors.white,
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: AppColors.primaryDarkGreen,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: "Booking #CB$displayId",
                    size: 20,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      text: status[0].toUpperCase() + status.substring(1),
                      color: statusColor,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  
                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryDarkGreen,
                          backgroundImage: playerImage.isNotEmpty ? NetworkImage(playerImage) : null,
                          child: playerImage.isEmpty
                              ? AppText(
                                  text: playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
                                  color: Colors.white,
                                  size: 20,
                                  weight: FontWeight.bold,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: playerName,
                                size: 16,
                                weight: FontWeight.bold,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                text: "CricBook member since $memberSinceFormat",
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.history, size: 14, color: Colors.teal.shade700),
                                  const SizedBox(width: 4),
                                  AppText(
                                    text: "$pastBookings past bookings",
                                    size: 12,
                                    color: Colors.teal.shade700,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // BOOKING DETAILS
                  AppText(
                    text: "BOOKING DETAILS",
                    size: 13,
                    weight: FontWeight.bold,
                    color: Colors.teal.shade700,
                    letterSpacing: 1.2,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Court", groundName),
                  _buildDivider(),
                  _buildDetailRowWithIcon("Sport", sportName, HugeIcons.strokeRoundedCricketBat),
                  _buildDivider(),
                  _buildDetailRow("Date", date), // You might want to format this properly
                  _buildDivider(),
                  _buildDetailRow("Time", period),
                  _buildDivider(),
                  _buildDetailRow("Players", "10 players"), // Mocked count
                  _buildDivider(),
                  _buildDetailRow("Booking ID", "CB$displayId"),
                  
                  const SizedBox(height: 24),
                  
                  // PAYMENT SUMMARY
                  AppText(
                    text: "PAYMENT SUMMARY",
                    size: 13,
                    weight: FontWeight.bold,
                    color: Colors.teal.shade700,
                    letterSpacing: 1.2,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentRow("Ground rate", "₹$amount"),
                  _buildDivider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(text: "Total", size: 15, weight: FontWeight.bold),
                      AppText(
                        text: "₹$amount",
                        size: 15,
                        weight: FontWeight.bold,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ],
                  ),
                  

                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: Colors.grey.shade500),
          AppText(text: value, size: 14, weight: FontWeight.w600, color: Colors.grey.shade800),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: Colors.grey.shade500),
          Row(
            children: [
              HugeIcon(icon: icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              AppText(text: value, size: 14, weight: FontWeight.w600, color: Colors.grey.shade800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: Colors.grey.shade500),
          AppText(text: value, size: 14, weight: FontWeight.w500, color: Colors.grey.shade800),
        ],
      ),
    );
  }

  Widget _buildAdvancePaidRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: Colors.grey.shade500),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText(
              text: value,
              size: 13,
              weight: FontWeight.w500,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }
}
