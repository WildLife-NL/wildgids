import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart';
import '../models/enums/nav_tab.dart';

class NavBarDemo extends StatefulWidget {
  const NavBarDemo({super.key});

  @override
  State<NavBarDemo> createState() => _NavBarDemoState();
}

class _NavBarDemoState extends State<NavBarDemo> {
  NavTab currentTab = NavTab.soorten;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nav Bar Preview'),
        backgroundColor: const Color(0xFF6B8E23),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Current tab:',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              currentTab.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B8E23),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentTab: currentTab,
        onTabSelected: (tab) {
          setState(() {
            currentTab = tab;
          });
        },
      ),
    );
  }
}
