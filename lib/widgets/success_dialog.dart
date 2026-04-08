import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessDialog extends StatelessWidget {
  final String docId; // 新增：接收 Firebase 的 ID
  final VoidCallback? onOpenTracking;

  const SuccessDialog({super.key, required this.docId, this.onOpenTracking});

  @override
  Widget build(BuildContext context) {
    // 取得 ID 的最後四碼並轉為大寫，作為簡單好記的序號
    final String shortId = docId.length >= 4
        ? docId.substring(docId.length - 4).toUpperCase()
        : docId.toUpperCase();
    final String deepLink =
        "${Uri.base.origin}${Uri.base.path}#/received?id=$docId";

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Warmth Requested!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                const Text("Your Unique Tracker ID:"),
                const SizedBox(height: 8),

                // 顯示四位序號的深色區塊
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "W-$shortId",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                const Text(
                  "Keep this ID to track your postcard.\nNext: open tracking, or share this with a friend.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: "W-$shortId"),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tracker ID copied")),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy ID"),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: deepLink));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Share link copied")),
                          );
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                    ElevatedButton.icon(
                      onPressed: onOpenTracking ?? () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.track_changes),
                      label: const Text("Open Tracking"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
