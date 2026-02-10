import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:aman_enterprises/services/api_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  static Future<ApiResponse> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        return ApiResponse(
          success: false,
          message: 'Sign in cancelled by user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Successfully signed in to Firebase
        // Now you might want to send this to your backend
        // For now, we'll return a success response with user data
        
        // You can get the token to send to your backend:
        // String? token = await user.getIdToken();
        
        return ApiResponse(
          success: true,
          message: 'Google Sign-In Successful',
          data: {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          // If your backend issues its own token, you'd get it here. 
          // For now we assume the firebase login is enough or we use the firebase ID token?
          // Since the existing ApiService uses a custom token, we might need to backend integration.
          // But as I cannot see backend code, I will stop here for client side.
        ); 
      } else {
        return ApiResponse(
          success: false,
          message: 'Firebase authentication failed',
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return ApiResponse(
        success: false,
        message: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
