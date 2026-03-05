import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/firebase_service.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Postcard>>(
      stream: FirebaseService().getPublicPostcards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final p = list[i];
            return ListTile(
              leading: Icon(p.status == 'sent' ? Icons.mark_as_unread : Icons.hourglass_top, color: p.status == 'sent' ? Colors.green : Colors.orange),
              title: Text("To: ${p.receiverName}"),
              subtitle: Text("Status: ${p.status.toUpperCase()} • Topic: ${p.topic}"),
            );
          },
        );
      },
    );
  }
}
