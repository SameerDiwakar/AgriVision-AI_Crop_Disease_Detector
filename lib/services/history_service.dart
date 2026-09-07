import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_record.dart';

/// Service to handle persistent local storage of crop disease scan history.
class HistoryService {
  static const String _storageKey = 'agri_vision_scan_history';

  /// Save a new scan record to local storage (newest first)
  static Future<void> saveScan(ScanHistoryRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryRecord> currentScans = await getScans();

      // Avoid exact duplicate entries by ID
      currentScans.removeWhere((item) => item.id == record.id);
      currentScans.insert(0, record);

      // Encode list to JSON string list
      final List<String> encodedList =
          currentScans.map((scan) => jsonEncode(scan.toJson())).toList();

      await prefs.setStringList(_storageKey, encodedList);
    } catch (e) {
      // Print debug log if save fails
      print('Error saving scan to history: $e');
    }
  }

  /// Retrieve all saved scan records sorted newest first
  static Future<List<ScanHistoryRecord>> getScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? rawList = prefs.getStringList(_storageKey);

      if (rawList == null || rawList.isEmpty) {
        return [];
      }

      final List<ScanHistoryRecord> scans = [];
      for (final jsonStr in rawList) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          scans.add(ScanHistoryRecord.fromJson(map));
        } catch (e) {
          print('Error parsing history item JSON: $e');
        }
      }

      // Sort newest first by timestamp
      scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return scans;
    } catch (e) {
      print('Error loading history from storage: $e');
      return [];
    }
  }

  /// Delete a specific scan by ID
  static Future<bool> deleteScan(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryRecord> currentScans = await getScans();

      final int initialLength = currentScans.length;
      currentScans.removeWhere((item) => item.id == id);

      if (currentScans.length != initialLength) {
        final List<String> encodedList =
            currentScans.map((scan) => jsonEncode(scan.toJson())).toList();
        await prefs.setStringList(_storageKey, encodedList);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting scan: $e');
      return false;
    }
  }

  /// Clear all scan history
  static Future<void> clearAllScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}
