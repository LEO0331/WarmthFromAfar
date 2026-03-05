import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/request_page.dart';
import 'views/tracking_page.dart';
import 'views/admin/admin_login.dart'; // 需建立此檔案處理 Auth

// main.dart 修改
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const WanderStampApp(),
    ),
  );
}


class WanderStampApp extends StatelessWidget {
  const WanderStampApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      routes: {
        '/': (context) => const MainNavigator(),
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _idx = 0;
  final _pages = [const RequestPage(), const TrackingPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📮 WanderStamp")),
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.send_rounded), label: "Request"),
          NavigationDestination(icon: Icon(Icons.history_edu_rounded), label: "Track"),
        ],
      ),
    );
  }
}
