import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Firebase Auth Service — handles Google Sign-In and auth state.
/// Replaces the old Google-Drive-only AuthService.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  /// Stream untuk listen auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get ID Token Result (untuk Custom Claims)
  Future<IdTokenResult?> getIdTokenResult({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;
    return await user.getIdTokenResult(forceRefresh);
  }

  /// Get Current Role from Custom Claims
  Future<String?> getCurrentUserRole() async {
    final result = await getIdTokenResult(forceRefresh: true);
    return result?.claims?['role'] as String?;
  }

  /// Get Current BengkelId from Custom Claims
  Future<String?> getCurrentUserBengkelId() async {
    final result = await getIdTokenResult(forceRefresh: true);
    return result?.claims?['bengkelId'] as String?;
  }

  /// Legacy alias for signInWithGoogle
  Future<UserCredential?> signIn() => signInWithGoogle();

  /// Google Sign-In → Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Silent sign-in (auto-login on app restart)
  Future<UserCredential?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Silent Sign-In Error: $e');
      return null;
    }
  }

  /// Sign Out — clears both Google + Firebase sessions
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get Authenticated HTTP Client for Google APIs (Drive)
  Future<http.Client> getAuthenticatedClient() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      final signinResult = await _googleSignIn.signIn();
      if (signinResult == null) throw Exception('Google Sign-In failed or cancelled');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('Failed to get authenticated client');
    return client;
  }
}
