import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService._();
  static final FirebaseGoogleAuthService instance = FirebaseGoogleAuthService._();

  /// Triggers the official Google OAuth / Firebase Auth Popup
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final jsFn = js_util.getProperty(html.window, 'firebaseSignInWithGoogle');
      if (jsFn == null) {
        return {
          'success': false,
          'message': 'Firebase Google Sign-In SDK उपलब्ध भएन।'
        };
      }

      final promise = js_util.callMethod(html.window, 'firebaseSignInWithGoogle', []);
      final resultJson = await js_util.promiseToFuture(promise);

      if (resultJson is String) {
        final Map<String, dynamic> parsed = jsonDecode(resultJson);
        return parsed;
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
