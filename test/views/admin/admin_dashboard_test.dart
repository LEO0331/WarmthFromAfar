import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:warmth_from_afar/views/admin/admin_dashboard.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/widgets/postcard_card.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockFirebaseService = MockFirebaseService();
    FirebaseService.setMockInstance(mockFirebaseService);
  });

  group('AdminDashboard Widget Tests', () {
    testWidgets('should show list in admin mode', (WidgetTester tester) async {
       when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value([
            Postcard(id: 'testid1', receiverName: 'Alice', address: 'Add1', topic: 'Topic1', status: 'pending'),
          ]));

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AdminDashboard(),
        ),
      ));
      await tester.pump();

      expect(find.byType(PostcardCard), findsOneWidget);
    });

    testWidgets('should logout when logout button is pressed', (WidgetTester tester) async {
       when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value([]));
       when(() => mockAuthProvider.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        initialRoute: '/dashboard',
        routes: {
          '/': (context) => const Text("Home Screen"),
          '/dashboard': (context) => ChangeNotifierProvider<AuthProvider>.value(
                value: mockAuthProvider,
                child: const AdminDashboard(),
              ),
        },
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      verify(() => mockAuthProvider.logout()).called(1);
      expect(find.text("Home Screen"), findsOneWidget);
    });
  });
}
