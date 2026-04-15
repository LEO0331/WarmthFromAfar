import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:warmth_from_afar/main.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseService mockFirebaseService;
  late MockAuthProvider mockAuthProvider;

  final postcards = <Postcard>[
    Postcard(
      id: 'test-postcard-1-8A2C',
      receiverName: 'Alice',
      address: 'Taipei',
      topic: 'Comfort (溫暖與安慰)',
      status: 'pending',
      requestDate: DateTime(2026, 4, 1),
    ),
    Postcard(
      id: 'test-postcard-2-9B7D',
      receiverName: 'Bob',
      address: 'Tokyo',
      topic: 'Travel Story (旅行故事)',
      status: 'sent',
      stage: 'sent',
      sentDate: DateTime(2026, 4, 2),
      lat: 35.6764,
      lng: 139.65,
      sentCity: 'Tokyo',
    ),
  ];

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    mockAuthProvider = MockAuthProvider();
    FirebaseService.setMockInstance(mockFirebaseService);

    when(() => mockAuthProvider.user).thenReturn(null);
    when(
      () => mockFirebaseService.getTopicStats(),
    ).thenAnswer((_) async => {'Comfort (溫暖與安慰)': 1});
    when(
      () => mockFirebaseService.getPublicPostcards(),
    ).thenAnswer((_) => Stream.value(postcards));
    when(
      () => mockFirebaseService.addRequest(
        any(),
        any(),
        any(),
        requestType: any(named: 'requestType'),
        giftFromName: any(named: 'giftFromName'),
        giftMessage: any(named: 'giftMessage'),
        campaign: any(named: 'campaign'),
      ),
    ).thenAnswer((_) async => 'request-id-1234');
    when(
      () => mockFirebaseService.getPostcardByShortId(any()),
    ).thenAnswer((_) async => postcards.first);
    when(
      () => mockFirebaseService.updateStatus(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockFirebaseService.updateReceiptFeedback(
        any(),
        reaction: any(named: 'reaction'),
        message: any(named: 'message'),
        showOnWall: any(named: 'showOnWall'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const WanderStampApp(),
    );
  }

  testWidgets('e2e: tracking and receipt confirmation on chrome', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('How WanderStamp works'), findsOneWidget);

    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();

    expect(find.text('✈️ Sent'), findsOneWidget);
    expect(find.textContaining('Alice'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to Map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to List'), findsOneWidget);

    await tester.tap(find.text('Received'));
    await tester.pumpAndSettle();
    expect(find.text('Did you receive a postcard?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '8A2C');
    await tester.tap(find.text('Confirm Arrival ❤️'));
    await tester.pumpAndSettle();

    expect(find.text('You made my day!'), findsOneWidget);
    verify(() => mockFirebaseService.getPostcardByShortId('8A2C')).called(1);
    verify(
      () =>
          mockFirebaseService.updateStatus('test-postcard-1-8A2C', 'received'),
    ).called(1);
  });
}
