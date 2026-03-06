import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/postcard.dart';

class WanderMap extends StatelessWidget {
  final List<Postcard> postcards;

  const WanderMap({super.key, required this.postcards});

  @override
  Widget build(BuildContext context) {
    // 1. 篩選出已經寄出 (status == 'sent' 或 'received') 且具有座標的資料
    final markersData = postcards
        .where((p) => p.lat != null && p.lng != null)
        .toList();

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          // 預設中心點 (世界地圖中心)
          initialCenter: const LatLng(20.0, 0.0),
          initialZoom: 2.5,
          // 限制最小縮放，避免地圖重複
          minZoom: 2.0,
          maxZoom: 18.0,
        ),
        children: [
          // 2. 設定圖層 (OpenStreetMap 免費圖資)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourname.wanderstamp',
          ),
          
          // 3. 渲染標記圖層
          MarkerLayer(
            markers: markersData.map((p) {
              return Marker(
                point: LatLng(p.lat!, p.lng!),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showPostcardInfo(context, p),
                  child: _buildMarkerIcon(p.status),
                ),
              );
            }).toList(),
          ),
          
          // 4. 加上版權宣告 (OSM 規範)
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }

  // 根據狀態顯示不同標記圖標
  Widget _buildMarkerIcon(String status) {
    return Column(
      children: [
        Icon(
          status == 'received' ? Icons.favorite : Icons.location_on,
          color: status == 'received' ? Colors.pink : Colors.amber.shade700,
          size: 35,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text("Warmth", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // 點擊標記顯示簡短資訊
  void _showPostcardInfo(BuildContext context, Postcard p) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("📮 Sent from ${p.sentCity ?? 'Unknown City'}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Topic: ${p.topic}"),
            Text("Recipient: ${p.receiverName}"),
            const SizedBox(height: 10),
            Text("Status: ${p.status.toUpperCase()}", 
              style: TextStyle(color: p.status == 'received' ? Colors.pink : Colors.green)),
          ],
        ),
      ),
    );
  }
}
