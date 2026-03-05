import 'package:cloud_firestore/cloud_firestore.dart';

class Postcard {
  final String id;
  final String receiverName;
  final String address;
  final String topic;
  final String status; // 'pending', 'sent', 'received'
  final DateTime? requestDate;
  final DateTime? sentDate;

  Postcard({
    required this.id,
    required this.receiverName,
    required this.address,
    required this.topic,
    required this.status,
    this.requestDate,
    this.sentDate,
  });

  factory Postcard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Postcard(
      id: doc.id,
      receiverName: data['receiverName'] ?? '',
      address: data['address'] ?? '',
      topic: data['topic'] ?? '',
      status: data['status'] ?? 'pending',
      requestDate: (data['requestDate'] as Timestamp?)?.toDate(),
      sentDate: (data['sentDate'] as Timestamp?)?.toDate(),
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
    };
  }
}
