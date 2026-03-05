import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/postcard.dart';
import '../services/firebase_service.dart';

class PostcardCard extends StatelessWidget {
  final Postcard postcard;
  final bool isAdminView;

  const PostcardCard({super.key, required this.postcard, this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _getStatusIcon(),
        title: Text("To: ${postcard.receiverName}"),
        subtitle: Text(
          postcard.status == 'sent' && postcard.sentCity != null
              ? "From: ${postcard.sentCity}" // 寄出後顯示城市名
              : "Topic: ${postcard.topic}",
        ),
        children: [
          if (isAdminView) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📦 SHIPPING ADDRESS:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 5),
                  SelectableText(postcard.address, 
                      style: const TextStyle(fontSize: 16, backgroundColor: Colors.yellow)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // --- 替換後的定位寄出按鈕 ---
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_on),
                        label: const Text("Locate & Send"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade100,
                          foregroundColor: Colors.orange.shade900,
                        ),
                        onPressed: () => _handleMarkAsSent(context),
                      ),
                      const SizedBox(width: 10),
                      // --- QR Code 標籤按鈕 ---
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.blueGrey),
                        tooltip: "Generate QR Label",
                        onPressed: () => _showQRDialog(context),
                      ),
                    ],
                  )
                ],
              ),
            )
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${postcard.status.toUpperCase()}"),
                  if (postcard.sentDate != null)
                    Text("Sent on: ${postcard.sentDate.toString().substring(0, 10)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
        ],
      ),
    );
  }

  // --- 邏輯：處理定位並更新 Firebase ---
  Future<void> _handleMarkAsSent(BuildContext context) async {
    try {
      // 1. 請求位置權限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 2. 獲取座標
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. 逆向地理編碼（座標轉城市名）
      String cityName = "Unknown Location";
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = "${p.locality}, ${p.country}";
        }
      } catch (e) {
        debugPrint("Geocoding failed: $e");
      }

      // 4. 更新 Firebase (需確保 FirebaseService 有對應方法)
      await FirebaseService().updateStatusWithLocation(
        postcard.id,
        'sent',
        lat: position.latitude,
        lng: position.longitude,
        city: cityName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully marked as sent from $cityName! 📮")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- 邏輯：顯示 QR Code 對話框 ---
  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Postcard QR Label"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              // 替換為你的網址
              data: "https://your-username.github.io{postcard.id}",
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
            ),
            const SizedBox(height: 10),
            const Text("Scan to mark as 'Received'", style: TextStyle(fontSize: 12)),
            SelectableText("ID: ${postcard.id}",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: "https://your-username.github.io{postcard.id}"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Copied!")));
            },
            child: const Text("Copy Link"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (postcard.status) {
      case 'sent':
        return const Icon(Icons.send_rounded, color: Colors.green);
      case 'received':
        return const Icon(Icons.favorite, color: Colors.pink);
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
    }
  }
}
