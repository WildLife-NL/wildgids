import 'package:flutter/material.dart';
import 'widgets/nav_bar.dart';
import 'models/enums/nav_tab.dart';

void main() {
  runApp(const NavBarPreviewApp());
}

class NavBarPreviewApp extends StatelessWidget {
  const NavBarPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nav Bar Preview',
      home: const NavBarPreviewScreen(),
    );
  }
}

class NavBarPreviewScreen extends StatefulWidget {
  const NavBarPreviewScreen({super.key});

  @override
  State<NavBarPreviewScreen> createState() => _NavBarPreviewScreenState();
}

class _NavBarPreviewScreenState extends State<NavBarPreviewScreen> {
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
              'Tap the tabs below to test',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current tab:',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              currentTab.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
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
