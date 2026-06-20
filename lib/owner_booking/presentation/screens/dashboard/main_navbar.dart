import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/bookings_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/slots/slots_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/profile_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/grounds/grounds_screen.dart';

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
    const BookingsScreen(),
    const GroundsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryDarkGreen;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedHome01,
                  color: _selectedIndex == 0
                      ? primaryColor
                      : Colors.grey.shade400,
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: _selectedIndex == 1
                      ? primaryColor
                      : Colors.grey.shade400,
                ),
                label: "Slots",
              ),
              BottomNavigationBarItem(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedTaskDone01,
                  color: _selectedIndex == 2
                      ? primaryColor
                      : Colors.grey.shade400,
                ),
                label: "Bookings",
              ),
              BottomNavigationBarItem(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCricketBat,
                  color: _selectedIndex == 3
                      ? primaryColor
                      : Colors.grey.shade400,
                ),
                label: "Grounds",
              ),
              BottomNavigationBarItem(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: _selectedIndex == 4
                      ? primaryColor
                      : Colors.grey.shade400,
                ),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final dynamic icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: AppText(text: title, size: 18, weight: FontWeight.w700),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            AppText(text: "$title Coming Soon", size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
