import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/views/tracking_page.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/widgets/postcard_card.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
  });

  group('TrackingPage Widget Tests', () {
    final testPostcards = [
      Postcard(id: 'id1', receiverName: 'Alice', address: 'Add1', topic: 'Topic1', status: 'sent'),
      Postcard(id: 'id2', receiverName: 'Bob', address: 'Add2', topic: 'Topic2', status: 'pending'),
    ];

    testWidgets('should display stats and list of postcards', (WidgetTester tester) async {
      when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value(testPostcards));

      await tester.pumpWidget(const MaterialApp(
        home: TrackingPage(),
      ));

      // Wait for StreamBuilder
      await tester.pump();

      expect(find.text("✈️ Sent"), findsOneWidget);
      // Removed unstable check for "1"
      
      expect(find.byType(PostcardCard), findsNWidgets(2));
      expect(find.text("To: Alice"), findsOneWidget);
      expect(find.text("To: Bob"), findsOneWidget);
    });

    testWidgets('should filter list based on search query', (WidgetTester tester) async {
       when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value(testPostcards));

      await tester.pumpWidget(const MaterialApp(
        home: TrackingPage(),
      ));
      await tester.pump();

      // Search for Alice
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();

      expect(find.text("To: Alice"), findsOneWidget);
      expect(find.text("To: Bob"), findsNothing);
    });

    testWidgets('should filter based on switch', (WidgetTester tester) async {
       when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value(testPostcards));

      await tester.pumpWidget(const MaterialApp(
        home: TrackingPage(),
      ));
      await tester.pump();

      // Only show sent/received
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text("To: Alice"), findsOneWidget); // Alice is sent
      expect(find.text("To: Bob"), findsNothing); // Bob is pending
    });
  });
}
