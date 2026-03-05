import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // 新增
import 'firebase_options.dart';          // 新增
import 'providers/auth_provider.dart';
import 'views/request_page.dart';
import 'views/tracking_page.dart';
import 'views/admin/admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // 使用 MultiProvider 或單一 Provider 包裹 App
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
      title: 'WanderStamp',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.amber,
      ),
      // 設定初始路由
      initialRoute: '/',
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
  final List<Widget> _pages = [
    const RequestPage(), 
    const TrackingPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📮 WanderStamp"),
        centerTitle: true,
      ),
      body: IndexedStack( // 使用 IndexedStack 可以保留頁面狀態
        index: _idx,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.send_rounded), 
            label: "Request",
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_rounded), 
            label: "Track",
          ),
        ],
      ),
    );
  }
}
