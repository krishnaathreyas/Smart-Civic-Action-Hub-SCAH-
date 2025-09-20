// presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;
  bool _isLoading = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoading => _isLoading;
  // Simple admin check for demo: treat government domains as admin
  bool get isAdmin {
    final email = _currentUser?.email.toLowerCase();
    if (email == null) return false;
    // Simple demo rule: any *.gov or *@springfield.gov is admin
    return email.endsWith('.gov') || email.endsWith('@springfield.gov');
  }

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('=== SESSION LOADING DEBUG ===');
      final userData = await StorageService.getUser();
      debugPrint(
        'Loaded user data: ${userData != null ? "Found user ${userData.name} (${userData.email})" : "No user data found"}',
      );

      if (userData != null) {
        _currentUser = userData;
        _isAuthenticated = true;
        _isOnboardingComplete = true;
        debugPrint('User session restored successfully');
      } else {
        debugPrint('No existing user session found');
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    required String homeAddress,
    required String municipalWard,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('=== CREATE PROFILE DEBUG ===');
      debugPrint('Creating profile for: $name ($email)');

      // Check if email already exists
      final emailExists = await StorageService.emailExists(email);
      debugPrint('Email exists check: $emailExists');

      if (emailExists) {
        throw Exception('An account with this email already exists');
      }

      // In a real app, this would make an API call
      await Future.delayed(const Duration(seconds: 1));

      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        homeAddress: homeAddress,
        municipalWard: municipalWard,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('User model created successfully');

      _currentUser = user;
      _isAuthenticated = true;
      _isOnboardingComplete = true;

      // Save to users database for authentication
      await StorageService.saveUserToDatabase(user);
      // Save as current user session
      await StorageService.saveUser(user);

      debugPrint('Profile creation completed successfully');
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }

  // Simulate signup process
  Future<void> startSignup() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, just mark as "starting signup"
      // In real app, this would validate email/phone and send verification
    } catch (e) {
      debugPrint('Error starting signup: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign in with improved error handling and debugging
  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('=== SIGN IN DEBUG ===');
      debugPrint('Attempting to sign in with email: $email');

      // Check if email exists first
      final emailExists = await StorageService.emailExists(email);
      debugPrint('Email exists in database: $emailExists');

      if (!emailExists) {
        debugPrint('Email not found in database');
        throw Exception(
          'No account found with this email. Please sign up first.',
        );
      }

      // Validate credentials against stored users
      final user = await StorageService.validateCredentials(email, password);
      debugPrint(
        'User validation result: ${user != null ? "Success" : "Failed"}',
      );

      if (user == null) {
        debugPrint('Password validation failed');
        throw Exception(
          'Invalid password. Please check your password and try again.',
        );
      }

      debugPrint('Sign in successful for user: ${user.name}');

      _currentUser = user;
      _isAuthenticated = true;
      _isOnboardingComplete = true;

      // Save as current user session
      await StorageService.saveUser(user);
      debugPrint('User session saved successfully');
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  } // Simulate login process (legacy method)

  Future<void> startLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, skip to creating a demo user
      // In real app, this would validate credentials
    } catch (e) {
      debugPrint('Error starting login: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, this would make an API call
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        updatedAt: DateTime.now(),
      );

      // Save to local storage
      await StorageService.saveUser(_currentUser!);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateReputation(int points) async {
    if (_currentUser == null) return;

    final newPoints = _currentUser!.reputationPoints + points;
    final newVoteWeight = _calculateVoteWeight(newPoints);
    final newTier = _getReputationTier(newPoints);

    _currentUser = _currentUser!.copyWith(
      reputationPoints: newPoints,
      voteWeight: newVoteWeight,
      reputationTier: newTier,
      updatedAt: DateTime.now(),
    );

    // Save to local storage
    await StorageService.saveUser(_currentUser!);
    notifyListeners();
  }

  double _calculateVoteWeight(int reputationPoints) {
    if (reputationPoints < 50) return 0.5;
    if (reputationPoints < 100) return 1.0;
    if (reputationPoints < 500) return 1.5;
    if (reputationPoints < 1000) return 2.0;
    if (reputationPoints < 2500) return 2.5;
    return 3.0;
  }

  String _getReputationTier(int points) {
    if (points >= 2500) return 'Diamond';
    if (points >= 1000) return 'Platinum';
    if (points >= 500) return 'Gold';
    if (points >= 100) return 'Silver';
    return 'Bronze';
  }

  Future<void> signOut() async {
    debugPrint('=== SIGNING OUT ===');
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboardingComplete = false;

    await StorageService.clearUser();
    debugPrint('User signed out successfully');
    notifyListeners();
  }

  // Debug method to clear all user data
  Future<void> clearAllUserData() async {
    debugPrint('=== CLEARING ALL USER DATA ===');
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboardingComplete = false;

    await StorageService.clearAllData();
    debugPrint('All user data cleared');
    notifyListeners();
  }
}
