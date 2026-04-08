import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmth_from_afar/models/postcard.dart';
import 'package:warmth_from_afar/widgets/wall_of_warmth.dart';

void main() {
  group('WallOfWarmth Widget Tests', () {
    testWidgets('renders nothing when no eligible messages', (tester) async {
      final postcards = [
        Postcard(
          id: 'a',
          receiverName: 'A',
          address: 'Addr',
          topic: 'Topic',
          status: 'received',
          showOnWall: false,
          recipientReaction: '❤️',
          recipientMessage: 'Hello',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WallOfWarmth(postcards: postcards)),
        ),
      );

      expect(find.text("Wall of Warmth"), findsNothing);
    });

    testWidgets('renders up to six eligible messages', (tester) async {
      final postcards = List.generate(
        7,
        (i) => Postcard(
          id: 'postcard-id-$i',
          receiverName: 'U$i',
          address: 'Addr$i',
          topic: 'Topic',
          status: 'received',
          showOnWall: true,
          recipientReaction: '😊',
          recipientMessage: 'Message $i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WallOfWarmth(postcards: postcards)),
        ),
      );

      expect(find.text("Wall of Warmth"), findsOneWidget);
      expect(find.text("Shared reactions from recipients"), findsOneWidget);
      expect(find.textContaining("Message"), findsNWidgets(6));
      expect(find.text("Message 6"), findsNothing);
    });
  });
}
