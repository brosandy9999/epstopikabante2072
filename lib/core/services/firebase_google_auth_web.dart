import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService._();
  static final FirebaseGoogleAuthService instance = FirebaseGoogleAuthService._();

  /// Triggers the official Google OAuth / Firebase Auth Popup
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      if (!globalContext.has('firebaseSignInWithGoogle')) {
        return {
          'success': false,
          'message': 'Firebase Google Sign-In SDK उपलब्ध भएन।'
        };
      }

      final JSPromise? promise = globalContext.callMethod('firebaseSignInWithGoogle'.toJS);
      if (promise != null) {
        final result = await promise.toDart;
        if (result != null) {
          final resultStr = (result as JSString).toDart;
          final Map<String, dynamic> parsed = jsonDecode(resultStr);
          return parsed;
        }
      }

      return {
        'success': false,
        'message': 'अज्ञात प्रतिक्रिया प्राप्त भयो।'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Google लगइन गर्न सकिएन: ${e.toString()}'
      };
    }
  }
}
