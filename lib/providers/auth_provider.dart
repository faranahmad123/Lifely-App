import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/firebase_service.dart';
import '../models/user_model.dart';

/// ══════════════════════════════════════════════════════════════════
/// 🔐 LIFELY — AUTH PROVIDER
/// ══════════════════════════════════════════════════════════════════
/// Manages the current user state (login, profile, role detection).
/// All data is fetched from Firebase Auth + Firestore — no dummy data.
/// ══════════════════════════════════════════════════════════════════

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _auth.currentUser != null;
  String get uid => _auth.currentUser?.uid ?? '';

  /// Fetches the user profile from Firestore using the Firebase Auth UID.
  /// Call this after successful login/signup.
  Future<void> fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _firebaseService.getUserProfile(uid);
      _currentUser = user;
    } catch (e) {
      debugPrint('❌ AuthProvider: Error fetching user data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Convenience: fetch data for the currently signed-in user
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await fetchUserData(user.uid);
    }
  }

  /// Sign out and clear the user state
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}


