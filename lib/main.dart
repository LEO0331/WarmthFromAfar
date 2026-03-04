import 'package:flutter/material.dart';

void main() => runApp(const PostcardApp());

class PostcardApp extends StatelessWidget {
  const PostcardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _index = 0;
  final _pages = [const RequestPage(), const TrackingPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📮 Random Warmth Postcard")),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.send), label: "Request"),
          NavigationDestination(icon: Icon(Icons.map), label: "Track"),
        ],
      ),
    );
  }
}

// 頁面 A: 請求表單
class RequestPage extends StatelessWidget {
  const RequestPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Receive a surprise from my journey.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(decoration: const InputDecoration(labelText: "Name / Nickname", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextFormField(maxLines: 3, decoration: const InputDecoration(labelText: "Full Address", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          const Text("What message do you need?"),
          Wrap(
            spacing: 8,
            children: ["Inspiration", "Comfort", "Travel Story", "Daily Life"].map((topic) => ChoiceChip(label: Text(topic), selected: false)).toList(),
          ),
          const SizedBox(height: 30),
          Center(child: ElevatedButton(onPressed: () {}, child: const Text("Request Postcard"))),
        ],
      ),
    );
  }
}

// 頁面 B: 追蹤列表
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.mark_as_unread),
        title: Text("To: Stranger in London"),
        subtitle: const Text("Status: Sent from Tokyo on 2024/05/20"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
