import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/bookings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _ownerDetails;

  int _monthlyBookings = 0;
  double _monthlyRevenue = 0;
  String _occupancy = "0%";

  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fetchProfileData();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
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
              style: TextStyle(color: AppColors.error),
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
      final ownerRes = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final groundsRes = await Supabase.instance.client
          .from('grounds')
          .select('id')
          .eq('owner_id', userId);

      final List<Object> groundIds = groundsRes
          .map((g) => g['id'] as Object)
          .toList();

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
                if (createdAt == null ||
                    createdAt.compareTo(startOfMonth) < 0) {
                  continue;
                }

                if (booking['status'] != 'cancelled' &&
                    booking['status'] != 'declined') {
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
        _fadeController.forward();
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
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryDarkGreen),
        ),
      );
    }

    final ownerName = _ownerDetails?['owner_name'] ?? "Owner Name";
    final phone = _ownerDetails?['phone'] ?? "No Phone";
    final city = _ownerDetails?['city'] ?? "City";
    final venueName = _ownerDetails?['venue_name'] ?? "Venue Name";

    final createdAtStr = _ownerDetails?['created_at'];
    final memberSince = createdAtStr != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAtStr))
        : "2024";

    final sportsConfig =
        _ownerDetails?['sports_config'] as Map<String, dynamic>? ?? {};
    final sportsList = sportsConfig.keys.map((k) {
      return k
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }).toList();
    final sportsStr = sportsList.isNotEmpty
        ? sportsList.join(', ')
        : 'No sports configured';

    int activeCourts = 0;
    sportsConfig.forEach((key, value) {
      if (value is Map && value['num_courts'] != null) {
        activeCourts += (value['num_courts'] as num).toInt();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDarkGreen,
                    Color(0xFF0A7A4E),
                    AppColors.primaryLightGreen,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32,
                bottom: 48,
              ),
              child: Column(
                children: [
                  // Avatar with ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.primaryLightGreen,
                        child: AppText(
                          text: _getInitials(ownerName),
                          size: 28,
                          weight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: ownerName,
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        text: phone,
                        size: 13,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        text: city,
                        size: 13,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Member badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.goldenYellow,
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          text: "Partner since $memberSince",
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content overlapping header ──
            Transform.translate(
              offset: const Offset(0, -24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPaddingHorizontal,
                  ),
                  child: Column(
                    children: [
                      // Venue Card
                      _buildVenueCard(venueName, sportsStr, activeCourts),
                      const SizedBox(height: AppSizes.lg),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.receipt_long_outlined,
                              value: _monthlyBookings.toString(),
                              label: "Bookings",
                              subLabel: "this month",
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.account_balance_wallet_outlined,
                              value: _formatRevenue(_monthlyRevenue),
                              label: "Revenue",
                              subLabel: "this month",
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.pie_chart_outline,
                              value: _occupancy,
                              label: "Occupancy",
                              subLabel: "rate",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xxl),

                      // Account Settings
                      _buildSettingsSection("Account Settings", [
                        _SettingsItem(
                          icon: Icons.person_outline,
                          title: "Edit Personal Info",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.group_outlined,
                          title: "Manage Staff / Managers",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.account_balance_outlined,
                          title: "Bank & Payout Settings",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          title: "Notification Preferences",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.card_membership_outlined,
                          title: "Subscription & Plan",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.lock_outline,
                          title: "Privacy & Data",
                          onTap: _showComingSoon,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: AppSizes.xxl),

                      // Venue Settings
                      _buildSettingsSection("Venue Settings", [
                        _SettingsItem(
                          icon: Icons.calendar_month_outlined,
                          title: "All Bookings",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingsScreen(),
                            ),
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.edit_location_alt_outlined,
                          title: "Edit Venue Details",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.sports_tennis_outlined,
                          title: "Manage Courts / Grounds",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.sports_baseball_outlined,
                          title: "Update Amenities",
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/amenities-settings',
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.price_change_outlined,
                          title: "Adjust Pricing",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.event_busy_outlined,
                          title: "Holiday / Closure Schedule",
                          onTap: _showComingSoon,
                        ),
                        _SettingsItem(
                          icon: Icons.rule_outlined,
                          title: "Booking Rules",
                          onTap: _showComingSoon,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: AppSizes.xxl),

                      // Logout
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightLg,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const AppText(
                            text: "Log Out",
                            color: AppColors.error,
                            size: 16,
                            weight: FontWeight.w600,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Version
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: AppColors.textSecondaryLight.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AppText(
                            text:
                                "CricBook Owner App v1.0.0  •  Made for India IN",
                            size: 12,
                            color: AppColors.textSecondaryLight.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xxxxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Venue Card ──
  Widget _buildVenueCard(String venueName, String sportsStr, int activeCourts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDarkGreen,
                  AppColors.primaryLightGreen,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLg),
                topRight: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  text: "Venue Overview",
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
                GestureDetector(
                  onTap: _showComingSoon,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: const AppText(
                      text: "Edit",
                      size: 12,
                      color: AppColors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              children: [
                _buildVenueDetailRow(Icons.store_outlined, "Venue", venueName),
                _buildVenueDetailRow(
                  Icons.sports_outlined,
                  "Sports",
                  sportsStr,
                ),
                _buildVenueDetailRow(
                  Icons.grid_view_outlined,
                  "Courts",
                  "$activeCourts active",
                ),
                _buildStatusRow("Status", "Live", true),
                _buildVenueDetailRow(
                  Icons.star_outline,
                  "Rating",
                  "4.7 (38 reviews)",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.primaryDarkGreen),
          const SizedBox(width: AppSizes.sm),
          AppText(text: label, size: 13, color: AppColors.textSecondaryLight),
          const Spacer(),
          Flexible(
            child: AppText(
              text: value,
              size: 13,
              weight: FontWeight.w600,
              align: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isLive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isLive
                ? AppColors.statusConfirmed
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppSizes.sm),
          AppText(text: label, size: 13, color: AppColors.textSecondaryLight),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm + 2,
              vertical: AppSizes.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.statusConfirmedBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: AppColors.statusConfirmed.withValues(alpha: 0.3),
              ),
            ),
            child: AppText(
              text: value,
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.statusConfirmed,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Card ──
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.lg,
        horizontal: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.slotAvailableBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primaryLightGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDarkGreen),
          const SizedBox(height: AppSizes.sm),
          AppText(
            text: value,
            size: 20,
            weight: FontWeight.w800,
            color: AppColors.primaryDarkGreen,
          ),
          const SizedBox(height: AppSizes.xs),
          AppText(
            text: label,
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.primaryDarkGreen,
          ),
          AppText(
            text: subLabel,
            size: 10,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  // ── Settings Section ──
  Widget _buildSettingsSection(String title, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.xl,
              AppSizes.xl,
              AppSizes.xl,
              AppSizes.sm,
            ),
            child: AppText(
              text: title,
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          ...items.map((item) {
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.vertical(
                bottom: item.isLast
                    ? const Radius.circular(AppSizes.radiusLg)
                    : Radius.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md + 2,
                ),
                decoration: item.isLast
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.slotAvailableBg,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        item.icon,
                        size: AppSizes.iconSm,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: item.title,
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            AppText(
                              text: item.subtitle!,
                              size: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondaryLight.withValues(
                        alpha: 0.5,
                      ),
                    ),
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
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
}
