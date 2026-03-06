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

  // 1. 將預設值設為 null，強制使用者選擇
  String? _selectedTopic;
  int _tapCount = 0;

  // 2. 擴充更多溫暖的話題
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
    // 3. 防呆檢查：確保話題已被選擇
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

    await FirebaseService().addRequest(
      _nameController.text,
      _addressController.text,
      _selectedTopic!,
    );

    if (!mounted) return;

    // 彈出驚喜動畫對話框
    showDialog(context: context, builder: (context) => const SuccessDialog());

    // 4. 提交後重置表單
    setState(() {
      _nameController.clear();
      _addressController.clear();
      _selectedTopic = null;
    });
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
                _tapCount = 0; // 重置計數
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Nickname / Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Full Shipping Address",
              hintText: "Include postal code and country",
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 186, 182, 182),
                fontSize: 14,
              ),
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 15),

          // 5. 下拉選單實作：使用 hint 取代 initialValue
          DropdownButtonFormField<String>(
            initialValue: _selectedTopic,
            hint: const Text("Select a Message Topic"), // 初始為空時顯示的提示
            items: _topics
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _selectedTopic = val),
            decoration: const InputDecoration(
              labelText: "What do you need?",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.auto_awesome_outlined),
            ),
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
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
