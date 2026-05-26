import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';
import 'package:warmth_from_afar/main.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';
import 'package:warmth_from_afar/services/firebase_service.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  PatrolBinding.ensureInitialized(NativeAutomatorConfig());

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
    Postcard(
      id: 'request-id-1234',
      receiverName: 'Charlie',
      address: 'Berlin, Germany',
      topic: 'Inspiration (勇氣與啟發)',
      status: 'pending',
      requestDate: DateTime(2026, 4, 3),
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

  patrolTest('e2e: tracking and receipt confirmation (mobile patrol)', (
    $,
  ) async {
    await $.pumpWidgetAndSettle(buildApp());

    expect(find.text('How WanderStamp works'), findsOneWidget);

    await $('Track').tap();
    await $.pumpAndSettle();

    expect(find.text('✈️ Sent'), findsOneWidget);
    expect(find.textContaining('Alice'), findsOneWidget);

    await $(find.byTooltip('Switch to Map')).tap();
    await $.pumpAndSettle();
    expect(find.byTooltip('Switch to List'), findsOneWidget);

    await $('Received').tap();
    await $.pumpAndSettle();
    expect(find.text('Did you receive a postcard?'), findsOneWidget);

    await $(TextField).first.enterText('8A2C');
    await $('Confirm Arrival ❤️').tap();
    await $.pumpAndSettle();

    expect(find.text('You made my day!'), findsOneWidget);
    verify(() => mockFirebaseService.getPostcardByShortId('8A2C')).called(1);
    verify(
      () =>
          mockFirebaseService.updateStatus('test-postcard-1-8A2C', 'received'),
    ).called(1);
  });

  patrolTest('e2e: request success opens tracking (mobile patrol)', ($) async {
    await $.pumpWidgetAndSettle(buildApp());

    await $(TextField).first.enterText('Charlie');
    await $(DropdownButtonFormField<String>).first.tap();
    await $.pumpAndSettle();
    await $('Inspiration (勇氣與啟發)').last.tap();
    await $.pumpAndSettle();

    await $('Continue to Address').scrollTo();
    await $('Continue to Address').tap();
    await $.pumpAndSettle();

    await $(TextField).first.enterText('Berlin, Germany');
    await $('Send Warmth Request').scrollTo();
    await $('Send Warmth Request').tap();
    await $.pump(const Duration(milliseconds: 900));

    expect(find.text('Warmth Requested!'), findsOneWidget);
    expect(find.text('W-1234'), findsOneWidget);
    verify(
      () => mockFirebaseService.addRequest(
        'Charlie',
        'Berlin, Germany',
        'Inspiration (勇氣與啟發)',
        requestType: 'self',
        giftFromName: null,
        giftMessage: null,
        campaign: null,
      ),
    ).called(1);

    await $('Open Tracking').tap();
    await $.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Charlie'), findsOneWidget);
  });
}
