import 'dart:async';

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService._();
  static final FirebaseGoogleAuthService instance = FirebaseGoogleAuthService._();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    return {
      'success': false,
      'message': 'Google Sign-In is only supported on Web/Mobile platforms.'
    };
  }
}
