import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _instructionsKey = 'last_applied_instructions';
  static const String _appConfigKey = 'app_config';
  static const String _lastErrorKey = 'last_error';

  // Save instructions to local storage
  static Future<void> saveInstructions(String instructionsJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_instructionsKey, instructionsJson);
      print('নির্দেশনা সফলভাবে সেভ করা হয়েছে');
    } catch (e) {
      print('নির্দেশনা সেভ করতে সমস্যা: $e');
      throw Exception('নির্দেশনা সেভ করতে সমস্যা: $e');
    }
  }

  // Get saved instructions from local storage
  static Future<String?> getSavedInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructions = prefs.getString(_instructionsKey);

      if (instructions != null) {
        print('সেভ করা নির্দেশনা পাওয়া গেছে');
      } else {
        print('কোনো সেভ করা নির্দেশনা পাওয়া যায়নি');
      }

      return instructions;
    } catch (e) {
      print('নির্দেশনা লোড করতে সমস্যা: $e');
      return null;
    }
  }

  // Clear saved instructions
  static Future<void> clearInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_instructionsKey);
      print('নির্দেশনা ক্লিয়ার করা হয়েছে');
    } catch (e) {
      print('নির্দেশনা ক্লিয়ার করতে সমস্যা: $e');
    }
  }

  // Save last error
  static Future<void> saveLastError(String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastErrorKey, error);
      print('Error সেভ করা হয়েছে: $error');
    } catch (e) {
      print('Error সেভ করতে সমস্যা: $e');
    }
  }

  // Get last error
  static Future<String?> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastErrorKey);
    } catch (e) {
      print('Error লোড করতে সমস্যা: $e');
      return null;
    }
  }

  // Clear last error
  static Future<void> clearLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorKey);
      print('Error ক্লিয়ার করা হয়েছে');
    } catch (e) {
      print('Error ক্লিয়ার করতে সমস্যা: $e');
    }
  }

  // Save app configuration
  static Future<void> saveAppConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config);
      await prefs.setString(_appConfigKey, configJson);
      print('অ্যাপ কনফিগ সফলভাবে সেভ করা হয়েছে');
    } catch (e) {
      print('অ্যাপ কনফিগ সেভ করতে সমস্যা: $e');
    }
  }

  // Get app configuration
  static Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_appConfigKey);

      if (configJson != null) {
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        print('অ্যাপ কনফিগ লোড করা হয়েছে');
        return config;
      }

      return null;
    } catch (e) {
      print('অ্যাপ কনফিগ লোড করতে সমস্যা: $e');
      return null;
    }
  }

  // Clear all app data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('সমস্ত ডাটা ক্লিয়ার করা হয়েছে');
    } catch (e) {
      print('ডাটা ক্লিয়ার করতে সমস্যা: $e');
    }
  }

  // Check if instructions exist
  static Future<bool> hasSavedInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_instructionsKey);
    } catch (e) {
      print('নির্দেশনা চেক করতে সমস্যা: $e');
      return false;
    }
  }

  // Get storage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructions = await getSavedInstructions();
      final hasInstructions = await hasSavedInstructions();

      return {
        'hasInstructions': hasInstructions,
        'instructionsLength': instructions?.length ?? 0,
        'lastError': await getLastError(),
        'hasAppConfig': prefs.containsKey(_appConfigKey),
      };
    } catch (e) {
      print('স্টোরেজ তথ্য পাওয়ার过程中 সমস্যা: $e');
      return {
        'hasInstructions': false,
        'instructionsLength': 0,
        'lastError': null,
        'hasAppConfig': false,
      };
    }
  }
}

// JSON encode/decode helper functions
String jsonEncode(Map<String, dynamic> map) {
  return json.encode(map);
}

Map<String, dynamic> jsonDecode(String jsonString) {
  return json.decode(jsonString) as Map<String, dynamic>;
}