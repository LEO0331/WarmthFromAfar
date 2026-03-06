import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/success_dialog.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});
  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedTopic;
  int _tapCount = 0;

  final List<String> _topics = [
    "Inspiration (勇氣與啟發)",
    "Comfort (溫暖與安慰)",
    "Travel Story (旅行故事)",
    "Daily Life (生活雜記)",
    "Random Surprise (隨機驚喜)",
    "Birthday Blessing (生日祝福)",
    "Heartbreak Healing (失戀療癒)",
    "New Adventure (冒險啟程)",
  ];

  void _submit() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and pick a topic!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 1. 修改此處：接收 Firebase 回傳的 docId
    final String? newDocId = await FirebaseService().addRequest(
      _nameController.text,
      _addressController.text,
      _selectedTopic!,
    );

    if (!mounted) return;

    // 2. 將 docId 傳給 SuccessDialog 顯示序號
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(docId: newDocId ?? "TEMP"),
    );

    setState(() {
      _nameController.clear();
      _addressController.clear();
      _selectedTopic = null;
    });
  }

  // 抽出統一的輸入框樣式 (Light Color Style)
  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.amber.shade700),
      filled: true,
      fillColor: Colors.grey.shade50, // 淺色背景
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              _tapCount++;
              if (_tapCount == 5) {
                _tapCount = 0;
                Navigator.pushNamed(context, '/admin-login');
              }
            },
            child: const Text(
              "Receive Warmth From A Traveller",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),

          // Nickname 輸入框
          TextField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              "Nickname / Name",
              "How should I call you?",
              Icons.person_outline,
            ),
          ),
          const SizedBox(height: 15),

          // Address 輸入框 (Light Color 樣式)
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: _buildInputDecoration(
              "Mailing Address",
              "An address you are comfortable to share with",
              Icons.home_outlined,
            ),
          ),
          const SizedBox(height: 15),

          // 下拉選單
          DropdownButtonFormField<String>(
            initialValue: _selectedTopic, 
            hint: const Text("Select a Message Topic"),
            items: _topics
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _selectedTopic = val),
            decoration: _buildInputDecoration(
              "What do you need?",
              "",
              Icons.auto_awesome_outlined,
            ),
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Send Warmth Request 📮",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
