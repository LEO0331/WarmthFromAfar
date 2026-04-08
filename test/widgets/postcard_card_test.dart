import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/widgets/postcard_card.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;
  const geocodingChannel = MethodChannel('flutter.baseflow.com/geocoding');
  const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geocodingChannel, (call) async {
          if (call.method == 'placemarkFromCoordinates') {
            return [
              {
                'name': 'Test',
                'street': 'Street',
                'isoCountryCode': 'JP',
                'country': 'Japan',
                'postalCode': '100',
                'administrativeArea': 'Tokyo',
                'subAdministrativeArea': '',
                'locality': 'Tokyo',
                'subLocality': '',
                'thoroughfare': '',
                'subThoroughfare': '',
              },
            ];
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geocodingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null);
  });

  Future<void> pumpCard(
    WidgetTester tester,
    Postcard postcard, {
    bool admin = false,
    int? queuePosition,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostcardCard(
            postcard: postcard,
            isAdminView: admin,
            queuePosition: queuePosition,
          ),
        ),
      ),
    );
  }

  group('PostcardCard Widget Tests', () {
    testWidgets('shows campaign subtitle branch and default icon', (
      tester,
    ) async {
      final postcard = Postcard(
        id: 'campaign-id-1234',
        receiverName: 'Leo',
        address: '123 Test St',
        topic: 'Snow',
        campaign: 'Spring Japan Trip',
        status: 'pending',
      );

      await pumpCard(tester, postcard);

      expect(find.text("To: Leo"), findsOneWidget);
      expect(find.text("Spring Japan Trip • Snow"), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows detailed public tracking fields', (tester) async {
      final postcard = Postcard(
        id: 'public-id-1234',
        receiverName: 'Mia',
        address: '456 Test St',
        topic: 'Comfort',
        status: 'sent',
        stage: 'sent',
        requestDate: DateTime(2026, 1, 10),
        sentDate: DateTime(2026, 1, 20),
        sentCity: 'Osaka',
        travelerNote: 'Wrote this near the river',
        travelerPhotoUrl: 'https://example.com/photo.jpg',
        etaDays: 2,
      );

      await pumpCard(tester, postcard, queuePosition: 4);
      await tester.tap(find.text("To: Mia"));
      await tester.pumpAndSettle();

      expect(find.text("Status: SENT"), findsOneWidget);
      expect(find.text("Journey Stage: SENT"), findsOneWidget);
      expect(find.textContaining("Requested on: 2026-01-10"), findsOneWidget);
      expect(
        find.textContaining("Estimated arrival: 2 day(s)"),
        findsOneWidget,
      );
      expect(
        find.textContaining("Sent on: 2026-01-20 from Osaka"),
        findsOneWidget,
      );
      expect(
        find.textContaining("Traveler note: Wrote this near the river"),
        findsOneWidget,
      );
      expect(find.byType(Image), findsWidgets);
      expect(find.byIcon(Icons.airplanemode_active), findsOneWidget);
      expect(
        find.textContaining("Queue position"),
        findsNothing,
      ); // queue only for pending
    });

    testWidgets('shows queue + received fields and received icon', (
      tester,
    ) async {
      final pending = Postcard(
        id: 'pending-id-1234',
        receiverName: 'A',
        address: 'Addr',
        topic: 'T',
        status: 'pending',
        stage: 'writing',
      );
      await pumpCard(tester, pending, queuePosition: 3);
      await tester.tap(find.text("To: A"));
      await tester.pumpAndSettle();
      expect(find.text("Queue position: #3"), findsOneWidget);

      final received = Postcard(
        id: 'received-id-1234',
        receiverName: 'B',
        address: 'Addr2',
        topic: 'T2',
        status: 'received',
        stage: 'received',
      );
      await pumpCard(tester, received);
      await tester.tap(find.text("To: B"));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('admin view expands and supports manual mark received', (
      tester,
    ) async {
      final sentPostcard = Postcard(
        id: 'test-id-long',
        receiverName: 'Leo',
        address: '123 Test St',
        topic: 'Snow',
        status: 'sent',
      );

      when(
        () => mockFirebaseService.updateStatus(any(), any()),
      ).thenAnswer((_) async {});

      await pumpCard(tester, sentPostcard, admin: true);
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      expect(find.textContaining("WARMTH ID:"), findsOneWidget);
      expect(find.text("W-LONG"), findsOneWidget);
      expect(find.text("Locate & Send"), findsOneWidget);
      expect(find.text("Manual Mark as Received"), findsOneWidget);

      await tester.tap(find.text("Manual Mark as Received"));
      await tester.pumpAndSettle();

      verify(
        () => mockFirebaseService.updateStatus('test-id-long', 'received'),
      ).called(1);
    });

    testWidgets('admin locate & send falls back without location plugin', (
      tester,
    ) async {
      final postcard = Postcard(
        id: 'fallback-id-1234',
        receiverName: 'Leo',
        address: 'Address',
        topic: 'Topic',
        status: 'pending',
      );

      await pumpCard(tester, postcard, admin: true);
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Locate & Send"));
      await tester.pumpAndSettle();

      expect(find.text("Locate & Send"), findsOneWidget);
    });

    testWidgets(
      'admin locate & send uses geolocator and geocoding success path',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(geolocatorChannel, (call) async {
              switch (call.method) {
                case 'checkPermission':
                  return 2; // whileInUse
                case 'requestPermission':
                  return 2; // whileInUse
                case 'getCurrentPosition':
                  return {
                    'latitude': 35.0,
                    'longitude': 139.0,
                    'timestamp': DateTime(
                      2026,
                      1,
                      1,
                    ).millisecondsSinceEpoch.toDouble(),
                    'accuracy': 1.0,
                    'altitude': 0.0,
                    'heading': 0.0,
                    'speed': 0.0,
                    'speed_accuracy': 1.0,
                    'altitude_accuracy': 1.0,
                    'heading_accuracy': 1.0,
                  };
              }
              return null;
            });

        final postcard = Postcard(
          id: 'geo-id-1234',
          receiverName: 'Geo',
          address: 'Address',
          topic: 'Topic',
          status: 'pending',
        );
        when(
          () => mockFirebaseService.updateStatusWithLocation(
            'geo-id-1234',
            'sent',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            city: any(named: 'city'),
          ),
        ).thenAnswer((_) async {});

        await pumpCard(tester, postcard, admin: true);
        await tester.tap(find.text("To: Geo"));
        await tester.pumpAndSettle();

        await tester.tap(find.text("Locate & Send"));
        await tester.pumpAndSettle();

        verify(
          () => mockFirebaseService.updateStatusWithLocation(
            'geo-id-1234',
            'sent',
            lat: 35.0,
            lng: 139.0,
            city: '35.00, 139.00',
          ),
        ).called(1);
      },
    );

    testWidgets('admin journey editor updates service payload', (tester) async {
      final postcard = Postcard(
        id: 'journey-id-1234',
        receiverName: 'Leo',
        address: 'Address',
        topic: 'Topic',
        status: 'pending',
        stage: 'requested',
      );

      when(
        () => mockFirebaseService.updateJourneyProgress(
          any(),
          stage: any(named: 'stage'),
          travelerNote: any(named: 'travelerNote'),
          travelerPhotoUrl: any(named: 'travelerPhotoUrl'),
          etaDays: any(named: 'etaDays'),
        ),
      ).thenAnswer((_) async {});

      await pumpCard(tester, postcard, admin: true);
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Update Journey Details"));
      await tester.pumpAndSettle();
      expect(find.text("Update Journey"), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Writing").last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, "Traveler note"),
        "New note",
      );
      await tester.enterText(
        find.widgetWithText(TextField, "Photo URL (optional)"),
        "https://img.test/p.jpg",
      );
      await tester.enterText(
        find.widgetWithText(TextField, "ETA days (optional)"),
        "7",
      );

      await tester.tap(find.text("Save"));
      await tester.pumpAndSettle();

      verify(
        () => mockFirebaseService.updateJourneyProgress(
          'journey-id-1234',
          stage: 'writing',
          travelerNote: 'New note',
          travelerPhotoUrl: 'https://img.test/p.jpg',
          etaDays: 7,
        ),
      ).called(1);
    });

    testWidgets('admin journey editor cancel closes dialog', (tester) async {
      final postcard = Postcard(
        id: 'journey-cancel-1234',
        receiverName: 'Leo',
        address: 'Address',
        topic: 'Topic',
        status: 'pending',
      );
      when(
        () => mockFirebaseService.updateJourneyProgress(
          any(),
          stage: any(named: 'stage'),
          travelerNote: any(named: 'travelerNote'),
          travelerPhotoUrl: any(named: 'travelerPhotoUrl'),
          etaDays: any(named: 'etaDays'),
        ),
      ).thenAnswer((_) async {});

      await pumpCard(tester, postcard, admin: true);
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Update Journey Details"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      expect(find.text("Update Journey"), findsNothing);
      verifyNever(
        () => mockFirebaseService.updateJourneyProgress(
          any(),
          stage: any(named: 'stage'),
          travelerNote: any(named: 'travelerNote'),
          travelerPhotoUrl: any(named: 'travelerPhotoUrl'),
          etaDays: any(named: 'etaDays'),
        ),
      );
    });

    testWidgets('admin received card supports delete dialog actions', (
      tester,
    ) async {
      final postcard = Postcard(
        id: 'delete-id-1234',
        receiverName: 'Nora',
        address: 'Delete St',
        topic: 'Topic',
        status: 'received',
      );
      when(
        () => mockFirebaseService.deletePostcard('delete-id-1234'),
      ).thenAnswer((_) async {});

      await pumpCard(tester, postcard, admin: true);
      await tester.tap(find.text("To: Nora"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Delete Record (Privacy Clean)"));
      await tester.pumpAndSettle();
      expect(find.text("Confirm Deletion?"), findsOneWidget);

      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(find.text("Confirm Deletion?"), findsNothing);

      await tester.tap(find.text("Delete Record (Privacy Clean)"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Delete Now"));
      await tester.pumpAndSettle();

      verify(
        () => mockFirebaseService.deletePostcard('delete-id-1234'),
      ).called(1);
    });
  });
}
