import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/screens/my_sports_screen.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    _PlaceholderScreen(
      title: "Dashboard",
      icon: HugeIcons.strokeRoundedDashboardSquare01,
    ),
    _PlaceholderScreen(
      title: "Bookings",
      icon: HugeIcons.strokeRoundedCalendar01,
    ),
    const MySportsScreen(),
    _PlaceholderScreen(title: "Profile", icon: HugeIcons.strokeRoundedUser),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B00);

    return Scaffold(
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
                icon: HugeIcons.strokeRoundedDashboardSquare01,
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
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedFootball,
                color: _selectedIndex == 2
                    ? primaryColor
                    : Colors.grey.shade400,
              ),
              label: "Sports",
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: _selectedIndex == 3
                    ? primaryColor
                    : Colors.grey.shade400,
              ),
              label: "Profile",
            ),
          ],
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
