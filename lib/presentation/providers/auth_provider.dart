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

  AuthProvider() {
    _loadUserFromStorage();
  }
  // Add this method to your AuthProvider class
  void resetOnboarding() {
    _isOnboardingComplete = false;
    notifyListeners();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await StorageService.getUser();
      if (userData != null) {
        _currentUser = userData;
        _isAuthenticated = true;
        _isOnboardingComplete = true;
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
    String? phoneNumber,
    required String homeAddress,
    required String municipalWard,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, this would make an API call
      await Future.delayed(const Duration(seconds: 2));

      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        homeAddress: homeAddress,
        municipalWard: municipalWard,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = user;
      _isAuthenticated = true;

      // Save to local storage
      await StorageService.saveUser(user);
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

  // Modify the startSignup method:
  Future<void> startSignup() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Set authenticated to true
      _isAuthenticated = true; // Add this line
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting signup: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Similarly modify the startLogin method:
  Future<void> startLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Set authenticated to true
      _isAuthenticated = true; // Add this line
      notifyListeners();
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
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboardingComplete = false;

    await StorageService.clearUser();
    notifyListeners();
  }
}
