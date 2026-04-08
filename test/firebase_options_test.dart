import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmth_from_afar/firebase_options.dart';

void main() {
  group('Firebase options', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('platform constants are configured', () {
      expect(DefaultFirebaseOptions.web.projectId, isNotEmpty);
      expect(DefaultFirebaseOptions.android.projectId, isNotEmpty);
      expect(DefaultFirebaseOptions.ios.projectId, isNotEmpty);
      expect(DefaultFirebaseOptions.macos.projectId, isNotEmpty);
      expect(DefaultFirebaseOptions.windows.projectId, isNotEmpty);
    });

    test('currentPlatform is resolvable or intentionally unsupported', () {
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        expect(options.projectId, isNotEmpty);
      } on UnsupportedError catch (e) {
        // Linux path is an accepted, explicit branch in generated options.
        expect(e.message.toString(), contains('not been configured for linux'));
      }
    });

    test('currentPlatform resolves explicit platform branches', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        DefaultFirebaseOptions.currentPlatform.projectId,
        DefaultFirebaseOptions.android.projectId,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        DefaultFirebaseOptions.currentPlatform.projectId,
        DefaultFirebaseOptions.ios.projectId,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(
        DefaultFirebaseOptions.currentPlatform.projectId,
        DefaultFirebaseOptions.macos.projectId,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        DefaultFirebaseOptions.currentPlatform.projectId,
        DefaultFirebaseOptions.windows.projectId,
      );
    });

    test(
      'currentPlatform throws expected errors for unsupported platforms',
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message.toString(),
              'message',
              contains('not been configured for linux'),
            ),
          ),
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message.toString(),
              'message',
              contains('not supported for this platform'),
            ),
          ),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
