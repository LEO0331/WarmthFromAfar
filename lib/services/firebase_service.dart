import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 加入用於 debugPrint
import '../models/postcard.dart';

class FirebaseService {
  static FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirebaseService._internal({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  @visibleForTesting
  factory FirebaseService.forTest({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    return FirebaseService._internal(firestore: firestore, auth: auth);
  }

  @visibleForTesting
  static void setMockInstance(FirebaseService mock) {
    _instance = mock;
  }

  // 1. [新增] 管理員手動刪除紀錄 (隱私清理)
  Future<void> deletePostcard(String id) async {
    // 安全檢查：確保只有登入的管理員可以執行
    if (_auth.currentUser == null) return;

    try {
      await _db.collection('postcards').doc(id).delete();
    } catch (e) {
      debugPrint("Delete Error: $e");
      rethrow;
    }
  }

  // 2. 使用者提交請求 (回傳生成的 ID 用於顯示 W-XXXX 序號)
  Future<String?> addRequest(
    String name,
    String address,
    String topic, {
    String requestType = 'self',
    String? giftFromName,
    String? giftMessage,
    String? campaign,
  }) async {
    DocumentReference docRef = await _db.collection('postcards').add({
      'receiverName': name,
      'address': address,
      'topic': topic,
      'requestType': requestType,
      'giftFromName': giftFromName,
      'giftMessage': giftMessage,
      'campaign': campaign,
      'status': 'pending',
      'stage': 'requested',
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
    if (_auth.currentUser == null) return;

    await _db.collection('postcards').doc(id).update({
      'status': newStatus,
      'stage': newStatus == 'received' ? 'received' : 'sent',
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
      'stage': newStatus == 'received' ? 'received' : 'sent',
      'sentDate': newStatus == 'sent' ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> updateJourneyProgress(
    String id, {
    String? stage,
    String? travelerNote,
    String? travelerPhotoUrl,
    int? etaDays,
  }) async {
    if (_auth.currentUser == null) return;

    final Map<String, dynamic> payload = {};
    if (stage != null) {
      payload['stage'] = stage;
      if (stage == 'sent') payload['status'] = 'sent';
      if (stage == 'received') payload['status'] = 'received';
    }
    if (travelerNote != null) payload['travelerNote'] = travelerNote;
    if (travelerPhotoUrl != null) {
      payload['travelerPhotoUrl'] = travelerPhotoUrl;
    }
    if (etaDays != null) payload['etaDays'] = etaDays;

    if (payload.isEmpty) return;
    await _db.collection('postcards').doc(id).update(payload);
  }

  Future<void> updateReceiptFeedback(
    String id, {
    required String reaction,
    required String message,
    required bool showOnWall,
  }) async {
    await _db.collection('postcards').doc(id).update({
      'recipientReaction': reaction,
      'recipientMessage': message,
      'showOnWall': showOnWall,
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

  // 6. 搜尋特定短 ID 的明信片
  Future<Postcard?> getPostcardByShortId(String shortId) async {
    final query = shortId.toUpperCase();
    final snapshot = await _db.collection('postcards').get();
    try {
      final doc = snapshot.docs.firstWhere(
        (d) => d.id.toUpperCase().endsWith(query),
      );
      return Postcard.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, int>> getTopicStats() async {
    final snapshot = await _db.collection('postcards').get();
    final Map<String, int> result = {};
    for (final doc in snapshot.docs) {
      final topic = (doc.data()['topic'] as String?) ?? 'General';
      result[topic] = (result[topic] ?? 0) + 1;
    }
    return result;
  }
}
