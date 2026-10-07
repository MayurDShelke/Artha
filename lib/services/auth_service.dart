import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isFirebaseInitialized = false;

  bool get isFirebaseInitialized => _isFirebaseInitialized;
  FirebaseAuth? get auth => _auth;
  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Initialize Firebase Core safely with DefaultFirebaseOptions
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        // Use configured Firebase options for Android & iOS
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } else {
          await Firebase.initializeApp();
        }
      }
      _auth = FirebaseAuth.instance;
      _isFirebaseInitialized = true;
      try {
        await _googleSignIn.initialize(
          serverClientId: '482402462540-7jc33otan00lq5e9d813e778r845h0ur.apps.googleusercontent.com',
        );
      } catch (e) {
        debugPrint('Google Sign-In initialize notice: $e');
      }
      return true;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
      _isFirebaseInitialized = false;
      return false;
    }
  }

  /// Sign In with Email & Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your project is configured with Firebase.');
    }
    return await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign Up with Email & Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your project is configured with Firebase.');
    }
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return cred;
  }

  /// Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (_auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your project is configured with Firebase.');
    }

    try {
      // Trigger Google Authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Send Password Reset Email
  Future<void> sendPasswordReset(String email) async {
    if (_auth == null) {
      throw Exception('Firebase is not initialized.');
    }
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    if (_auth != null) {
      await _auth!.signOut();
    }
  }
}
