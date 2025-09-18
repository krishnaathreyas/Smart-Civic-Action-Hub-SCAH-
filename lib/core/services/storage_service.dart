// core/services/storage_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _usersDbKey = 'users_database';

  // Save current logged-in user
  static Future<void> saveUser(UserModel user) async {
    print('=== SAVING CURRENT USER SESSION ===');
    print('Saving session for: ${user.name} (${user.email})');

    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    print('User session saved successfully');
  }

  // Get current logged-in user
  static Future<UserModel?> getUser() async {
    print('=== LOADING CURRENT USER SESSION ===');

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    print('Session data: ${userJson != null ? "Found" : "Not found"}');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        print('Loaded user: ${user.name} (${user.email})');
        return user;
      } catch (e) {
        print('Error parsing user session: $e');
        return null;
      }
    }

    print('No user session found');
    return null;
  }

  // Clear current user session
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Save user to users database (for authentication)
  static Future<void> saveUserToDatabase(UserModel user) async {
    print('=== SAVING USER TO DATABASE ===');
    print('Saving user: ${user.name} (${user.email})');

    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_usersDbKey);

    Map<String, dynamic> usersDb;

    if (existingJson == null || existingJson.isEmpty) {
      // First user - create new database
      usersDb = {};
    } else {
      try {
        final decoded = jsonDecode(existingJson);

        // Handle both old List format and new Map format
        if (decoded is List) {
          print('Converting old List format to Map format');
          usersDb = {};
          for (var userJson in decoded) {
            final existingUser = UserModel.fromJson(userJson);
            usersDb[existingUser.email] = existingUser.toJson();
          }
        } else if (decoded is Map<String, dynamic>) {
          usersDb = decoded;
        } else {
          print('Unknown database format, creating new one');
          usersDb = {};
        }
      } catch (e) {
        print('Error parsing existing database: $e, creating new one');
        usersDb = {};
      }
    }

    // Use email as the key for lookup
    usersDb[user.email] = user.toJson();

    await prefs.setString(_usersDbKey, jsonEncode(usersDb));
    print('User saved to database successfully');
    print('Database now contains ${usersDb.length} users');
  }

  // Get user from database by email
  static Future<UserModel?> getUserByEmail(String email) async {
    print('=== GETTING USER BY EMAIL ===');
    print('Looking for email: $email');

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDbKey);
    print('Users database JSON: $usersJson');

    if (usersJson != null) {
      final Map<String, dynamic> usersDb = jsonDecode(usersJson);
      print('Available emails in database: ${usersDb.keys.toList()}');

      final userData = usersDb[email];
      if (userData != null) {
        print('Found user data for $email');
        return UserModel.fromJson(userData);
      } else {
        print('No user data found for $email');
      }
    } else {
      print('Users database is empty');
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
    print('=== STORAGE VALIDATION DEBUG ===');
    print('Validating credentials for email: $email');

    final user = await getUserByEmail(email);
    print('Found user: ${user != null ? "Yes - ${user.name}" : "No"}');

    if (user != null) {
      print('Stored password: "${user.password}"');
      print('Input password: "$password"');
      print('Stored password length: ${user.password.length}');
      print('Input password length: ${password.length}');
      print('Password match: ${user.password == password}');

      // Check for common issues
      if (user.password.trim() == password.trim()) {
        print('ISSUE: Passwords match when trimmed - there are extra spaces');
      }
      if (user.password.toLowerCase() == password.toLowerCase()) {
        print(
          'ISSUE: Passwords match when lowercased - case sensitivity issue',
        );
      }

      if (user.password == password) {
        print('✅ Password validation SUCCESSFUL');
        return user;
      } else {
        print('❌ Password validation FAILED');
      }
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

  // Clear all user data (for debugging/testing)
  static Future<void> clearAllData() async {
    print('=== CLEARING ALL DATA ===');
    final prefs = await SharedPreferences.getInstance();

    // Clear current user session
    await prefs.remove(_userKey);
    // Clear users database
    await prefs.remove(_usersDbKey);

    print('All data cleared successfully');
  }

  // Debug method to show all stored data
  static Future<void> debugShowAllData() async {
    print('=== DEBUG: SHOWING ALL STORED DATA ===');
    final prefs = await SharedPreferences.getInstance();

    print('Current user session: ${prefs.getString(_userKey)}');
    print('Users database: ${prefs.getString(_usersDbKey)}');

    final allKeys = prefs.getKeys();
    print('All SharedPreferences keys: $allKeys');
  }

  // Method to manually save a test user (for debugging)
  static Future<void> debugSaveTestUser() async {
    print('=== SAVING TEST USER FOR DEBUG ===');
    final testUser = UserModel(
      id: 'test_123',
      name: 'Test User',
      email: 'mallanagoudapolicepatil9@gmail.com',
      password: '123456',
      homeAddress: 'Test Address',
      municipalWard: 'Test Ward',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveUserToDatabase(testUser);
    print('Test user saved successfully');
  }

  // Migrate old List format to new Map format
  static Future<void> migrateDatabaseFormat() async {
    print('=== MIGRATING DATABASE FORMAT ===');
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_usersDbKey);

    if (existingJson == null || existingJson.isEmpty) {
      print('No existing database to migrate');
      return;
    }

    try {
      final decoded = jsonDecode(existingJson);

      if (decoded is List) {
        print('Found old List format, converting to Map format');
        final Map<String, dynamic> newDb = {};

        for (var userJson in decoded) {
          final user = UserModel.fromJson(userJson);
          newDb[user.email] = user.toJson();
        }

        await prefs.setString(_usersDbKey, jsonEncode(newDb));
        print('Migration completed. Database now has ${newDb.length} users');
      } else {
        print('Database is already in Map format');
      }
    } catch (e) {
      print('Error during migration: $e');
    }
  }
}
