import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:warmth_from_afar/models/postcard.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('Postcard Model Tests', () {
    test(
      'Postcard.fromFirestore should create a valid Postcard object',
      () async {
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);

        final docRef = await firestore.collection('postcards').add({
          'receiverName': 'Leo',
          'address': '123 Main St',
          'topic': 'Snow',
          'status': 'sent',
          'requestType': 'gift',
          'giftFromName': 'Maya',
          'giftMessage': 'You got this!',
          'campaign': 'Spring Japan Trip',
          'stage': 'sent',
          'requestDate': timestamp,
          'sentDate': timestamp,
          'lat': 35.6895,
          'lng': 139.6917,
          'sentCity': 'Tokyo, Japan',
          'travelerNote': 'Wrote this at sunset.',
          'travelerPhotoUrl': 'https://example.com/photo.jpg',
          'etaDays': 3,
          'recipientReaction': '❤️',
          'recipientMessage': 'Loved it',
          'showOnWall': true,
        });
        final doc = await docRef.get();

        final postcard = Postcard.fromFirestore(doc);

        expect(postcard.id, doc.id);
        expect(postcard.receiverName, 'Leo');
        expect(postcard.address, '123 Main St');
        expect(postcard.topic, 'Snow');
        expect(postcard.status, 'sent');
        expect(postcard.requestType, 'gift');
        expect(postcard.giftFromName, 'Maya');
        expect(postcard.giftMessage, 'You got this!');
        expect(postcard.campaign, 'Spring Japan Trip');
        expect(postcard.stage, 'sent');
        expect(postcard.requestDate, now);
        expect(postcard.sentDate, now);
        expect(postcard.lat, 35.6895);
        expect(postcard.lng, 139.6917);
        expect(postcard.sentCity, 'Tokyo, Japan');
        expect(postcard.travelerNote, 'Wrote this at sunset.');
        expect(postcard.travelerPhotoUrl, 'https://example.com/photo.jpg');
        expect(postcard.etaDays, 3);
        expect(postcard.recipientReaction, '❤️');
        expect(postcard.recipientMessage, 'Loved it');
        expect(postcard.showOnWall, true);
      },
    );

    test(
      'Postcard.fromFirestore should handle null values and defaults',
      () async {
        final docRef = await firestore.collection('postcards').add({});
        final doc = await docRef.get();

        final postcard = Postcard.fromFirestore(doc);

        expect(postcard.id, doc.id);
        expect(postcard.receiverName, 'Anonymous');
        expect(postcard.address, '');
        expect(postcard.topic, 'General');
        expect(postcard.status, 'pending');
        expect(postcard.requestType, 'self');
        expect(postcard.stage, 'requested');
        expect(postcard.requestDate, isNull);
        expect(postcard.lat, isNull);
        expect(postcard.showOnWall, false);
      },
    );

    test('Postcard.toMap should return a valid map', () {
      final now = DateTime.now();
      final postcard = Postcard(
        id: 'test-id',
        receiverName: 'Leo',
        address: '123 Main St',
        topic: 'Snow',
        requestType: 'gift',
        giftFromName: 'Maya',
        giftMessage: 'Happy birthday!',
        campaign: 'Taiwan Cafe Week',
        status: 'pending',
        stage: 'writing',
        requestDate: now,
        lat: 35.6895,
        lng: 139.6917,
        sentCity: 'Tokyo, Japan',
        travelerNote: 'Preparing a note.',
        travelerPhotoUrl: 'https://example.com/p.jpg',
        etaDays: 5,
        recipientReaction: '😊',
        recipientMessage: 'Thanks!',
        showOnWall: true,
      );

      final map = postcard.toMap();

      expect(map['receiverName'], 'Leo');
      expect(map['address'], '123 Main St');
      expect(map['topic'], 'Snow');
      expect(map['requestType'], 'gift');
      expect(map['giftFromName'], 'Maya');
      expect(map['giftMessage'], 'Happy birthday!');
      expect(map['campaign'], 'Taiwan Cafe Week');
      expect(map['status'], 'pending');
      expect(map['stage'], 'writing');
      expect(map['requestDate'], now);
      expect(map['lat'], 35.6895);
      expect(map['lng'], 139.6917);
      expect(map['sentCity'], 'Tokyo, Japan');
      expect(map['travelerNote'], 'Preparing a note.');
      expect(map['travelerPhotoUrl'], 'https://example.com/p.jpg');
      expect(map['etaDays'], 5);
      expect(map['recipientReaction'], '😊');
      expect(map['recipientMessage'], 'Thanks!');
      expect(map['showOnWall'], true);
    });
  });
}
