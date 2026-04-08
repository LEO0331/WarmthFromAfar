import 'package:cloud_firestore/cloud_firestore.dart';

class Postcard {
  final String id;
  final String receiverName;
  final String address;
  final String topic;
  final String requestType; // 'self', 'gift'
  final String? giftFromName;
  final String? giftMessage;
  final String? campaign;
  final String status; // 'pending', 'sent', 'received'
  final String stage; // 'requested', 'writing', 'packed', 'sent', 'received'
  final DateTime? requestDate;
  final DateTime? sentDate;

  // --- 新增地圖相關欄位 ---
  final double? lat; // 緯度
  final double? lng; // 經度
  final String? sentCity; // 寄出的城市名稱 (例如: "Tokyo, Japan")
  final String? travelerNote;
  final String? travelerPhotoUrl;
  final int? etaDays;
  final String? recipientReaction;
  final String? recipientMessage;
  final bool showOnWall;

  Postcard({
    required this.id,
    required this.receiverName,
    required this.address,
    required this.topic,
    this.requestType = 'self',
    this.giftFromName,
    this.giftMessage,
    this.campaign,
    required this.status,
    this.stage = 'requested',
    this.requestDate,
    this.sentDate,
    this.lat,
    this.lng,
    this.sentCity,
    this.travelerNote,
    this.travelerPhotoUrl,
    this.etaDays,
    this.recipientReaction,
    this.recipientMessage,
    this.showOnWall = false,
  });

  factory Postcard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Postcard(
      id: doc.id,
      receiverName: data['receiverName'] ?? 'Anonymous',
      address: data['address'] ?? '',
      topic: data['topic'] ?? 'General',
      status: data['status'] ?? 'pending',
      requestType: data['requestType'] ?? 'self',
      giftFromName: data['giftFromName'],
      giftMessage: data['giftMessage'],
      campaign: data['campaign'],
      stage: data['stage'] ?? _deriveStage(data['status'] ?? 'pending'),
      requestDate: (data['requestDate'] as Timestamp?)?.toDate(),
      sentDate: (data['sentDate'] as Timestamp?)?.toDate(),
      // --- 解析新增欄位 ---
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      sentCity: data['sentCity'],
      travelerNote: data['travelerNote'],
      travelerPhotoUrl: data['travelerPhotoUrl'],
      etaDays: data['etaDays'],
      recipientReaction: data['recipientReaction'],
      recipientMessage: data['recipientMessage'],
      showOnWall: data['showOnWall'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverName': receiverName,
      'address': address,
      'topic': topic,
      'requestType': requestType,
      'giftFromName': giftFromName,
      'giftMessage': giftMessage,
      'campaign': campaign,
      'status': status,
      'stage': stage,
      'requestDate': requestDate ?? FieldValue.serverTimestamp(),
      'sentDate': sentDate,
      // --- 寫入新增欄位 ---
      'lat': lat,
      'lng': lng,
      'sentCity': sentCity,
      'travelerNote': travelerNote,
      'travelerPhotoUrl': travelerPhotoUrl,
      'etaDays': etaDays,
      'recipientReaction': recipientReaction,
      'recipientMessage': recipientMessage,
      'showOnWall': showOnWall,
    };
  }

  static String _deriveStage(String status) {
    switch (status) {
      case 'received':
        return 'received';
      case 'sent':
        return 'sent';
      default:
        return 'requested';
    }
  }
}
