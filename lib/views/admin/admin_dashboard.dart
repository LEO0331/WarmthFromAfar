import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/postcard.dart';
import '../../widgets/postcard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard (All Data)"),
        actions: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: StreamBuilder<List<Postcard>>(
        stream: FirebaseService().getPublicPostcards(), // 管理員看同一個 Stream 但顯示更多
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) => PostcardCard(
              postcard: snapshot.data![i],
              isAdminView: true, // 關鍵：開啟管理員模式
            ),
          );
        },
      ),
    );
  }
}
