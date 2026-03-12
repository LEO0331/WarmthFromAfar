import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:warmth_from_afar/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    test('Initial user should be null', () {
      final auth = MockFirebaseAuth();
      final provider = AuthProvider(auth: auth);
      expect(provider.user, isNull);
      expect(provider.isAdmin, isFalse);
    });

    test('login should return null on success', () async {
      final auth = MockFirebaseAuth();
      final provider = AuthProvider(auth: auth);
      
      final result = await provider.login('test@example.com', 'password');
      
      // Allow authStateChanges stream to emit
      await Future.delayed(Duration.zero);
      
      expect(result, isNull);
      expect(provider.user, isNotNull);
      expect(provider.isAdmin, isTrue);
    });

    test('logout should clear user', () async {
      final auth = MockFirebaseAuth(signedIn: true);
      final provider = AuthProvider(auth: auth);
      
      // Wait for authStateChanges
      await Future.delayed(Duration.zero);
      expect(provider.user, isNotNull);
      
      await provider.logout();
      expect(provider.user, isNull);
    });
  });
}
