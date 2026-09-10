import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/support/owner_support_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/support/owner_support_state.dart';
import 'owner_support_chat_screen.dart';

class OwnerHelpSupportScreen extends StatelessWidget {
  const OwnerHelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat(BuildContext context, {String? query}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OwnerSupportCubit>(),
          child: OwnerSupportChatScreen(initialQuery: query),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => OwnerSupportCubit()..initSupport(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
              elevation: 0.5,
              title: Text(
                'Partner Help & Support',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF25D366),
                    size: 22,
                  ),
                  tooltip: 'WhatsApp Partner Support',
                  onPressed: () => _launchUrl(
                    'https://wa.me/919876543210?text=Hi%20TurfPro%20Partner%20Support,%20I%20need%20assistance',
                  ),
                ),
              ],
            ),
            body: BlocBuilder<OwnerSupportCubit, OwnerSupportState>(
              builder: (context, state) {
                Map<String, dynamic>? ownerContext;
                if (state is OwnerSupportLoaded) {
                  ownerContext = state.ownerContext;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Hero AI Assistant Banner
                    _buildHeroBanner(context, isDark),

                    const SizedBox(height: 18),

                    // Venue Context Summary
                    if (ownerContext != null) ...[
                      _buildOwnerContextCard(context, ownerContext, isDark),
                      const SizedBox(height: 20),
                    ],

                    // FAQ Topics for Turf Venue Owners
                    Text(
                      'Partner Support Topics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFaqTile(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'When do payouts get settled into my bank?',
                      subtitle: 'T+1 / T+2 settlement cycle, bank holidays, and statements',
                      query: 'When are payouts settled to my bank account?',
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.timer_outlined,
                      title: 'How does the 45-minute booking approval timer work?',
                      subtitle: 'Auto-expiry, player notifications, and calendar holding',
                      query: 'Explain the 45-minute booking approval requirement and countdown timer',
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.block_rounded,
                      title: 'How do I block slots for maintenance or rain?',
                      subtitle: 'Mark individual or recurring slots unavailable',
                      query: 'How do I block slots for rain, tournament, or ground maintenance?',
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.bolt_rounded,
                      title: 'Instant Booking vs Approval Mode',
                      subtitle: 'Difference between instant confirmations and manual review',
                      query: 'What is the difference between instant booking and approval mode?',
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.report_problem_outlined,
                      title: 'Player no-show or check-in disputes',
                      subtitle: 'Rules for no-shows, cancellation charges, and refunds',
                      query: 'What happens when a customer does not show up for their slot?',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 22),

                    // Direct Contact Options
                    Text(
                      'Direct Contact',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildContactTile(
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp Partner Helpline',
                      subtitle: '+91 98765 43210 (Mon-Sun, 9 AM - 11 PM)',
                      onTap: () => _launchUrl('https://wa.me/919876543210?text=Hi%20TurfPro%20Partner%20Desk'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildContactTile(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: AppColors.primaryDarkGreen,
                      title: 'Priority Partner Desk',
                      subtitle: 'Toll-free 1800-TURF-PRO (9 AM - 9 PM)',
                      onTap: () => _launchUrl('tel:18008873776'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildContactTile(
                      icon: Icons.email_outlined,
                      iconColor: Colors.blueAccent,
                      title: 'Partner Relations Email',
                      subtitle: 'partners@turfpro.in (Response within 12h)',
                      onTap: () => _launchUrl('mailto:partners@turfpro.in?subject=Partner%20Support%20Request'),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F3820), const Color(0xFF062012)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'TurfPro Partner AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF00E676)),
                    SizedBox(width: 4),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Have questions regarding your slot bookings, 45-minute approval window, or payout cycle? Get instant automated assistance.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(context),
              icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF1B5E20)),
              label: const Text(
                'Chat with Partner Assistant',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerContextCard(BuildContext context, Map<String, dynamic> ownerContext, bool isDark) {
    final totalGrounds = ownerContext['totalGrounds'] ?? 0;
    final activeGrounds = ownerContext['activeGrounds'] ?? 0;
    final ownerData = ownerContext['owner'] as Map<String, dynamic>?;
    final venueName = ownerData?['venue_name']?.toString() ??
        ownerData?['business_name']?.toString() ??
        'Your Venue';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLightGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stadium_rounded,
              color: AppColors.primaryDarkGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venueName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalGrounds.toString() + ' court(s) • ' + activeGrounds.toString() + ' active',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openChat(context, query: 'Show details for my grounds and slot statuses'),
            child: const Text(
              'Ask AI',
              style: TextStyle(
                color: AppColors.primaryDarkGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String query,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLightGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryDarkGreen, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        onTap: () => _openChat(context, query: query),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        onTap: onTap,
      ),
    );
  }
}
