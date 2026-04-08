import 'package:flutter_test/flutter_test.dart';
import 'package:warmth_from_afar/firebase_options.dart';

void main() {
  group('Firebase options', () {
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
  });
}
