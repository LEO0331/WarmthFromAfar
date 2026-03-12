import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;

  User? get user => _user;
  bool get isAdmin => _user != null;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // 成功
    } catch (e) {
      return e.toString(); // 失敗回傳錯誤訊息
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
