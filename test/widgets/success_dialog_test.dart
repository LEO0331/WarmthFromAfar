import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmth_from_afar/widgets/success_dialog.dart';

void main() {
  group('SuccessDialog Widget Tests', () {
    testWidgets('should display the short ID correctly', (
      WidgetTester tester,
    ) async {
      const fullId = 'long-firebase-doc-id-1234';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SuccessDialog(docId: fullId)),
        ),
      );

      // Wait for TweenAnimation
      await tester.pumpAndSettle();

      expect(find.text("W-1234"), findsOneWidget);
      expect(find.text("Warmth Requested!"), findsOneWidget);
    });

    testWidgets('should close when "Open Tracking" is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          const SuccessDialog(docId: 'test-id'),
                    );
                  },
                  child: const Text("Show"),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessDialog), findsOneWidget);

      await tester.tap(find.text("Open Tracking"));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessDialog), findsNothing);
    });

    testWidgets('should copy ID action is visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SuccessDialog(docId: 'test-doc-id-1234')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Copy ID"), findsOneWidget);
      expect(find.text("Share"), findsOneWidget);
    });

    testWidgets('copy and share actions show snackbars', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SuccessDialog(docId: 'test-doc-id-5678')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Copy ID"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Share"));
      await tester.pumpAndSettle();
    });

    testWidgets('uses custom open tracking callback when provided', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              docId: 'test-doc-id-9876',
              onOpenTracking: () => called = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Open Tracking"));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
