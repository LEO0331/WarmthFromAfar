import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/views/request_page.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/widgets/success_dialog.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
  });

  group('RequestPage Widget Tests', () {
    testWidgets('should show error snackbar if fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: RequestPage()),
      ));

      await tester.tap(find.textContaining("Send Warmth Request"));
      await tester.pumpAndSettle();

      expect(find.text("Please fill in all fields and pick a topic!"), findsOneWidget);
    });

    testWidgets('should call addRequest and show SuccessDialog on valid submit', (WidgetTester tester) async {
      when(() => mockFirebaseService.addRequest(any(), any(), any()))
          .thenAnswer((_) async => 'new-doc-id');

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: RequestPage()),
      ));

      await tester.enterText(find.byType(TextField).at(0), 'Leo');
      await tester.enterText(find.byType(TextField).at(1), 'Tokyo, Japan');
      
      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      // Select first item
      await tester.tap(find.text("Inspiration (勇氣與啟發)").last);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining("Send Warmth Request"));
      await tester.pumpAndSettle();

      verify(() => mockFirebaseService.addRequest('Leo', 'Tokyo, Japan', 'Inspiration (勇氣與啟發)')).called(1);
      expect(find.byType(SuccessDialog), findsOneWidget);
    });
  });
}
