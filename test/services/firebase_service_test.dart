import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/models/postcard.dart';

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
    test('addRequest should add a document and return the ID', () async {
      final id = await service.addRequest('Leo', 'Address', 'Snow');
      
      expect(id, isNotNull);
      final doc = await fakeFirestore.collection('postcards').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['receiverName'], 'Leo');
      expect(doc.data()?['status'], 'pending');
    });

    test('updateStatus should update the postcard status', () async {
      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
      });
      
      await service.updateStatus(docRef.id, 'received');
      
      final updatedDoc = await docRef.get();
      expect(updatedDoc.data()?['status'], 'received');
    });

    test('deletePostcard should not delete if user is not logged in', () async {
      final docRef = await fakeFirestore.collection('postcards').add({'data': 'test'});
      
      await service.deletePostcard(docRef.id);
      
      final doc = await docRef.get();
      expect(doc.exists, isTrue);
    });

    test('deletePostcard should delete if user is logged in', () async {
      final docRef = await fakeFirestore.collection('postcards').add({'data': 'test'});
      
      // Sign in user
      final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(firestore: fakeFirestore, auth: mockAuthLoggedIn);
      
      await serviceWithAuth.deletePostcard(docRef.id);
      
      final doc = await docRef.get();
      expect(doc.exists, isFalse);
    });

    test('updateStatusWithLocation should update location and city', () async {
       // Mock login
      final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
      final serviceWithAuth = FirebaseService.forTest(firestore: fakeFirestore, auth: mockAuthLoggedIn);

      final docRef = await fakeFirestore.collection('postcards').add({
        'status': 'pending',
      });
      
      await serviceWithAuth.updateStatusWithLocation(
        docRef.id, 
        'sent', 
        lat: 1.23, 
        lng: 4.56, 
        city: 'Test City'
      );
      
      final doc = await docRef.get();
      expect(doc.data()?['status'], 'sent');
      expect(doc.data()?['lat'], 1.23);
      expect(doc.data()?['lng'], 4.56);
      expect(doc.data()?['sentCity'], 'Test City');
    });
    
    test('getPublicPostcards should return a stream of postcards', () async {
      await fakeFirestore.collection('postcards').add({
        'receiverName': 'A',
        'requestDate': DateTime.now(),
      });
      
      final stream = service.getPublicPostcards();
      final list = await stream.first;
      
      expect(list.length, 1);
      expect(list[0].receiverName, 'A');
    });
   group('markAsSent', () {
      test('should call updateStatusWithLocation', () async {
        final mockAuthLoggedIn = MockFirebaseAuth(signedIn: true);
        final serviceWithAuth = FirebaseService.forTest(firestore: fakeFirestore, auth: mockAuthLoggedIn);

        final docRef = await fakeFirestore.collection('postcards').add({
          'status': 'pending',
        });

        await serviceWithAuth.markAsSent(docRef.id, lat: 10.0, lng: 20.0, city: 'London');

        final doc = await docRef.get();
        expect(doc.data()?['status'], 'sent');
        expect(doc.data()?['sentCity'], 'London');
      });
    });
  });
}
