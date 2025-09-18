// Debug script to check storage
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('=== STORAGE DEBUG SCRIPT ===');

  try {
    final prefs = await SharedPreferences.getInstance();

    print('All keys in SharedPreferences: ${prefs.getKeys()}');

    // Check for our specific keys
    final currentUser = prefs.getString('current_user');
    final usersDb = prefs.getString('users_database');

    print('Current user: $currentUser');
    print('Users database: $usersDb');

    if (usersDb != null && usersDb.isNotEmpty) {
      print('Users database content: $usersDb');
    } else {
      print('Users database is empty or null');
    }
  } catch (e) {
    print('Error: $e');
  }
}
