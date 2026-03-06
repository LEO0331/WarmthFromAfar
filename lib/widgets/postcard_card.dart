import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/postcard.dart';
import '../services/firebase_service.dart';

class PostcardCard extends StatelessWidget {
  final Postcard postcard;
  final bool isAdminView;

  const PostcardCard({
    super.key,
    required this.postcard,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _getStatusIcon(),
        title: Text("To: ${postcard.receiverName}"),
        subtitle: Text(
          postcard.status == 'sent' && postcard.sentCity != null
              ? "From: ${postcard.sentCity}"
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🆔 WARMTH ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                      SelectableText(
                        "W-${postcard.id.substring(postcard.id.length - 4).toUpperCase()}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "📦 SHIPPING ADDRESS:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    postcard.address,
                    style: const TextStyle(fontSize: 16, backgroundColor: Colors.yellow),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text("Locate & Send"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.orange.shade900,
                      ),
                      onPressed: () => _handleMarkAsSent(context),
                    ),
                  ),
                  if (postcard.status == 'sent') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.pink),
                        label: const Text("Manual Mark as Received"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.pink),
                        onPressed: () async {
                          await FirebaseService().updateStatus(postcard.id, 'received');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Updated to Received ❤️")),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                  if (postcard.status == 'received') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                        label: const Text("Delete Record (Privacy Clean)"),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, postcard.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顯示狀態文字
                  Text(
                    "Status: ${postcard.status.toUpperCase()}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(postcard.status),
                    ),
                  ),
                  const SizedBox(height: 5),
                  
                  // --- 新增：顯示申請日期 ---
                  if (postcard.requestDate != null)
                    Text(
                      "Requested on: ${postcard.requestDate!.toString().substring(0, 10)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                  // 顯示寄出日期與城市
                  if (postcard.status == 'sent' && postcard.sentDate != null)
                    Text(
                      "Sent on: ${postcard.sentDate.toString().substring(0, 10)} ${postcard.sentCity != null ? 'from ${postcard.sentCity}' : ''}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    
                  // 顯示到達鼓勵文字
                  if (postcard.status == 'received')
                    const Text(
                      "Arrived safely! ❤️",
                      style: TextStyle(fontSize: 12, color: Colors.pink, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'received') return Colors.pink;
    if (status == 'sent') return Colors.green;
    return Colors.orange;
  }

  Future<void> _handleMarkAsSent(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      // 預設城市名稱為經緯度，防止 Geocoding 失敗
      String cityName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5)); // 增加超時保護

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final locality = p.locality ?? "";
          final country = p.country ?? "";
          if (locality.isNotEmpty || country.isNotEmpty) {
            cityName = "$locality, $country";
          }
        }
      } catch (e) {
        // Geocoding 失敗時，cityName 維持經緯度字串，不會報 Unexpected null value
        debugPrint("Geocoding ignored: $e");
      }

      await FirebaseService().updateStatusWithLocation(
        postcard.id,
        'sent',
        lat: position.latitude,
        lng: position.longitude,
        city: cityName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Marked as sent from $cityName! 📮")),
        );
      }
    } catch (e) {
      debugPrint("MarkAsSent Error: $e");
      if (context.mounted) await _updateWithoutLocation(context);
    }
  }

  Future<void> _updateWithoutLocation(BuildContext context) async {
    await FirebaseService().updateStatus(postcard.id, 'sent');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as sent (Location skipped).")),
      );
    }
  }

  Widget _getStatusIcon() {
    switch (postcard.status) {
      case 'sent':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.airplanemode_active, color: Colors.white, size: 18),
        );
      case 'received':
        return const CircleAvatar(
          backgroundColor: Colors.pink,
          child: Icon(Icons.favorite, color: Colors.white, size: 18),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.hourglass_empty, color: Colors.white, size: 18),
        );
    }
  }
}

void _confirmDelete(BuildContext context, String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm Deletion?"),
      content: const Text("This will permanently remove the address and record from the database for privacy."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await FirebaseService().deletePostcard(id);
            if (context.mounted) Navigator.pop(ctx);
          },
          child: const Text("Delete Now"),
        ),
      ],
    ),
  );
}