import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/postcard.dart';
import '../widgets/postcard_card.dart'; // 使用我們寫好的漂亮卡片
import 'tracking_map_view.dart';       // 剛才建立的地圖視圖

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  bool _isMapView = false; // 切換狀態

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 在內層加入一個小 AppBar 用於切換視圖
      appBar: AppBar(
        title: const Text("Journey Tracker", style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _isMapView ? "Switch to List" : "Switch to Map",
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: StreamBuilder<List<Postcard>>(
        stream: FirebaseService().getPublicPostcards(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allPostcards = snapshot.data!;
          
          if (_isMapView) {
            // 顯示地圖視圖
            return WanderMap(postcards: allPostcards);
          } else {
            // 顯示原本的列表視圖
            if (allPostcards.isEmpty) {
              return const Center(child: Text("No postcards yet. Be the first!"));
            }
            return ListView.builder(
              itemCount: allPostcards.length,
              itemBuilder: (context, i) {
                return PostcardCard(postcard: allPostcards[i]);
              },
            );
          }
        },
      ),
    );
  }
}
