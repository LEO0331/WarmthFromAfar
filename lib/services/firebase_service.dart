import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 加入用於 debugPrint
import '../models/postcard.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. [新增] 管理員手動刪除紀錄 (隱私清理)
  Future<void> deletePostcard(String id) async {
    // 安全檢查：確保只有登入的管理員可以執行
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      await _db.collection('postcards').doc(id).delete();
    } catch (e) {
      debugPrint("Delete Error: $e");
      rethrow;
    }
  }

  // 2. 使用者提交請求 (回傳生成的 ID 用於顯示 W-XXXX 序號)
  Future<String?> addRequest(String name, String address, String topic) async {
    DocumentReference docRef = await _db.collection('postcards').add({
      'receiverName': name,
      'address': address,
      'topic': topic,
      'status': 'pending',
      'requestDate': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // 3. 監聽所有明信片進度 (公開，用於 Tracker 與 Chart)
  Stream<List<Postcard>> getPublicPostcards() {
    return _db
        .collection('postcards')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Postcard.fromFirestore(doc)).toList(),
        );
  }

  // 4. 管理員更新狀態 (含座標與城市)
  Future<void> updateStatusWithLocation(
    String id,
    String newStatus, {
    double? lat,
    double? lng,
    String? city,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    await _db.collection('postcards').doc(id).update({
      'status': newStatus,
      'lat': lat,
      'lng': lng,
      'sentCity': city,
      'sentDate': newStatus == 'sent' ? FieldValue.serverTimestamp() : null,
    });
  }

  // 5. 基礎狀態更新 (用於收件人回報或無座標更新)
  Future<void> updateStatus(String id, String newStatus) async {
    // 注意：收件人回報時是不會登入的，所以這裡不檢查 currentUser
    // 但如果是管理員手動更改，建議分開邏輯或在 Rules 層面控管
    await _db.collection('postcards').doc(id).update({
      'status': newStatus,
      'sentDate': newStatus == 'sent' ? FieldValue.serverTimestamp() : null,
    });
  }

  // 保留：舊版標記寄出方法 (相容性用)
  Future<void> markAsSent(
    String id, {
    required double lat,
    required double lng,
    required String city,
  }) async {
    await updateStatusWithLocation(id, 'sent', lat: lat, lng: lng, city: city);
  }
}
