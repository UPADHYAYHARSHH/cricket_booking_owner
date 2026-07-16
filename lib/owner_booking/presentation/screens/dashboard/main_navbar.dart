import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/slots/slots_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/profile_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/grounds/grounds_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/scan_ticket/scan_ticket_screen.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const DashboardScreen(),
    const SlotsScreen(),
    const GroundsScreen(),
    const ProfileScreen(),
  ];

  void _openScanner() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        floatingActionButton: _ScanFab(onTap: _openScanner),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: Colors.white,
          elevation: 12,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: HugeIcons.strokeRoundedHome01,
                  label: 'Home',
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  label: 'Slots',
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 64), // reserved space for the notch + scan FAB
                _NavItem(
                  icon: HugeIcons.strokeRoundedCricketBat,
                  label: 'Grounds',
                  selected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: HugeIcons.strokeRoundedUser,
                  label: 'Profile',
                  selected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The center scan button: raised above the bar and nested in its notch so
/// the owner can jump straight into ticket scanning from anywhere.
class _ScanFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.3 + 0.2 * _controller.value),
                  blurRadius: 8 + 4 * _controller.value,
                  spreadRadius: 2 + 2 * _controller.value,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: widget.onTap,
              backgroundColor: AppColors.primaryDarkGreen,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final color = Color.lerp(Colors.grey.shade400, AppColors.primaryDarkGreen, value)!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (0.15 * value),
                  child: HugeIcon(icon: icon, color: color, size: 22),
                ),
                const SizedBox(height: 4),
                AppText(
                  text: label,
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
