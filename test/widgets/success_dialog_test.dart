import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmth_from_afar/widgets/success_dialog.dart';

void main() {
  group('SuccessDialog Widget Tests', () {
    testWidgets('should display the short ID correctly', (WidgetTester tester) async {
      const fullId = 'long-firebase-doc-id-1234';
      
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SuccessDialog(docId: fullId),
        ),
      ));
      
      // Wait for TweenAnimation
      await tester.pumpAndSettle();

      expect(find.text("W-1234"), findsOneWidget);
      expect(find.text("Warmth Requested!"), findsOneWidget);
    });

    testWidgets('should close when "Got it!" is pressed', (WidgetTester tester) async {
       await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SuccessDialog(docId: 'test-id'),
                  );
                },
                child: const Text("Show"),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessDialog), findsOneWidget);

      await tester.tap(find.text("Got it!"));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessDialog), findsNothing);
    });
  });
}
