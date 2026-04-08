import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warmth_from_afar/main.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockFirebaseService extends Mock implements FirebaseService {}

class FakeFirebaseApp extends Fake implements FirebaseApp {}

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

  group('bootstrapApp Tests', () {
    testWidgets('should call init pipeline and wrap app with provider', (
      WidgetTester tester,
    ) async {
      final callOrder = <String>[];
      Widget? capturedRoot;
      const marker = SizedBox(key: Key('bootstrap-marker'));

      await bootstrapApp(
        ensureInitialized: () {
          callOrder.add('ensure');
          return TestWidgetsFlutterBinding.ensureInitialized();
        },
        initializeFirebase: ({String? name, FirebaseOptions? options}) async {
          callOrder.add('firebase');
          return FakeFirebaseApp();
        },
        runAppFn: (Widget app) {
          callOrder.add('runApp');
          capturedRoot = app;
        },
        app: marker,
      );

      expect(callOrder, ['ensure', 'firebase', 'runApp']);
      expect(capturedRoot, isNotNull);

      await tester.pumpWidget(capturedRoot!);
      expect(find.byType(ChangeNotifierProvider<AuthProvider>), findsOneWidget);
      expect(find.byKey(const Key('bootstrap-marker')), findsOneWidget);
    });

    testWidgets(
      'should use WanderStampApp by default when app is not provided',
      (WidgetTester tester) async {
        Widget? capturedRoot;

        await bootstrapApp(
          ensureInitialized: TestWidgetsFlutterBinding.ensureInitialized,
          initializeFirebase: ({String? name, FirebaseOptions? options}) async {
            return FakeFirebaseApp();
          },
          runAppFn: (Widget app) => capturedRoot = app,
        );

        expect(capturedRoot, isNotNull);
        await tester.pumpWidget(capturedRoot!);
        expect(
          find.byType(ChangeNotifierProvider<AuthProvider>),
          findsOneWidget,
        );
        expect(find.byType(WanderStampApp), findsOneWidget);
      },
    );
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

    testWidgets('onGenerateRoute should navigate to admin and received pages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const WanderStampApp(),
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/admin-login');
      await tester.pumpAndSettle();
      expect(find.text("Admin Access"), findsOneWidget);

      navigator.pushNamed('/received');
      await tester.pumpAndSettle();
      expect(find.text("Did you receive a postcard?"), findsOneWidget);
    });

    testWidgets('root route should apply initial tab and query args', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const WanderStampApp(),
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(
        '/',
        arguments: {'initialTab': 1, 'initialTrackQuery': 'ALICE'},
      );
      await tester.pumpAndSettle();

      expect(find.text("View Sent/Received Only"), findsOneWidget);
      expect(find.text("ALICE"), findsOneWidget);
    });

    testWidgets('root route should fallback when args values are null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const WanderStampApp(),
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(
        '/',
        arguments: {'initialTab': null, 'initialTrackQuery': null},
      );
      await tester.pumpAndSettle();

      expect(find.text("How WanderStamp works"), findsOneWidget);
    });
  });
}
