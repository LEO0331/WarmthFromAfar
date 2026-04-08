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
    when(
      () => mockFirebaseService.getTopicStats(),
    ).thenAnswer((_) async => {'Comfort': 2});
  });

  group('RequestPage Widget Tests', () {
    testWidgets('should show error snackbar if fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RequestPage())),
      );

      await tester.ensureVisible(find.text("Continue to Address"));
      await tester.tap(find.text("Continue to Address"));
      await tester.pumpAndSettle();

      expect(
        find.text("Please complete name and topic first."),
        findsOneWidget,
      );
    });

    testWidgets(
      'should call addRequest and show SuccessDialog on valid submit',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1800));
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
        ).thenAnswer((_) async => 'new-doc-id');

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RequestPage())),
        );

        await tester.enterText(find.byType(TextField).at(0), 'Leo');

        // Open dropdown
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<String>).at(0),
        );
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
        await tester.pumpAndSettle();

        // Select first item
        await tester.tap(find.text("Inspiration (勇氣與啟發)").last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text("Continue to Address"));
        await tester.tap(find.text("Continue to Address"));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Tokyo, Japan');
        await tester.ensureVisible(find.text("Send Warmth Request"));
        await tester.tap(find.text("Send Warmth Request"));
        await tester.pumpAndSettle();

        verify(
          () => mockFirebaseService.addRequest(
            'Leo',
            'Tokyo, Japan',
            'Inspiration (勇氣與啟發)',
            requestType: 'self',
            giftFromName: null,
            giftMessage: null,
            campaign: null,
          ),
        ).called(1);
        expect(find.byType(SuccessDialog), findsOneWidget);
      },
    );

    testWidgets('gift mode requires gift sender name', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RequestPage())),
      );

      await tester.tap(find.text("Gift"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Recipient');

      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).at(0),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Comfort (溫暖與安慰)").last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text("Continue to Address"));
      await tester.tap(find.text("Continue to Address"));
      await tester.pumpAndSettle();

      expect(find.text("Please fill in gift sender name."), findsOneWidget);
    });
  });
}
