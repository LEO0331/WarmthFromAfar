import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                const Text("Warmth Sent!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Your request is in my journey list.\nI'll write it when I reach the next city.", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Can't wait!")),
              ],
            ),
          ),
        );
      },
    );
  }
}
