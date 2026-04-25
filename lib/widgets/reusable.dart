import 'package:budget_buddy/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:budget_buddy/models/all_transactions.dart';
import 'package:budget_buddy/screens/stats_chats/stats_chats.dart';
import 'package:budget_buddy/screens/profile2/profile2.dart';

class CustomNavBar extends StatelessWidget {
  final int activeIndex;
  const CustomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: activeIndex,
      selectedItemColor: Color(0XFF578ADD),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      unselectedItemColor: Color(0XFF4B5563),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      onTap: (int index) {
        if (index == 0) {
          Navigator.pushNamed(context, HomeScreen.id);
        }
        if (index == 1) {
          Navigator.pushNamed(context, AllTransactions.id);
        }
        if (index == 2) {
          Navigator.pushNamed(context, StatsPage.id);
        }
        if (index == 3) {
          Navigator.pushNamed(context, ProfilePage2.id);
        }
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
    );
  }
}
