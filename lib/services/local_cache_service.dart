import 'package:hive_flutter/hive_flutter.dart';
import '../models/crop_scan.dart';
import '../models/weather.dart';

class LocalCacheService {
  static const String _scansBox = 'crop_scans';
  static const String _weatherBox = 'weather_data';
  static const String _chatBox = 'chat_history';
  static const String _offlineQueueBox = 'offline_queue';
  static const String _userPrefsBox = 'user_preferences';
  
  // Memory cache for frequently accessed data
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheTimestamps = {};
  static const Duration _memoryCacheDuration = Duration(minutes: 5);

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters (TODO: implement Hive adapters)
  }

  // Memory cache helpers
  static dynamic _getFromMemoryCache(String key) {
    if (_memoryCache.containsKey(key)) {
      final timestamp = _memoryCacheTimestamps[key];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _memoryCacheDuration) {
        return _memoryCache[key];
      } else {
        // Expired, remove from cache
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
      }
    }
    return null;
  }

  static void _putInMemoryCache(String key, dynamic value) {
    _memoryCache[key] = value;
    _memoryCacheTimestamps[key] = DateTime.now();
  }

  // Crop Scan Operations with Multi-level Caching
  static Future<void> saveCropScan(CropScan scan) async {
    try {
      // Save to Hive (persistent)
      final box = await Hive.openBox(_scansBox);
      await box.put(scan.id, scan.toJson());
      
      // Update memory cache
      _putInMemoryCache('scan_${scan.id}', scan.toJson());
    } catch (e) {
      // If Hive fails, at least try memory cache for immediate use
      _putInMemoryCache('scan_${scan.id}', scan.toJson());
      rethrow;
    }
  }

  static Future<List<CropScan>> getCachedScans({bool forceRefresh = false}) async {
    // Try memory cache first unless forcing refresh
    if (!forceRefresh) {
      final cached = _getFromMemoryCache('all_scans');
      if (cached != null) {
        return (cached as List<dynamic>).map((json) => CropScan.fromJson(json)).toList();
      }
    }

    try {
      final box = await Hive.openBox(_scansBox);
      final scans = box.values.map((json) => CropScan.fromJson(json)).toList();
      scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Update memory cache
      _putInMemoryCache('all_scans', scans.map((scan) => scan.toJson()).toList());
      
      return scans;
    } catch (e) {
      // Fallback to memory cache if Hive fails
      final cached = _getFromMemoryCache('all_scans');
      if (cached != null) {
        return (cached as List<dynamic>).map((json) => CropScan.fromJson(json)).toList();
      }
      return []; // Return empty if both fail
    }
  }

  static Future<CropScan?> getCropScanById(String id, {bool forceRefresh = false}) async {
    // Try memory cache first unless forcing refresh
    if (!forceRefresh) {
      final cached = _getFromMemoryCache('scan_$id');
      if (cached != null) {
        return CropScan.fromJson(cached);
      }
    }

    try {
      final box = await Hive.openBox(_scansBox);
      final json = box.get(id);
      if (json != null) {
        final scan = CropScan.fromJson(json);
        // Update memory cache
        _putInMemoryCache('scan_$id', json);
        return scan;
      }
      return null;
    } catch (e) {
      // Fallback to memory cache
      final cached = _getFromMemoryCache('scan_$id');
      if (cached != null) {
        return CropScan.fromJson(cached);
      }
      return null;
    }
  }

  // Weather Data Operations
  static Future<void> saveWeatherData(WeatherData weather) async {
    try {
      final box = await Hive.openBox(_weatherBox);
      await box.put('current', weather.toJson());
      
      // Update memory cache
      _putInMemoryCache('weather_current', weather.toJson());
    } catch (e) {
      _putInMemoryCache('weather_current', weather.toJson());
      rethrow;
    }
  }

  static Future<WeatherData?> getCachedWeather({bool forceRefresh = false}) async {
    // Try memory cache first unless forcing refresh
    if (!forceRefresh) {
      final cached = _getFromMemoryCache('weather_current');
      if (cached != null) {
        return WeatherData.fromJson(cached);
      }
    }

    try {
      final box = await Hive.openBox(_weatherBox);
      final json = box.get('current');
      if (json != null) {
        final weather = WeatherData.fromJson(json);
        // Update memory cache
        _putInMemoryCache('weather_current', json);
        return weather;
      }
      return null;
    } catch (e) {
      // Fallback to memory cache
      final cached = _getFromMemoryCache('weather_current');
      if (cached != null) {
        return WeatherData.fromJson(cached);
      }
      return null;
    }
  }

  // Chat History Operations
  static Future<void> saveChatMessage(String message, String response, String userId) async {
    try {
      final box = await Hive.openBox(_chatBox);
      final chatData = {
        'message': message,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': userId,
      };
      await box.add(chatData);
      
      // Update recent chats in memory cache (keep last 20)
      final recentKey = 'recent_chats_$userId';
      final recentChats = _getFromMemoryCache(recentKey) as List<dynamic>? ?? [];
      recentChats.insert(0, chatData);
      if (recentChats.length > 20) {
        recentChats.removeRange(20, recentChats.length);
      }
      _putInMemoryCache(recentKey, recentChats);
    } catch (e) {
      // Still update memory cache even if Hive fails
      final chatData = {
        'message': message,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': userId,
      };
      final recentKey = 'recent_chats_$userId';
      final recentChats = _getFromMemoryCache(recentKey) as List<dynamic>? ?? [];
      recentChats.insert(0, chatData);
      if (recentChats.length > 20) {
        recentChats.removeRange(20, recentChats.length);
      }
      _putInMemoryCache(recentKey, recentChats);
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedChatHistory({String? userId, bool forceRefresh = false}) async {
    final cacheKey = userId == null ? 'all_chats' : 'chats_$userId';
    
    // Try memory cache first unless forcing refresh
    if (!forceRefresh) {
      final cached = _getFromMemoryCache(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    }

    try {
      final box = await Hive.openBox(_chatBox);
      final history = box.values.toList().cast<Map<String, dynamic>>();
      history.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      // Filter by userId if specified
      final filteredHistory = userId == null 
          ? history 
          : history.where((chat) => chat['user_id'] == userId).toList();
      
      // Limit to last 50 messages
      final limitedHistory = filteredHistory.take(50).toList();
      
      // Update memory cache
      _putInMemoryCache(cacheKey, limitedHistory);
      
      return limitedHistory;
    } catch (e) {
      // Fallback to memory cache
      final cached = _getFromMemoryCache(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
      return []; // Return empty if both fail
    }
  }

  // Offline Queue Implementation
  static Future<void> queueForOffline(Map<String, dynamic> action) async {
    try {
      final box = await Hive.openBox(_offlineQueueBox);
      final queuedAction = {
        ...action,
        'queued_at': DateTime.now().toIso8601String(),
        'id': '${DateTime.now().millisecondsSinceEpoch}_${action['type'] ?? 'unknown'}',
      };
      await box.add(queuedAction);
    } catch (e) {
      // If even Hive fails, we have a serious problem
      // In a real app, you might want to show a critical error to user
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final box = await Hive.openBox(_offlineQueueBox);
      return box.values.toList().cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> removeFromOfflineQueue(String id) async {
    try {
      final box = await Hive.openBox(_offlineQueueBox);
      final key = box.keys.firstWhere(
        (k) => box.get(k)['id'] == id,
        orElse: () => -1,
      );
      if (key != -1) {
        await box.deleteAt(key);
      }
    } catch (e) {
      // Log error but don't fail silently in production
      rethrow;
    }
  }

  static Future<void> clearProcessedOfflineQueue(List<String> processedIds) async {
    try {
      final box = await Hive.openBox(_offlineQueueBox);
      final keysToRemove = box.keys.where(
        (k) => processedIds.contains(box.get(k)['id'])
      ).toList();
      
      for (final key in keysToRemove) {
        await box.deleteAt(key);
      }
    } catch (e) {
      rethrow;
    }
  }

  // User Preferences
  static Future<void> saveUserPreference(String key, dynamic value) async {
    try {
      final box = await Hive.openBox(_userPrefsBox);
      await box.put(key, value);
      _putInMemoryCache('pref_$key', value);
    } catch (e) {
      _putInMemoryCache('pref_$key', value);
      rethrow;
    }
  }

  static Future<dynamic> getUserPreference(String key, {dynamic defaultValue}) async {
    // Try memory cache first
    final cached = _getFromMemoryCache('pref_$key');
    if (cached != null) {
      return cached;
    }

    try {
      final box = await Hive.openBox(_userPrefsBox);
      final value = box.get(key, defaultValue: defaultValue);
      
      // Update memory cache
      if (value != null) {
        _putInMemoryCache('pref_$key', value);
      }
      
      return value;
    } catch (e) {
      // Fallback to memory cache or default
      final cached = _getFromMemoryCache('pref_$key');
      if (cached != null) {
        return cached;
      }
      return defaultValue;
    }
  }

  // Cache Management
  static Future<void> clearOldCache() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      // Clear old scans
      final scanBox = await Hive.openBox(_scansBox);
      final scanKeysToDelete = scanBox.keys.where((key) {
        final scanJson = scanBox.get(key);
        if (scanJson == null) return true;
        final scan = CropScan.fromJson(scanJson);
        return scan.createdAt.isBefore(cutoffDate);
      }).toList();
      await scanBox.deleteAll(scanKeysToDelete);

      // Clear old chat history
      final chatBox = await Hive.openBox(_chatBox);
      final chatKeysToDelete = chatBox.keys.where((key) {
        final chat = chatBox.get(key) as Map<String, dynamic>?;
        if (chat == null) return true;
        final timestamp = DateTime.tryParse(chat['timestamp']);
        return timestamp == null || timestamp.isBefore(cutoffDate);
      }).toList();
      await chatBox.deleteAll(chatKeysToDelete);

      // Clear old weather data (keep only current)
      final weatherBox = await Hive.openBox(_weatherBox);
      await weatherBox.clear();
      await weatherBox.put('placeholder', {}); // Keep box alive

      // Clear memory cache entries related to old data
      _memoryCache.removeWhere((key, value) => 
        key.startsWith('scan_') || 
        key.startsWith('chats_') ||
        key == 'all_scans' ||
        key == 'weather_current'
      );
      _memoryCacheTimestamps.removeWhere((key, value) => 
        key.startsWith('scan_') || 
        key.startsWith('chats_') ||
        key == 'all_scans' ||
        key == 'weather_current'
      );
    } catch (e) {
      // Log error but continue - cache clearing is best effort
      rethrow;
    }
  }

  static Future<void> clearAllCache() async {
    try {
      // Clear all Hive boxes
      await Hive.deleteBoxFromDisk(_scansBox);
      await Hive.deleteBoxFromDisk(_weatherBox);
      await Hive.deleteBoxFromDisk(_chatBox);
      await Hive.deleteBoxFromDisk(_offlineQueueBox);
      await Hive.deleteBoxFromDisk(_userPrefsBox);
      
      // Reinitialize boxes
      await Hive.openBox(_scansBox);
      await Hive.openBox(_weatherBox);
      await Hive.openBox(_chatBox);
      await Hive.openBox(_offlineQueueBox);
      await Hive.openBox(_userPrefsBox);
      
      // Clear memory cache
      _memoryCache.clear();
      _memoryCacheTimestamps.clear();
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final scanBox = await Hive.openBox(_scansBox);
      final weatherBox = await Hive.openBox(_weatherBox);
      final chatBox = await Hive.openBox(_chatBox);
      final queueBox = await Hive.openBox(_offlineQueueBox);
      final prefsBox = await Hive.openBox(_userPrefsBox);
      
      return {
        'scans_count': scanBox.length,
        'weather_entries': weatherBox.length,
        'chat_messages': chatBox.length,
        'offline_queue_length': queueBox.length,
        'user_preferences': prefsBox.length,
        'memory_cache_entries': _memoryCache.length,
        'memory_cache_size_approx': _calculateApproximateMemorySize(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'memory_cache_entries': _memoryCache.length,
      };
    }
  }

  static int _calculateApproximateMemorySize() {
    int size = 0;
    _memoryCache.forEach((key, value) {
      size += key.length * 2; // Approximate UTF-16 char size
      if (value is String) {
        size += value.length * 2;
      } else if (value is List) {
        size += value.length * 24; // Rough estimate for list overhead
        for (final item in value) {
          if (item is String) {
            size += item.length * 2;
          } else if (item is Map) {
            size += 48; // Map overhead
            item.forEach((k, v) {
              size += (k.length as num).toInt() * 2;
              if (v is String) {
                size += v.length * 2;
              }
            });
          }
        }
      } else if (value is Map) {
        size += 48; // Map overhead
        value.forEach((k, v) {
            size += (k.length as num).toInt() * 2;
          if (v is String) {
            size += v.length * 2;
          }
        });
      }
    });
    return size;
  }
}