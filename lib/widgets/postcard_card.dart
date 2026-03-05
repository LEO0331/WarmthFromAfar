import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        subtitle: Text("Topic: ${postcard.topic}"),
        children: [
          if (isAdminView) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📦 SHIPPING ADDRESS:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  SelectableText(postcard.address),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => FirebaseService().updateStatus(postcard.id, 'sent'),
                        icon: const Icon(Icons.local_shipping),
                        label: const Text("Mark as Sent"),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          // 生成 QR Code 連結並複製
                          Clipboard.setData(ClipboardData(text: "https://wanderstamp.web.app{postcard.id}"));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receipt Link Copied!")));
                        },
                        icon: const Icon(Icons.qr_code),
                      )
                    ],
                  )
                ],
              ),
            )
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Status: ${postcard.status.toUpperCase()}"),
            )
        ],
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (postcard.status) {
      case 'sent': return const Icon(Icons.send_rounded, color: Colors.green);
      case 'received': return const Icon(Icons.favorite, color: Colors.pink);
      default: return const Icon(Icons.hourglass_empty, color: Colors.orange);
    }
  }
}
