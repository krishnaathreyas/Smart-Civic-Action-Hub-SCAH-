import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/storage_service.dart';

class DebugStorageScreen extends StatefulWidget {
  const DebugStorageScreen({super.key});

  @override
  _DebugStorageScreenState createState() => _DebugStorageScreenState();
}

class _DebugStorageScreenState extends State<DebugStorageScreen> {
  String _debugOutput = '';

  void _addToOutput(String text) {
    setState(() {
      _debugOutput += '$text\n';
    });
  }

  Future<void> _clearOutput() async {
    setState(() {
      _debugOutput = '';
    });
  }

  Future<void> _showAllData() async {
    _addToOutput('=== SHOWING ALL STORED DATA ===');
    // We need to capture the debug output, so let me recreate the logic here
    final prefs = await SharedPreferences.getInstance();

    _addToOutput('Current user session: ${prefs.getString('current_user')}');
    _addToOutput('Users database: ${prefs.getString('users_database')}');

    final allKeys = prefs.getKeys();
    _addToOutput('All SharedPreferences keys: $allKeys');
  }

  Future<void> _clearAllData() async {
    _addToOutput('=== CLEARING ALL DATA ===');
    await StorageService.clearAllData();
    _addToOutput('All data cleared');
  }

  Future<void> _saveTestUser() async {
    _addToOutput('=== SAVING TEST USER ===');
    await StorageService.debugSaveTestUser();
    _addToOutput('Test user saved');
  }

  Future<void> _checkUserExists() async {
    _addToOutput('=== CHECKING IF USER EXISTS ===');
    final user = await StorageService.getUserByEmail(
      'mallanagoudapolicepatil9@gmail.com',
    );
    if (user != null) {
      _addToOutput('User found: ${user.name} (${user.email})');
    } else {
      _addToOutput('User NOT found');
    }
  }

  Future<void> _validateCredentials() async {
    _addToOutput('=== VALIDATING CREDENTIALS ===');
    final isValid = await StorageService.validateCredentials(
      'mallanagoudapolicepatil9@gmail.com',
      '123456',
    );
    _addToOutput('Credentials valid: $isValid');
  }

  Future<void> _inspectStoredUser() async {
    _addToOutput('=== INSPECTING STORED USER ===');
    final user = await StorageService.getUserByEmail(
      'mallanagoudapolicepatil9@gmail.com',
    );
    if (user != null) {
      _addToOutput('User Name: ${user.name}');
      _addToOutput('User Email: ${user.email}');
      _addToOutput('Stored Password: "${user.password}"');
      _addToOutput('Password Length: ${user.password.length}');
      _addToOutput('Password Bytes: ${user.password.codeUnits}');
      _addToOutput('Test Password: "123456"');
      _addToOutput('Test Password Bytes: ${"123456".codeUnits}');
      _addToOutput('Direct Match: ${user.password == "123456"}');
    } else {
      _addToOutput('No user found with that email');
    }
  }

  Future<void> _migrateDatabaseFormat() async {
    _addToOutput('=== MIGRATING DATABASE FORMAT ===');
    await StorageService.migrateDatabaseFormat();
    _addToOutput('Migration completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Storage')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: _showAllData,
                  child: const Text('Show All Data'),
                ),
                ElevatedButton(
                  onPressed: _clearAllData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear All Data'),
                ),
                ElevatedButton(
                  onPressed: _saveTestUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Save Test User'),
                ),
                ElevatedButton(
                  onPressed: _checkUserExists,
                  child: const Text('Check User Exists'),
                ),
                ElevatedButton(
                  onPressed: _validateCredentials,
                  child: const Text('Validate Credentials'),
                ),
                ElevatedButton(
                  onPressed: _inspectStoredUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('Inspect User'),
                ),
                ElevatedButton(
                  onPressed: _migrateDatabaseFormat,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Migrate DB Format'),
                ),
                ElevatedButton(
                  onPressed: _clearOutput,
                  child: const Text('Clear Output'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty
                        ? 'No debug output yet...'
                        : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
