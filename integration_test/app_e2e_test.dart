import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:warmth_from_afar/main.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';
import 'package:warmth_from_afar/widgets/success_dialog.dart';

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

  testWidgets('e2e: tracking and receipt confirmation on chrome', (tester) async {
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

  testWidgets('e2e: request flow shows required-field validation', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Receive Warmth From A Traveller'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Continue to Address'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Please complete name and topic first.'), findsOneWidget);
    verifyNever(
      () => mockFirebaseService.addRequest(
        any(),
        any(),
        any(),
        requestType: any(named: 'requestType'),
        giftFromName: any(named: 'giftFromName'),
        giftMessage: any(named: 'giftMessage'),
        campaign: any(named: 'campaign'),
      ),
    );
  });

  testWidgets('e2e: tracking map/list toggle and sent-only filter', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alice'), findsOneWidget);
    expect(find.textContaining('Bob'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to Map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to List'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to List'));
    await tester.pumpAndSettle();
    expect(find.text('✈️ Sent'), findsOneWidget);
    expect(find.text('⏳ Pending'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bob'), findsOneWidget);
    expect(find.textContaining('Alice'), findsNothing);
  });

  testWidgets('e2e: received flow rejects invalid short id', (tester) async {
    when(
      () => mockFirebaseService.getPostcardByShortId('ZZZZ'),
    ).thenThrow(Exception('Not found'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Received'));
    await tester.pumpAndSettle();
    expect(find.text('Did you receive a postcard?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ZZZZ');
    await tester.tap(find.text('Confirm Arrival ❤️'));
    await tester.pumpAndSettle();

    expect(find.text('Postcard not found. Please check the ID.'), findsOneWidget);
  });

  testWidgets('e2e: success dialog actions copy, share, and open tracking', (
    tester,
  ) async {
    var openedTracking = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SuccessDialog(
                        docId: 'request-id-1234',
                        onOpenTracking: () => openedTracking = true,
                      ),
                    );
                  },
                  child: const Text('Show Success Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success Dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Warmth Requested!'), findsOneWidget);
    expect(find.text('W-1234'), findsOneWidget);

    expect(find.text('Copy ID'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.text('Open Tracking'));
    await tester.pumpAndSettle();
    expect(openedTracking, isTrue);
  });
}
