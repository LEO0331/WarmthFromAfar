import 'package:cloud_firestore/cloud_firestore.dart';

class Postcard {
  final String id;
  final String receiverName;
  final String address;
  final String topic;
  final String status; // 'pending', 'sent', 'received'
  final DateTime? requestDate;
  final DateTime? sentDate;

  // --- 新增地圖相關欄位 ---
  final double? lat; // 緯度
  final double? lng; // 經度
  final String? sentCity; // 寄出的城市名稱 (例如: "Tokyo, Japan")

  Postcard({
    required this.id,
    required this.receiverName,
    required this.address,
    required this.topic,
    required this.status,
    this.requestDate,
    this.sentDate,
    this.lat,
    this.lng,
    this.sentCity,
  });

  factory Postcard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Postcard(
      id: doc.id,
      receiverName: data['receiverName'] ?? 'Anonymous',
      address: data['address'] ?? '',
      topic: data['topic'] ?? 'General',
      status: data['status'] ?? 'pending',
      requestDate: (data['requestDate'] as Timestamp?)?.toDate(),
      sentDate: (data['sentDate'] as Timestamp?)?.toDate(),
      // --- 解析新增欄位 ---
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      sentCity: data['sentCity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverName': receiverName,
      'address': address,
      'topic': topic,
      'status': status,
      'requestDate': requestDate ?? FieldValue.serverTimestamp(),
      'sentDate': sentDate,
      // --- 寫入新增欄位 ---
      'lat': lat,
      'lng': lng,
      'sentCity': sentCity,
    };
  }
}
