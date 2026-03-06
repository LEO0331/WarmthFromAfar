import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ReceivedConfirmationPage extends StatefulWidget {
  const ReceivedConfirmationPage({super.key});

  @override
  State<ReceivedConfirmationPage> createState() =>
      _ReceivedConfirmationPageState();
}

class _ReceivedConfirmationPageState extends State<ReceivedConfirmationPage> {
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confirmReceipt();
  }

  Future<void> _confirmReceipt() async {
    // 從當前網址取得參數 ?id=xxxxxx
    final String? docId = Uri.base.queryParameters['id'];

    if (docId == null || docId.isEmpty) {
      setState(() {
        _isProcessing = false;
        _error = "Invalid Link: No postcard ID found.";
      });
      return;
    }

    try {
      // 呼叫 Service 更新狀態為 'received'
      await FirebaseService().updateStatus(docId, 'received');
      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = "Update failed. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📮 Postcard Arrival")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: _isProcessing
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(_error!, style: const TextStyle(fontSize: 18)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 100, color: Colors.pink),
                    const SizedBox(height: 20),
                    const Text(
                      "You made my day!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "I'm so happy to know the postcard reached you safely. Thank you for being part of this journey!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/'),
                      child: const Text("View All Journeys"),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
