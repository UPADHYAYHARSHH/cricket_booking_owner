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
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ScanTicketScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: _screens[_selectedIndex],
        ),
        floatingActionButton: _ScanFab(onTap: _openScanner),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: AppColors.surfaceLight,
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
                const SizedBox(width: 64),
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

class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.white,
          size: 28,
        ),
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
            final color = Color.lerp(
              AppColors.textSecondaryLight,
              AppColors.primaryDarkGreen,
              value,
            )!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (0.15 * value),
                  child: HugeIcon(
                    icon: icon as dynamic,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  text: label,
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: selected ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryDarkGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
