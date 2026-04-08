import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/main.dart';
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

    when(
      () => mockFirebaseService.getPublicPostcards(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockFirebaseService.getTopicStats(),
    ).thenAnswer((_) async => {'Comfort': 1});
    when(() => mockAuthProvider.user).thenReturn(null);
  });

  group('MainNavigator Widget Tests', () {
    testWidgets('should switch tabs on NavigationBar tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const MainNavigator(),
          ),
        ),
      );

      // Initial tab is Request
      expect(find.text("How WanderStamp works"), findsOneWidget);

      // Tap Track tab
      await tester.tap(find.text("Track"));
      await tester.pumpAndSettle();
      expect(find.text("✈️ Sent"), findsOneWidget);

      // Tap Received tab
      await tester.tap(find.text("Received"));
      await tester.pumpAndSettle();
      expect(find.text("Did you receive a postcard?"), findsOneWidget);
    });
  });

  group('WanderStampApp Tests', () {
    testWidgets('should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const WanderStampApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainNavigator), findsOneWidget);
    });
  });
}
