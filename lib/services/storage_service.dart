import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _instructionsKey = 'last_applied_instructions';
  static const String _appConfigKey = 'app_config';
  static const String _lastErrorKey = 'last_error';
  static const String _playbackStatsKey = 'playback_stats';

  // Save instructions to local storage
  static Future<void> saveInstructions(String instructionsJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_instructionsKey, instructionsJson);
      print('Instructions saved successfully');
    } catch (e) {
      print('Error saving instructions: $e');
      throw Exception('Error saving instructions: $e');
    }
  }

  // Get saved instructions from local storage
  static Future<String?> getSavedInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructions = prefs.getString(_instructionsKey);

      if (instructions != null) {
        print('Saved instructions found');
      } else {
        print('No saved instructions found');
      }

      return instructions;
    } catch (e) {
      print('Error loading instructions: $e');
      return null;
    }
  }

  // Clear saved instructions
  static Future<void> clearInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_instructionsKey);
      print('Instructions cleared');
    } catch (e) {
      print('Error clearing instructions: $e');
    }
  }

  // Save last error
  static Future<void> saveLastError(String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastErrorKey, error);
      print('Error saved: $error');
    } catch (e) {
      print('Error saving error: $e');
    }
  }

  // Get last error
  static Future<String?> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastErrorKey);
    } catch (e) {
      print('Error loading last error: $e');
      return null;
    }
  }

  // Clear last error
  static Future<void> clearLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorKey);
      print('Last error cleared');
    } catch (e) {
      print('Error clearing last error: $e');
    }
  }

  // Save app configuration
  static Future<void> saveAppConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config);
      await prefs.setString(_appConfigKey, configJson);
      print('App config saved successfully');
    } catch (e) {
      print('Error saving app config: $e');
    }
  }

  // Get app configuration
  static Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_appConfigKey);

      if (configJson != null) {
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        print('App config loaded');
        return config;
      }

      return null;
    } catch (e) {
      print('Error loading app config: $e');
      return null;
    }
  }

  // Save playback statistics
  static Future<void> savePlaybackStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = jsonEncode(stats);
      await prefs.setString(_playbackStatsKey, statsJson);
      print('Playback stats saved');
    } catch (e) {
      print('Error saving playback stats: $e');
    }
  }

  // Get playback statistics
  static Future<Map<String, dynamic>?> getPlaybackStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_playbackStatsKey);

      if (statsJson != null) {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        print('Playback stats loaded');
        return stats;
      }

      return null;
    } catch (e) {
      print('Error loading playback stats: $e');
      return null;
    }
  }

  // Clear all app data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Check if instructions exist
  static Future<bool> hasSavedInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_instructionsKey);
    } catch (e) {
      print('Error checking instructions: $e');
      return false;
    }
  }

  // Check if app config exists
  static Future<bool> hasAppConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_appConfigKey);
    } catch (e) {
      print('Error checking app config: $e');
      return false;
    }
  }

  // Get storage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructions = await getSavedInstructions();
      final hasInstructions = await hasSavedInstructions();
      final hasConfig = await hasAppConfig();
      final lastError = await getLastError();

      return {
        'hasInstructions': hasInstructions,
        'instructionsLength': instructions?.length ?? 0,
        'lastError': lastError,
        'hasAppConfig': hasConfig,
        'totalKeys': prefs.getKeys().length,
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {
        'hasInstructions': false,
        'instructionsLength': 0,
        'lastError': null,
        'hasAppConfig': false,
        'totalKeys': 0,
      };
    }
  }

  // Get all stored keys (for debugging)
  static Future<List<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().toList();
    } catch (e) {
      print('Error getting storage keys: $e');
      return [];
    }
  }

  // Remove specific key
  static Future<bool> removeKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(key);
      print('Key removed: $key');
      return result;
    } catch (e) {
      print('Error removing key: $e');
      return false;
    }
  }

  // Check if key exists
  static Future<bool> keyExists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      print('Error checking key existence: $e');
      return false;
    }
  }

  // Get string value by key
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting string: $e');
      return null;
    }
  }

  // Set string value by key
  static Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(key, value);
      print('String saved for key: $key');
      return result;
    } catch (e) {
      print('Error setting string: $e');
      return false;
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