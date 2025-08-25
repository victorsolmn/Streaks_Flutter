import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/app_theme.dart';
import 'home_screen_new.dart';
import 'progress_screen_new.dart';
import 'nutrition_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenNew(),
    const ProgressScreenNew(),
    const NutritionScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.trending_up_outlined),
      activeIcon: Icon(Icons.trending_up_rounded),
      label: 'Progress',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_dining_outlined),
      activeIcon: Icon(Icons.local_dining_rounded),
      label: 'Nutrition',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/images/streaker_logo.svg',
          colorFilter: ColorFilter.mode(
            AppTheme.textSecondary,
            BlendMode.srcIn,
          ),
        ),
      ),
      activeIcon: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/images/streaker_logo.svg',
          colorFilter: ColorFilter.mode(
            AppTheme.primaryAccent,
            BlendMode.srcIn,
          ),
        ),
      ),
      label: 'Streaker',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_circle_outlined),
      activeIcon: Icon(Icons.account_circle_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: _bottomNavItems,
        ),
      ),
    );
  }
}