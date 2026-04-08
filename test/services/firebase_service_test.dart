import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FirebaseService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    service = FirebaseService.forTest(firestore: fakeFirestore, auth: mockAuth);
  });

  group('FirebaseService Tests', () {
    test('forTest without args attempts default firebase instances', () {
      expect(() => FirebaseService.forTest(), throwsA(anything));
    });

    test('addRequest should add a document and return the ID', () async {
      final id = await service.addRequest('Leo', 'Address', 'Snow');

      expect(id, isNotNull);
      final doc = await fakeFirestore.collection('postcards').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['receiverName'], 'Leo');
      expect(doc.data()?['status'], 'pending');
      expect(doc.data()?['requestType'], 'self');
      expect(doc.data()?['stage'], 'requested');
    });

    test('addRequest should persist gift and campaign metadata', () async {
      final id = await service.addRequest(
        'Kai',
        'Gift Address',
        'Comfort',
        requestType: 'gift',
        giftFromName: 'Leo',
        giftMessage: 'For a hard week',
        campaign: 'Spring Japan Trip',
      );

      final doc = await fakeFirestore.collection('postcards').doc(id).get();
      expect(doc.data()?['requestType'], 'gift');
      expect(doc.data()?['giftFromName'], 'Leo');
      expect(doc.data()?['giftMessage'], 'For a hard week');
      expect(doc.data()?['campaign'], 'Spring Japan Trip');
    });

    test('updateStatus should update the postcard status', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
      });

      await service.updateStatus(docRef.id, 'received');

      final updatedDoc = await docRef.get();
      expect(updatedDoc.data()?['status'], 'received');
      expect(updatedDoc.data()?['stage'], 'received');
    });

    test('deletePostcard should not delete if user is not logged in', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'data': 'test',
      });

      await service.deletePostcard(docRef.id);

      final doc = await docRef.get();
      expect(doc.exists, isTrue);
    });

    test('deletePostcard should delete if user is logged in', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'data': 'test',
      });

      // Sign in user
      final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(
        firestore: fakeFirestore,
        auth: mockAuthLoggedIn,
      );

      await serviceWithAuth.deletePostcard(docRef.id);

      final doc = await docRef.get();
      expect(doc.exists, isFalse);
    });

    test('updateStatusWithLocation should update location and city', () async {
      // Mock login
      final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(
        firestore: fakeFirestore,
        auth: mockAuthLoggedIn,
      );

      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
      });

      await serviceWithAuth.updateStatusWithLocation(
        docRef.id,
        'sent',
        lat: 1.23,
        lng: 4.56,
        city: 'Test City',
      );

      final doc = await docRef.get();
      expect(doc.data()?['status'], 'sent');
      expect(doc.data()?['lat'], 1.23);
      expect(doc.data()?['lng'], 4.56);
      expect(doc.data()?['sentCity'], 'Test City');
      expect(doc.data()?['stage'], 'sent');
    });

    test('getPublicPostcards should return a stream of postcards', () async {
      await fakeFirestore.collection('postcards').add({
        'receiverName': 'A',
        'requestDate': Timestamp.fromDate(DateTime.now()),
      });

      final stream = service.getPublicPostcards();
      final list = await stream.first;

      expect(list.length, 1);
      expect(list[0].receiverName, 'A');
    });

    test(
      'updateJourneyProgress should update stage and story fields',
      () async {
        final auth = MockFirebaseAuth(signedIn: true);
        final serviceWithAuth = FirebaseService.forTest(
          firestore: fakeFirestore,
          auth: auth,
        );
        final docRef = await fakeFirestore.collection('postcards').add({
          'status': 'pending',
          'stage': 'requested',
        });

        await serviceWithAuth.updateJourneyProgress(
          docRef.id,
          stage: 'writing',
          travelerNote: 'Writing from Kyoto',
          travelerPhotoUrl: 'https://example.com/photo.jpg',
          etaDays: 4,
        );

        final doc = await docRef.get();
        expect(doc.data()?['stage'], 'writing');
        expect(doc.data()?['travelerNote'], 'Writing from Kyoto');
        expect(
          doc.data()?['travelerPhotoUrl'],
          'https://example.com/photo.jpg',
        );
        expect(doc.data()?['etaDays'], 4);
      },
    );

    test('updateJourneyProgress should no-op when unauthenticated', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
        'stage': 'requested',
      });

      await service.updateJourneyProgress(docRef.id, stage: 'sent');
      final doc = await docRef.get();
      expect(doc.data()?['stage'], 'requested');
    });

    test('updateJourneyProgress should no-op with empty payload', () async {
      final auth = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(
        firestore: fakeFirestore,
        auth: auth,
      );
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
        'stage': 'requested',
      });

      await serviceWithAuth.updateJourneyProgress(docRef.id);
      final doc = await docRef.get();
      expect(doc.data()?['stage'], 'requested');
    });

    test('updateJourneyProgress maps sent/received stages to status', () async {
      final auth = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(
        firestore: fakeFirestore,
        auth: auth,
      );
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
        'stage': 'requested',
      });

      await serviceWithAuth.updateJourneyProgress(docRef.id, stage: 'sent');
      var doc = await docRef.get();
      expect(doc.data()?['status'], 'sent');

      await serviceWithAuth.updateJourneyProgress(docRef.id, stage: 'received');
      doc = await docRef.get();
      expect(doc.data()?['status'], 'received');
    });

    test('updateReceiptFeedback should store reaction and message', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'received',
      });

      await service.updateReceiptFeedback(
        docRef.id,
        reaction: '❤️',
        message: 'This made my week',
        showOnWall: true,
      );

      final doc = await docRef.get();
      expect(doc.data()?['recipientReaction'], '❤️');
      expect(doc.data()?['recipientMessage'], 'This made my week');
      expect(doc.data()?['showOnWall'], true);
    });

    test('getTopicStats should aggregate topic counts', () async {
      await fakeFirestore.collection('postcards').add({'topic': 'Comfort'});
      await fakeFirestore.collection('postcards').add({'topic': 'Comfort'});
      await fakeFirestore.collection('postcards').add({'topic': 'Inspiration'});

      final stats = await service.getTopicStats();
      expect(stats['Comfort'], 2);
      expect(stats['Inspiration'], 1);
    });

    test(
      'getPostcardByShortId returns matching postcard and null when absent',
      () async {
        final docRef = await fakeFirestore.collection('postcards').add({
          'receiverName': 'Leo',
          'address': 'Address',
          'topic': 'Travel',
          'status': 'pending',
          'requestDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });

        final suffix = docRef.id.substring(docRef.id.length - 4).toUpperCase();
        final found = await service.getPostcardByShortId(suffix);
        final notFound = await service.getPostcardByShortId('ZZZZ');

        expect(found, isNotNull);
        expect(found!.id, docRef.id);
        expect(notFound, isNull);
      },
    );

    group('markAsSent', () {
      test('should call updateStatusWithLocation', () async {
        final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
        final serviceWithAuth = FirebaseService.forTest(
          firestore: fakeFirestore,
          auth: mockAuthLoggedIn,
        );

        final docRef = await fakeFirestore.collection('postcards').add({
          'status': 'pending',
        });

        await serviceWithAuth.markAsSent(
          docRef.id,
          lat: 10.0,
          lng: 20.0,
          city: 'London',
        );

        final doc = await docRef.get();
        expect(doc.data()?['status'], 'sent');
        expect(doc.data()?['sentCity'], 'London');
        expect(doc.data()?['stage'], 'sent');
      });
    });
  });
}
