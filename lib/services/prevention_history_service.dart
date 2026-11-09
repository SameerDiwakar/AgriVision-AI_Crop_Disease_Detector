import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prevention_model.dart';

/// Service to handle persistent local storage of weather-driven disease prevention assessments.
class PreventionHistoryService {
  static const String _storageKey = 'agri_vision_prevention_history';

  /// Save a new prevention evaluation record (newest first)
  static Future<void> saveRecord(PreventionHistoryRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<PreventionHistoryRecord> current = await getRecords();

      // Avoid duplicates
      current.removeWhere((item) => item.id == record.id);
      current.insert(0, record);

      final List<String> encoded =
          current.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_storageKey, encoded);
    } catch (e) {
      print('Error saving prevention assessment: $e');
    }
  }

  /// Retrieve all saved prevention records sorted newest first
  static Future<List<PreventionHistoryRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? rawList = prefs.getStringList(_storageKey);

      if (rawList == null || rawList.isEmpty) {
        return [];
      }

      final List<PreventionHistoryRecord> records = [];
      for (final jsonStr in rawList) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          records.add(PreventionHistoryRecord.fromJson(map));
        } catch (e) {
          print('Error parsing prevention history JSON: $e');
        }
      }

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      print('Error loading prevention history: $e');
      return [];
    }
  }

  /// Delete a record by ID
  static Future<bool> deleteRecord(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<PreventionHistoryRecord> current = await getRecords();

      final int before = current.length;
      current.removeWhere((item) => item.id == id);

      if (current.length != before) {
        final List<String> encoded =
            current.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList(_storageKey, encoded);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting prevention record: $e');
      return false;
    }
  }

  /// Clear all prevention history
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing prevention history: $e');
    }
  }
}

