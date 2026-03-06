import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    // 檢查網址參數是否帶有 ?id=xxxx
    _checkUrlAndConfirm();
  }

  Future<void> _checkUrlAndConfirm() async {
    final String? docId = Uri.base.queryParameters['id'];
    if (docId != null && docId.isNotEmpty) {
      _processConfirmation(docId);
    }
  }

  Future<void> _processConfirmation(String docId) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await FirebaseService().updateStatus(docId, 'received');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = "Update failed. The ID might be incorrect.";
        });
      }
    }
  }

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
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = "Postcard not found. Please check the ID.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 成功畫面
    if (_isSuccess) return _buildSuccessView();

    // 必須使用 Scaffold 包裹，以提供 Material 環境給 TextField
    return Scaffold(
      backgroundColor: Colors.white,
      // 只有當直接透過 URL 進入時才顯示 AppBar
      appBar: Uri.base.queryParameters.containsKey('id') 
          ? AppBar(title: const Text("Confirm Receipt"), centerTitle: true)
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) 
                const CircularProgressIndicator()
              else ...[
                const Icon(
                  Icons.volunteer_activism_rounded,
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

                // 手動輸入框 (加強樣式)
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _idController,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: "e.g. 8A2C",
                      counterText: "",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amber, width: 2),
                      ),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _manualConfirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Confirm Arrival ❤️", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 120, color: Colors.pink),
              const SizedBox(height: 30),
              const Text(
                "You made my day!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "I'm so happy to know the postcard reached you safely. Thank you for being part of this journey!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSuccess = false;
                    _idController.clear();
                  });
                  // 導回到首頁 (Request Tab)
                  Navigator.pushNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
