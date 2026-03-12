import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/widgets/postcard_card.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
  });

  group('PostcardCard Widget Tests', () {
    final testPostcard = Postcard(
      id: 'test-doc-id-1234',
      receiverName: 'Leo',
      address: '123 Test St',
      topic: 'Snow',
      status: 'pending',
    );

    testWidgets('should display receiver name and topic', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostcardCard(postcard: testPostcard),
        ),
      ));

      expect(find.text("To: Leo"), findsOneWidget);
      expect(find.text("Topic: Snow"), findsOneWidget);
    });

    testWidgets('should show ExpansionTile children when expanded and in admin mode', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostcardCard(postcard: testPostcard, isAdminView: true),
        ),
      ));

      // Initially collapsed
      expect(find.textContaining("WARMTH ID:"), findsNothing);

      // Expand
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      expect(find.textContaining("WARMTH ID:"), findsOneWidget);
      expect(find.text("W-1234"), findsOneWidget);
      expect(find.text("Locate & Send"), findsOneWidget);
    });

    testWidgets('should call updateStatus when Manual Mark as Received is pressed', (WidgetTester tester) async {
      final sentPostcard = Postcard(
        id: 'test-id-long',
        receiverName: 'Leo',
        address: '123 Test St',
        topic: 'Snow',
        status: 'sent',
      );

      when(() => mockFirebaseService.updateStatus(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostcardCard(postcard: sentPostcard, isAdminView: true),
        ),
      ));

      // Expand
      await tester.tap(find.text("To: Leo"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Manual Mark as Received"));
      await tester.pumpAndSettle();

      verify(() => mockFirebaseService.updateStatus('test-id-long', 'received')).called(1);
    });
  });
}
