import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/postcard.dart';
import '../../widgets/postcard_card.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; 

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Logout",
          onPressed: () async {
            // 1. 執行登出
            await Provider.of<AuthProvider>(context, listen: false).logout();
            // 2. 跳回首頁並清空路由堆疊
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out safely")),
              );
            }
          },
        ),
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
