import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 需引入用於手動搜尋
import '../services/firebase_service.dart';

class ReceivedConfirmationPage extends StatefulWidget {
  const ReceivedConfirmationPage({super.key});

  @override
  State<ReceivedConfirmationPage> createState() =>
      _ReceivedConfirmationPageState();
}

class _ReceivedConfirmationPageState extends State<ReceivedConfirmationPage> {
  final TextEditingController _idController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkUrlAndConfirm();
  }

  // 自動檢查網址是否有 ?id=xxxx
  Future<void> _checkUrlAndConfirm() async {
    final String? docId = Uri.base.queryParameters['id'];
    if (docId != null && docId.isNotEmpty) {
      _processConfirmation(docId);
    }
  }

  // 核心邏輯：執行狀態更新
  Future<void> _processConfirmation(String docId) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await FirebaseService().updateStatus(docId, 'received');
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = "Update failed. The ID might be incorrect.";
      });
    }
  }

  // 手動輸入 4 位序號的搜尋邏輯
  Future<void> _manualConfirm() async {
    final input = _idController.text.trim().toUpperCase().replaceAll("W-", "");
    if (input.length < 4) {
      setState(() => _error = "Please enter at least 4 characters.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 搜尋 Firestore 找到 ID 後四碼匹配的文件
      final snapshot = await FirebaseFirestore.instance
          .collection('postcards')
          .get();
      final doc = snapshot.docs.firstWhere(
        (d) => d.id.toUpperCase().endsWith(input),
      );

      await _processConfirmation(doc.id);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = "Postcard not found. Please check the ID.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果成功，顯示愛心畫面
    if (_isSuccess) return _buildSuccessView();

    return Scaffold(
      appBar: AppBar(title: const Text("📮 Confirm Receipt")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isProcessing) const CircularProgressIndicator(),

              if (!_isProcessing) ...[
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Did you receive a postcard?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("Enter the 4-digit ID from the postcard:"),
                const SizedBox(height: 20),

                // 手動輸入框
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _idController,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: "e.g. 8A2C",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _manualConfirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text("Confirm Arrival ❤️"),
                ),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/'),
                  child: const Text("Back to Home"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 成功的 UI
  Widget _buildSuccessView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 120, color: Colors.pink),
            const SizedBox(height: 30),
            const Text(
              "You made my day!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                "I'm so happy to know the postcard reached you safely. Thank you for being part of this journey!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/'),
              child: const Text("View All Journeys"),
            ),
          ],
        ),
      ),
    );
  }
}
