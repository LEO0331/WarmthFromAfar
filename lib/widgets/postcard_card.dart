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
    // 1. 檢查權限 (這會觸發瀏覽器權限彈窗)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return; // 使用者拒絕
    }

    // 2. 獲取座標 (加上 timeout 防止 Web 卡死)
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 10));

    // 3. 處理城市名稱 (解決 Geocoding null 錯誤)
    String cityName = "Traveling...";
    try {
      // 在 Web 上 placemarkFromCoordinates 常回傳空 list 或 null
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // 增加 null check，避免 "Unexpected null value"
        final locality = p.locality ?? "";
        final country = p.country ?? "";
        cityName = (locality.isNotEmpty && country.isNotEmpty) 
                   ? "$locality, $country" 
                   : (p.name ?? "Unknown Location");
      } else {
        // 如果抓不到地名，就顯示簡短座標
        cityName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      }
    } catch (e) {
      // 捕捉 Geocoding 錯誤，避免中斷主流程
      cityName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      debugPrint("Geocoding ignored: $e");
    }

    // 4. 更新 Firebase (確保 Service 裡有這個方法)
    await FirebaseService().updateStatusWithLocation(
      postcard.id,
      'sent',
      lat: position.latitude,
      lng: position.longitude,
      city: cityName,
    );

    // 5. 最後才顯示 SnackBar，避免 RenderBox size 衝突
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // 先隱藏舊的
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Marked as sent from $cityName! 📮")),
      );
    }
  } catch (e) {
    debugPrint("MarkAsSent Error: $e");
    // 保底：定位失敗時至少要能標記寄出
    //await FirebaseService().updateStatus(postcard.id, 'sent');
    // ignore: use_build_context_synchronously
    await _updateWithoutLocation(context);
  }
}

// 輔助方法：當定位失敗時的保底更新
Future<void> _updateWithoutLocation(BuildContext context) async {
  await FirebaseService().updateStatus(postcard.id, 'sent');
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marked as sent (Location skipped).")),
    );
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
