import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.login(_email.text, _pw.text);
    if (error == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Access")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _handleLogin, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}
