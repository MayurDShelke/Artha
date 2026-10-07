import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuestMode = false;
  bool _isInitialized = false;

  AuthState(this._authService) {
    _init();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuestMode => _isGuestMode;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFirebaseAvailable => _authService.isFirebaseInitialized;

  String get displayName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }
    if (_user?.email != null && _user!.email!.isNotEmpty) {
      return _user!.email!.split('@').first;
    }
    return 'Guest User';
  }

  String get email => _user?.email ?? 'Offline / Local';

  String? get photoUrl => _user?.photoURL;

  Future<void> _init() async {
    await _authService.initialize();
    _user = _authService.currentUser;
    _subscription = _authService.authStateChanges.listen((newUser) {
      _user = newUser;
      if (newUser != null) {
        _isGuestMode = false;
      }
      notifyListeners();
    });
    _isInitialized = true;
    notifyListeners();
  }

  void continueAsGuest() {
    _isGuestMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.signInWithEmail(email: email, password: password);
      _user = cred.user;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyMessage(e.code, e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _user = cred.user;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyMessage(e.code, e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null) {
        _user = cred.user;
        _isGuestMode = false;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyMessage(e.code, e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyMessage(e.code, e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _user = null;
    _isGuestMode = false;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getFriendlyMessage(String code, String? defaultMsg) {
    switch (code) {
      case 'user-not-found':
        return 'Account not created yet with this email. Please create an account first!';
      case 'invalid-credential':
        return 'Account not found or password incorrect. If you are new, please create an account first!';
      case 'wrong-password':
        return 'Incorrect password. If you do not have an account yet, please create an account first!';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead!';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment or reset your password.';
      default:
        return defaultMsg ?? 'Authentication error. If you are a new user, please create an account first!';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
