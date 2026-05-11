import 'package:flutter/material.dart';
import 'package:budget_buddy/models/all_transactions.dart';
import 'package:budget_buddy/screens/home/home.dart';
import 'package:budget_buddy/screens/stats_chats/stats_chats.dart';
import 'package:budget_buddy/screens/profile2/profile2.dart';
import 'package:budget_buddy/widgets/liquid_glass_nav_bar.dart';

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
      bottomNavigationBar: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: LiquidGlassNavBar(
            items: [
              LiquidGlassNavBarItem(icon: Icons.home_outlined, label: "Home"),
              LiquidGlassNavBarItem(
                icon: Icons.receipt_long_outlined,
                label: "Transactions",
              ),
              LiquidGlassNavBarItem(
                icon: Icons.bar_chart_outlined,
                label: "Stats",
              ),
              LiquidGlassNavBarItem(
                icon: Icons.person_outline,
                label: "Profile",
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
