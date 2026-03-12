import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:warmth_from_afar/views/admin/admin_login.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

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

  group('AdminLoginPage Widget Tests', () {
    testWidgets('should show login fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AdminLoginPage(),
        ),
      ));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text("Login"), findsOneWidget);
    });

    testWidgets('should call login on button press', (WidgetTester tester) async {
       when(() => mockAuthProvider.login(any(), any()))
          .thenAnswer((_) async => null);
       when(() => mockFirebaseService.getPublicPostcards())
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AdminLoginPage(),
        ),
      ));

      await tester.enterText(find.byType(TextField).at(0), 'admin@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(() => mockAuthProvider.login('admin@test.com', 'password')).called(1);
    });
  });
}
