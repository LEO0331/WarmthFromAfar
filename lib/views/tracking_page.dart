import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/postcard.dart';
import '../widgets/postcard_card.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _searchQuery = "";
  bool _showOnlySentOrReceived = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Postcard>>(
      stream: FirebaseService().getPublicPostcards(), // 建議在此處 limit(50) 或不限
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allData = snapshot.data!;

        // 1. 計算統計數字
        final sentCount = allData.where((p) => p.status == 'sent').length;
        final receivedCount = allData
            .where((p) => p.status == 'received')
            .length;
        final pendingCount = allData.where((p) => p.status == 'pending').length;

        // 2. 根據過濾器與搜尋過濾資料
        final filteredData = allData.where((p) {
          // ignore: dead_null_aware_expression, dead_code
          final String name = p.receiverName ?? "";
          final id = p.id.toUpperCase();
          final String searchKey = _searchQuery;

          final matchesSearch =
              name.contains(searchKey.toLowerCase()) ||
              id.endsWith(searchKey.replaceAll("W-", ""));

          if (_showOnlySentOrReceived) {
            return matchesSearch &&
                (p.status == 'sent' || p.status == 'received');
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
                      itemBuilder: (context, i) =>
                          PostcardCard(postcard: filteredData[i]),
                    ),
            ),
          ],
        );
      },
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
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
              hintText: "Search your nickname...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          Row(
            children: [
              const Text(
                "View Sent/Received Only",
                style: TextStyle(fontSize: 13),
              ),
              Switch(
                value: _showOnlySentOrReceived,
                onChanged: (val) =>
                    setState(() => _showOnlySentOrReceived = val),
                activeThumbColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
