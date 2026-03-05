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
  String _selectedTopic = "Inspiration";
  int _tapCount = 0;

  void _submit() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) return;
    await FirebaseService().addRequest(_nameController.text, _addressController.text, _selectedTopic);
    if (!mounted) return;
    showDialog(context: context, builder: (context) => const SuccessDialog());
    _nameController.clear();
    _addressController.clear();
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
              if (_tapCount == 5) Navigator.pushNamed(context, '/admin-login');
            },
            child: const Text("Receive Warmth From A Stranger", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nickname", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _addressController, maxLines: 3, decoration: const InputDecoration(labelText: "Full Address", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: _selectedTopic,
            items: ["Inspiration", "Comfort", "Travel Story", "Daily Life"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedTopic = val!),
            decoration: const InputDecoration(labelText: "Message Topic", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)), child: const Text("Send Request")),
        ],
      ),
    );
  }
}
