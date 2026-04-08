import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'views/received_confirmation_page.dart';
import 'views/request_page.dart';
import 'views/tracking_page.dart';
import 'views/admin/admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/admin-login') {
          return MaterialPageRoute(builder: (_) => const AdminLoginPage());
        }
        if (settings.name == '/received') {
          return MaterialPageRoute(
            builder: (_) => const ReceivedConfirmationPage(),
          );
        }

        int initialTab = 0;
        String initialTrackQuery = "";
        final args = settings.arguments;
        if (args is Map) {
          initialTab = (args['initialTab'] as int?) ?? 0;
          initialTrackQuery = (args['initialTrackQuery'] as String?) ?? "";
        }

        return MaterialPageRoute(
          builder: (_) => MainNavigator(
            initialIndex: initialTab,
            initialTrackingQuery: initialTrackQuery,
          ),
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  final int initialIndex;
  final String initialTrackingQuery;

  const MainNavigator({
    super.key,
    this.initialIndex = 0,
    this.initialTrackingQuery = "",
  });

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  late int _idx;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _pages = [
      const RequestPage(),
      TrackingPage(initialSearchQuery: widget.initialTrackingQuery),
      const ReceivedConfirmationPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📮 WanderStamp"), centerTitle: true),
      body: IndexedStack(
        // 使用 IndexedStack 可以保留頁面狀態
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
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_rounded),
            label: "Received",
          ),
        ],
      ),
    );
  }
}
