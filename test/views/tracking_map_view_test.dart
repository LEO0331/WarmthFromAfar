import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:warmth_from_afar/views/tracking_map_view.dart';
import 'package:warmth_from_afar/models/postcard.dart';

class OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}

void main() {
  group('WanderMap Widget Tests', () {
    testWidgets('should render FlutterMap with markers', (
      WidgetTester tester,
    ) async {
      final postcards = [
        Postcard(
          id: '1234',
          receiverName: 'Leo',
          address: 'Add',
          topic: 'Travel',
          status: 'sent',
          lat: 25.0,
          lng: 121.0,
          sentCity: 'Taipei',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WanderMap(
            postcards: postcards,
            tileProvider: OfflineTileProvider(),
          ),
        ),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Check marker icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('should show info sheet on marker tap', (
      WidgetTester tester,
    ) async {
      final postcards = [
        Postcard(
          id: 'testid1234',
          receiverName: 'Leo',
          address: 'Add',
          topic: 'Travel',
          status: 'sent',
          lat: 25.0,
          lng: 121.0,
          sentCity: 'Taipei',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WanderMap(
            postcards: postcards,
            tileProvider: OfflineTileProvider(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.location_on));
      await tester.pumpAndSettle();

      expect(find.textContaining("Sent from Taipei"), findsOneWidget);
      expect(find.text("ID: W-1234"), findsOneWidget);
    });
  });
}
