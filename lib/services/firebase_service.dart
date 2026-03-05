import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/postcard.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 使用者提交請求
  Future<void> addRequest(String name, String address, String topic) async {
    await _db.collection('postcards').add({
      'receiverName': name,
      'address': address,
      'topic': topic,
      'status': 'pending',
      'requestDate': FieldValue.serverTimestamp(),
    });
  }

  // 監聽所有明信片進度 (公開)
  Stream<List<Postcard>> getPublicPostcards() {
    return _db.collection('postcards')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Postcard.fromFirestore(doc)).toList());
  }

  // 管理員更新狀態
  Future<void> updateStatus(String id, String newStatus) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _db.collection('postcards').doc(id).update({
      'status': newStatus,
      'sentDate': newStatus == 'sent' ? FieldValue.serverTimestamp() : null,
    });
  }
}
