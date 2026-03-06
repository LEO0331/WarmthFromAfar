import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/postcard.dart';
import '../widgets/postcard_card.dart';
import 'tracking_map_view.dart'; // 確保此檔案存在

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _searchQuery = "";
  bool _showOnlySentOrReceived = false;
  bool _isMapView = false; // 新增：控制目前是地圖還是列表

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 在頂部加入切換按鈕
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _isMapView ? "Switch to List" : "Switch to Map",
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Postcard>>(
        stream: FirebaseService().getPublicPostcards(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allData = snapshot.data!;

          // 如果切換到地圖模式
          if (_isMapView) {
            return WanderMap(postcards: allData);
          }

          // 否則顯示列表模式（包含統計與搜尋）
          return _buildListView(allData);
        },
      ),
    );
  }

  // 封裝原本的列表邏輯
  Widget _buildListView(List<Postcard> allData) {
    // 1. 計算統計數字
    final sentCount = allData.where((p) => p.status == 'sent').length;
    final receivedCount = allData.where((p) => p.status == 'received').length;
    final pendingCount = allData.where((p) => p.status == 'pending').length;

    // 2. 根據過濾器與搜尋過濾資料
    final filteredData = allData.where((p) {
      final String name = p.receiverName.toLowerCase();
      final String id = p.id.toUpperCase();
      final String query = _searchQuery.toUpperCase();

      // 修正：支援暱稱搜尋或 ID 後四碼搜尋
      final matchesSearch = name.contains(query.toLowerCase()) || 
                            id.endsWith(query.replaceAll("W-", ""));

      if (_showOnlySentOrReceived) {
        return matchesSearch && (p.status == 'sent' || p.status == 'received');
      }
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        // --- 統計數字區塊 ---
        _buildStatisticsHeader(sentCount, receivedCount, pendingCount),

        // --- 搜尋與過濾控制列 ---
        _buildFilterBar(),

        // --- 列表內容 ---
        Expanded(
          child: filteredData.isEmpty
              ? const Center(child: Text("No matching records found."))
              : ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, i) => PostcardCard(postcard: filteredData[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsHeader(int sent, int received, int pending) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.amber.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("✈️ Sent", sent.toString(), Colors.green),
          _statItem("❤️ Received", received.toString(), Colors.pink),
          _statItem("⏳ Pending", pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search nickname or ID (e.g. 8A2C)",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          Row(
            children: [
              const Text("View Sent/Received Only", style: TextStyle(fontSize: 13)),
              Switch(
                value: _showOnlySentOrReceived,
                onChanged: (val) => setState(() => _showOnlySentOrReceived = val),
                activeThumbColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
