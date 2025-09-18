// core/services/storage_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _usersDbKey = 'users_database';

  // Save current logged-in user
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  // Get current logged-in user
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }

    return null;
  }

  // Clear current user session
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Save user to users database (for authentication)
  static Future<void> saveUserToDatabase(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDbKey) ?? '{}';
    final Map<String, dynamic> usersDb = jsonDecode(usersJson);

    // Use email as the key for lookup
    usersDb[user.email] = user.toJson();

    await prefs.setString(_usersDbKey, jsonEncode(usersDb));
  }

  // Get user from database by email
  static Future<UserModel?> getUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDbKey);
    if (usersJson != null) {
      final Map<String, dynamic> usersDb = jsonDecode(usersJson);
      final userData = usersDb[email];
      if (userData != null) {
        return UserModel.fromJson(userData);
      }
    }
    return null;
  }

  // Check if email exists in database
  static Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // Validate user credentials
  static Future<UserModel?> validateCredentials(
    String email,
    String password,
  ) async {
    final user = await getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
