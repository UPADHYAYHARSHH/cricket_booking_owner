import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/bookings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ownerDetails;
  
  int _monthlyBookings = 0;
  double _monthlyRevenue = 0;
  String _occupancy = "0%";

  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text(
              "Log Out",
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchProfileData() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // 1. Fetch Owner Details
      final ownerRes = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // 2. Fetch Monthly Stats via Stream
      final groundsRes = await Supabase.instance.client
          .from('grounds')
          .select('id')
          .eq('owner_id', userId);
          
      final List<Object> groundIds = groundsRes.map((g) => g['id'] as Object).toList();

      if (groundIds.isNotEmpty) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

        _bookingsSubscription = Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .inFilter('ground_id', groundIds)
            .listen((bookingsRes) {
              int bookingsCount = 0;
              double revenue = 0;
              for (var booking in bookingsRes) {
                final createdAt = booking['created_at'];
                if (createdAt == null || createdAt.compareTo(startOfMonth) < 0) continue;
                
                if (booking['status'] != 'cancelled' && booking['status'] != 'declined') {
                  bookingsCount++;
                  if (booking['amount'] != null) {
                    revenue += double.parse(booking['amount'].toString());
                  }
                }
              }
              if (mounted) {
                setState(() {
                  _monthlyBookings = bookingsCount;
                  _monthlyRevenue = revenue;
                  _occupancy = bookingsCount > 0 ? "87%" : "0%"; 
                });
              }
            });
      }

      if (mounted) {
        setState(() {
          _ownerDetails = ownerRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "O";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K";
    }
    return "₹${amount.toStringAsFixed(0)}";
  }

  void _showComingSoon() {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text("Coming Soon"),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDarkGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final ownerName = _ownerDetails?['owner_name'] ?? "Owner Name";
    final phone = _ownerDetails?['phone'] ?? "No Phone";
    final city = _ownerDetails?['business_city'] ?? "City";
    final venueName = _ownerDetails?['venue_name'] ?? "Venue Name";
    
    final createdAtStr = _ownerDetails?['created_at'];
    final memberSince = createdAtStr != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAtStr)) 
        : "2024";

    // Format Sports
    final sportsConfig = _ownerDetails?['sports_config'] as Map<String, dynamic>? ?? {};
    final sportsList = sportsConfig.keys.map((k) {
      return k.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }).toList();
    final sportsStr = sportsList.isNotEmpty ? sportsList.join(', ') : 'No sports configured';

    // Count Active Courts
    int activeCourts = 0;
    sportsConfig.forEach((key, value) {
      if (value is Map && value['num_courts'] != null) {
        activeCourts += (value['num_courts'] as num).toInt();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primaryDarkGreen,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF6BBD90), // Light green from mockup
                    child: AppText(
                      text: _getInitials(ownerName),
                      size: 28,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: ownerName,
                    size: 22,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "$phone • $city",
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge("⭐ Partner since $memberSince", const Color(0xFFF57C00)),
                    ],
                  ),
                ],
              ),
            ),

            // Overlapping Card & Content
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Venue Overview Card
                    _buildVenueCard(venueName, sportsStr, activeCourts),
                    const SizedBox(height: 16),
                    
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(_monthlyBookings.toString(), "Bookings this\nmonth")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(_formatRevenue(_monthlyRevenue), "Revenue")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(_occupancy, "Occupancy")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Settings
                    _buildSettingsSection("Account Settings", [
                      _SettingsItem("Edit Personal Info", onTap: _showComingSoon),
                      _SettingsItem("Manage Staff / Managers", onTap: _showComingSoon),
                      _SettingsItem("Bank & Payout Settings", onTap: _showComingSoon),
                      _SettingsItem("Notification Preferences", onTap: _showComingSoon),
                      _SettingsItem("Subscription & Plan", onTap: _showComingSoon),
                      _SettingsItem("Privacy & Data", onTap: _showComingSoon, isLast: true),
                    ]),
                    const SizedBox(height: 24),

                    // Venue Settings
                    _buildSettingsSection("Venue Settings", [
                      _SettingsItem("All Bookings", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()))),
                      _SettingsItem("Edit Venue Details", onTap: _showComingSoon),
                      _SettingsItem("Manage Courts / Grounds", onTap: _showComingSoon),
                      _SettingsItem("Update Amenities", onTap: () => Navigator.pushNamed(context, '/amenities-settings')),
                      _SettingsItem("Adjust Pricing", onTap: _showComingSoon),
                      _SettingsItem("Holiday / Closure Schedule", onTap: _showComingSoon),
                      _SettingsItem("Booking Rules", onTap: _showComingSoon, isLast: true),
                    ]),
                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _confirmLogout(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFA3A3), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const AppText(
                          text: "Log Out",
                          color: Color(0xFFE53935),
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: "CricBook Owner App v1.0.0 • Made for India IN",
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: AppText(text: text, size: 12, weight: FontWeight.w600, color: Colors.white),
    );
  }

  Widget _buildVenueCard(String venueName, String sportsStr, int activeCourts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(text: "Venue Overview", size: 16, weight: FontWeight.w700),
              GestureDetector(
                onTap: _showComingSoon,
                child: const AppText(text: "Edit", size: 14, color: Colors.teal, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVenueRow("Venue", venueName),
          _buildVenueRow("Sports", sportsStr),
          _buildVenueRow("Courts", "$activeCourts active"),
          _buildVenueRow("Status", "• Live", isStatus: true),
          _buildVenueRow("Rating", "⭐ 4.7 (38 reviews)"),
        ],
      ),
    );
  }

  Widget _buildVenueRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: Colors.grey.shade500),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: AppText(text: value, size: 12, weight: FontWeight.w600, color: Colors.green.shade700),
            )
          else
            AppText(text: value, size: 14, weight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAF5), // Light green tint from mockup
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AppText(text: value, size: 22, weight: FontWeight.w800, color: AppColors.primaryDarkGreen),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: AppText(text: label, size: 12, color: AppColors.primaryDarkGreen.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppText(text: title, size: 16, weight: FontWeight.w700),
          ),
          ...items.map((item) {
            return InkWell(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: item.isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(text: item.title, size: 14, weight: FontWeight.w500),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            AppText(
                              text: item.subtitle!,
                              size: 11,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  _SettingsItem(this.title, {this.subtitle, required this.onTap, this.isLast = false});
}
