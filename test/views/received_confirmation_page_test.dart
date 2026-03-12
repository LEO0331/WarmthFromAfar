import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/views/received_confirmation_page.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/models/postcard.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
  });

  group('ReceivedConfirmationPage Widget Tests', () {
    testWidgets('should show initial form', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(
        home: ReceivedConfirmationPage(),
      ));

      expect(find.text("Did you receive a postcard?"), findsOneWidget);
    });

    testWidgets('should show error if ID is too short', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ReceivedConfirmationPage(),
      ));

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text("Confirm Arrival ❤️"));
      await tester.pump();

      expect(find.text("Please enter at least 4 characters."), findsOneWidget);
    });

    testWidgets('should call updateStatus when valid ID is entered', (WidgetTester tester) async {
      final testPostcard = Postcard(id: 'testid1234', receiverName: 'Leo', address: 'Add', topic: 'Top', status: 'sent');
      
      when(() => mockFirebaseService.getPostcardByShortId('1234'))
          .thenAnswer((_) async => testPostcard);
      when(() => mockFirebaseService.updateStatus('testid1234', 'received'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        initialRoute: '/confirm',
        routes: {
          '/confirm': (context) => const ReceivedConfirmationPage(),
          '/': (context) => const Scaffold(body: Text("Home Screen")),
        },
      ));

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text("Confirm Arrival ❤️"));
      await tester.pump();

      verify(() => mockFirebaseService.getPostcardByShortId('1234')).called(1);
      verify(() => mockFirebaseService.updateStatus('testid1234', 'received')).called(1);
      
      await tester.pumpAndSettle();
      expect(find.text("You made my day!"), findsOneWidget);

      // Test Back to Home
      await tester.tap(find.text("Back to Home"));
      await tester.pumpAndSettle();
      expect(find.text("Home Screen"), findsOneWidget);
    });
  });
}
