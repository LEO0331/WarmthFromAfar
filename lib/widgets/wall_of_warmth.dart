import 'package:flutter/material.dart';
import '../models/postcard.dart';

class WallOfWarmth extends StatelessWidget {
  final List<Postcard> postcards;

  const WallOfWarmth({super.key, required this.postcards});

  @override
  Widget build(BuildContext context) {
    final messages = postcards
        .where(
          (p) =>
              p.showOnWall &&
              (p.recipientMessage?.trim().isNotEmpty ?? false) &&
              (p.recipientReaction?.trim().isNotEmpty ?? false),
        )
        .take(6)
        .toList();

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wall of Warmth",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Shared reactions from recipients",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final item in messages) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.recipientReaction}  W-${item.id.substring(item.id.length - 4).toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.recipientMessage!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
