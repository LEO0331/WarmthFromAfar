import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('Postcard Model Tests', () {
    test('Postcard.fromFirestore should create a valid Postcard object', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      
      final mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.id).thenReturn('test-id');
      when(() => mockDoc.data()).thenReturn({
        'receiverName': 'Leo',
        'address': '123 Main St',
        'topic': 'Snow',
        'status': 'sent',
        'requestDate': timestamp,
        'sentDate': timestamp,
        'lat': 35.6895,
        'lng': 139.6917,
        'sentCity': 'Tokyo, Japan',
      });

      final postcard = Postcard.fromFirestore(mockDoc);

      expect(postcard.id, 'test-id');
      expect(postcard.receiverName, 'Leo');
      expect(postcard.address, '123 Main St');
      expect(postcard.topic, 'Snow');
      expect(postcard.status, 'sent');
      expect(postcard.requestDate, now);
      expect(postcard.sentDate, now);
      expect(postcard.lat, 35.6895);
      expect(postcard.lng, 139.6917);
      expect(postcard.sentCity, 'Tokyo, Japan');
    });

    test('Postcard.fromFirestore should handle null values and defaults', () {
      final mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.id).thenReturn('test-id-2');
      when(() => mockDoc.data()).thenReturn({});

      final postcard = Postcard.fromFirestore(mockDoc);

      expect(postcard.id, 'test-id-2');
      expect(postcard.receiverName, 'Anonymous');
      expect(postcard.address, '');
      expect(postcard.topic, 'General');
      expect(postcard.status, 'pending');
      expect(postcard.requestDate, isNull);
      expect(postcard.lat, isNull);
    });

    test('Postcard.toMap should return a valid map', () {
      final now = DateTime.now();
      final postcard = Postcard(
        id: 'test-id',
        receiverName: 'Leo',
        address: '123 Main St',
        topic: 'Snow',
        status: 'pending',
        requestDate: now,
        lat: 35.6895,
        lng: 139.6917,
        sentCity: 'Tokyo, Japan',
      );

      final map = postcard.toMap();

      expect(map['receiverName'], 'Leo');
      expect(map['address'], '123 Main St');
      expect(map['topic'], 'Snow');
      expect(map['status'], 'pending');
      expect(map['requestDate'], now);
      expect(map['lat'], 35.6895);
      expect(map['lng'], 139.6917);
      expect(map['sentCity'], 'Tokyo, Japan');
    });
  });
}
