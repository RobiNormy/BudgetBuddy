import 'package:flutter/material.dart';
import 'package:budget_buddy/models/all_transactions.dart';
import 'package:budget_buddy/screens/home/home.dart';
import 'package:budget_buddy/screens/stats_chats/stats_chats.dart';
import 'package:budget_buddy/screens/profile2/profile2.dart';
import 'package:budget_buddy/screens/splash/splash_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  static const String id = "main_wrapper";

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const AllTransactions(),
      const StatsPage(),
      const ProfilePage2(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          enableFeedback: false,
          selectedItemColor: Color(0XFF578ADD),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          unselectedItemColor: Color(0XFF4B5563),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt),
              label: "Transactions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: "Stats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
