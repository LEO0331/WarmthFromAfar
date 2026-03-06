import 'package:flutter/material.dart';
import 'request_page.dart';
import 'tracking_page.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});
  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _idx = 0;
  final List<Widget> _pages = [const RequestPage(), const TrackingPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.send_rounded),
            label: "Request",
            selectedIcon: Icon(Icons.mail_rounded, color: Colors.amber),
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: "Track",
            selectedIcon: Icon(Icons.map_rounded, color: Colors.amber),
          ),
        ],
      ),
    );
  }
}
