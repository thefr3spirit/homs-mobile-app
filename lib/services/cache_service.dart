import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const Duration defaultTTL = Duration(minutes: 10);

  // Cache keys
  static const String todaySummaryKey = 'cache_today_summary';
  static const String customersKey = 'cache_customers';
  static const String roomsKey = 'cache_rooms';
  static const String bookingsKey = 'cache_bookings';
  static const String paymentsKey = 'cache_payments';
  static const String historySummariesKey = 'cache_history_summaries';

  // Timestamp suffix for checking expiry
  static const String timestampSuffix = '_timestamp';

  /// Save data to cache with TTL
  Future<void> set(String key, dynamic data, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = json.encode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(key, dataJson);
      await prefs.setInt('$key$timestampSuffix', timestamp);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Get data from cache if not expired
  Future<dynamic> get(String key, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString(key);
      final timestamp = prefs.getInt('$key$timestampSuffix');

      if (dataJson == null || timestamp == null) {
        return null; // Not in cache
      }

      // Check if expired
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      final maxAge = (ttl ?? defaultTTL).inMilliseconds;

      if (age > maxAge) {
        // Expired - remove from cache
        await remove(key);
        return null;
      }

      // Valid cache - return data
      return json.decode(dataJson);
    } catch (e) {
      // Silently fail - caching is not critical
      return null;
    }
  }

  /// Remove specific cached item
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('$key$timestampSuffix');
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove all known cache keys
      final keys = [
        todaySummaryKey,
        customersKey,
        roomsKey,
        bookingsKey,
        paymentsKey,
        historySummariesKey,
      ];

      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('$key$timestampSuffix');
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if cache exists and is valid
  Future<bool> has(String key, {Duration? ttl}) async {
    final data = await get(key, ttl: ttl);
    return data != null;
  }

  /// Get cache age in milliseconds
  Future<int?> getAge(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('$key$timestampSuffix');

      if (timestamp == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - timestamp).toInt();
    } catch (e) {
      return null;
    }
  }
}
