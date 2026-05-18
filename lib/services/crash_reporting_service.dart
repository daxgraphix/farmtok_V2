import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrashReportingService {
  static const String _crashReportingEnabledKey = 'crash_reporting_enabled';
  static const String _crashesKey = 'reported_crashes';
  static const String _lastCrashKey = 'last_crash_time';
  static const String _pendingCrashesKey = 'pending_crashes';
  static const String _retryCountKey = 'retry_count_';

  static bool _isInitialized = false;
  static final List<CrashReport> _pendingReports = [];
  static final Map<String, int> _retryCounts = {};

  // Configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const String _crashEndpoint = 'https://your-crash-reporting-service.com/api/crashes';

  // Initialization
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final enabled = await isCrashReportingEnabled();
    if (!enabled) return;

    // Load pending reports and retry counts from storage
    await _loadPendingReports();
    await _loadRetryCounts();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      reportCrash(
        error: details.exception,
        stackTrace: details.stack,
        context: details.context?.toString(),
        library: details.library,
      );
    };

    // Handle uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      reportCrash(
        error: error,
        stackTrace: stack,
        context: 'Uncaught async error',
      );
      return true;
    };

    _isInitialized = true;

    // Send any pending crash reports
    await _sendPendingReports();
  }

  // Settings Management
  static Future<bool> isCrashReportingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_crashReportingEnabledKey) ?? true;
  }

  static Future<void> setCrashReportingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crashReportingEnabledKey, enabled);

    if (!enabled) {
      await clearCrashData();
    }
  }

  // Crash Reporting with Enhanced Error Handling
  static Future<void> reportCrash({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    String? library,
    Map<String, dynamic>? additionalData,
  }) async {
    final enabled = await isCrashReportingEnabled();
    if (!enabled) return;

    final crashReport = CrashReport(
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
      library: library,
      timestamp: DateTime.now(),
      additionalData: additionalData ?? {},
      deviceInfo: await _getDeviceInfo(),
    );

    // Add to pending reports
    _pendingReports.add(crashReport);

    // Store crash locally
    await _storeCrashLocally(crashReport);

    // In debug mode, print the crash
    if (kDebugMode) {
      print('Crash reported: ${crashReport.error}'); // ignore: avoid_print
    }

    // Try to send immediately if we have internet
    await _attemptSendCrashReport(crashReport);
  }

  // Store crash locally with improved error handling
  static Future<void> _storeCrashLocally(CrashReport crashReport) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crashesJson = prefs.getString(_crashesKey);
      List<dynamic> crashes = [];

      if (crashesJson != null) {
        try {
          crashes = jsonDecode(crashesJson);
        } catch (e) {
          crashes = [];
        }
      }

      crashes.add(crashReport.toJson());

      // Keep only last 50 crashes
      if (crashes.length > 50) {
        crashes = crashes.skip(crashes.length - 50).toList();
      }

      await prefs.setString(_crashesKey, jsonEncode(crashes));
      await prefs.setString(_lastCrashKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Failed to store crash locally: $e');
      }
      // Even if local storage fails, we still have the report in memory
    }
  }

  // Improved sending with retry mechanism
  static Future<void> _attemptSendCrashReport(CrashReport report) async {
    final reportId = report.timestamp.toIso8601String();
    final retryCount = _retryCounts[reportId] ?? 0;

    // Don't exceed max retry attempts
    if (retryCount >= _maxRetryAttempts) {
      if (kDebugMode) {
        print('Max retry attempts reached for crash report: $reportId');
      }
      return;
    }

    try {
      await _sendCrashReport(report);
      
      // Success - remove from pending and clear retry count
      _pendingReports.remove(report);
      _retryCounts.remove(reportId);
      await _updatePendingReportsStorage();
      await _updateRetryCountsStorage();
      
      if (kDebugMode) {
        print('Successfully sent crash report: $reportId');
      }
    } catch (e) {
      // Failed - increment retry count and store for later
      _retryCounts[reportId] = retryCount + 1;
      await _updateRetryCountsStorage();
      
      if (kDebugMode) {
        print('Failed to send crash report (attempt ${retryCount + 1}): $e');
      }
      
      // Schedule retry with exponential backoff
      if (retryCount + 1 < _maxRetryAttempts) {
        final delay = _retryDelay * (pow(2, retryCount) as int);
        Future.delayed(delay, () {
          _attemptSendCrashReport(report);
        });
      }
    }
  }

  // Process all pending reports
  static Future<void> _sendPendingReports() async {
    if (_pendingReports.isEmpty) return;

    // Process reports in order
    for (final report in List.from(_pendingReports)) {
      await _attemptSendCrashReport(report);
    }
  }

  // Actual sending implementation with better error handling
  static Future<void> _sendCrashReport(CrashReport report) async {
    try {
      final uri = Uri.parse(_crashEndpoint);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(report.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        return;
      } else {
        // Server error - throw to trigger retry mechanism
        throw HttpException(
          'Server returned status code ${response.statusCode}: ${response.body}',
        );
      }
    } on HttpException {
      // Re-throw for retry mechanism
      rethrow;
    } on FormatException catch (e) {
      // Invalid JSON - don't retry
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      // Network or other errors - retry
      throw Exception('Network error: $e');
    }
  }

  // Load pending reports from storage
  static Future<void> _loadPendingReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingCrashesKey);
      
      if (pendingJson != null) {
        final List<dynamic> pendingList = jsonDecode(pendingJson);
        _pendingReports.clear();
        _pendingReports.addAll(
          pendingList.map((json) => CrashReport.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load pending reports: $e');
      }
      _pendingReports.clear();
    }
  }

  // Load retry counts from storage
  static Future<void> _loadRetryCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_retryCountKey));
      
      _retryCounts.clear();
      for (final key in keys) {
        final reportId = key.substring(_retryCountKey.length);
        final count = prefs.getInt(key) ?? 0;
        _retryCounts[reportId] = count;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load retry counts: $e');
      }
      _retryCounts.clear();
    }
  }

  // Update pending reports storage
  static Future<void> _updatePendingReportsStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _pendingReports.map((report) => report.toJson()).toList();
      await prefs.setString(_pendingCrashesKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update pending reports storage: $e');
      }
    }
  }

  // Update retry counts storage
  static Future<void> _updateRetryCountsStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear existing retry count keys
      final keys = prefs.getKeys().where((key) => key.startsWith(_retryCountKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      // Store current retry counts
      _retryCounts.forEach((reportId, count) {
        final key = '$_retryCountKey$reportId';
        prefs.setInt(key, count);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update retry counts storage: $e');
      }
    }
  }

  // Device Information with enhanced details
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.0',
        'build_number': '1',
        'dart_version': Platform.version,
        'is_emulator': kIsWeb ? false : 
                      (Platform.isAndroid || Platform.isIOS) ? 
                      false : true, // Simplified check
        'locale': Platform.localeName,
        'timezone': DateTime.now().timeZoneName,
      };
    } catch (e) {
      // Fallback basic info if detailed info fails
      return {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.0',
        'build_number': '1',
        'dart_version': Platform.version,
        'error_getting_details': e.toString(),
      };
    }
  }

  // Crash Data Management
  static Future<List<CrashReport>> getCrashHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crashesJson = prefs.getString(_crashesKey);

      if (crashesJson == null) return [];

      final crashesData = jsonDecode(crashesJson) as List;
      return crashesData.map((data) => CrashReport.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get crash history: $e');
      }
      return [];
    }
  }

  static Future<void> clearCrashData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_crashesKey);
      await prefs.remove(_lastCrashKey);
      await prefs.remove(_pendingCrashesKey);
      
      // Clear retry counts
      final keys = prefs.getKeys().where((key) => key.startsWith(_retryCountKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      _pendingReports.clear();
      _retryCounts.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear crash data: $e');
      }
    }
  }

  static Future<DateTime?> getLastCrashTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCrash = prefs.getString(_lastCrashKey);

      if (lastCrash == null) return null;

      return DateTime.parse(lastCrash);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get last crash time: $e');
      }
      return null;
    }
  }

  // Non-fatal Error Reporting with context
  static Future<void> reportNonFatalError({
    required String error,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await reportCrash(
      error: 'Non-fatal: $error',
      context: context,
      additionalData: {
        ...?additionalData,
        'fatal': false,
        'error_type': 'non_fatal',
      },
    );
  }

  // Performance Monitoring
  static Future<void> reportPerformanceIssue({
    required String metricName,
    required double value,
    required String unit,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('performance_issue', {
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'context': context,
    });
  }

  // Custom Event Tracking (for analytics integration)
  static Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    // This would integrate with your analytics service
    if (kDebugMode) {
      print('📊 Analytics Event: $eventName - $parameters');
    }
    
    // In production, send to analytics service
    // await _sendAnalyticsEvent(eventName, parameters);
  }

  // Utility Methods
  static Future<Map<String, dynamic>> getCrashReportStats() async {
    try {
      final crashes = await getCrashHistory();
      final lastCrash = await getLastCrashTime();

      final errorTypes = <String, int>{};
      for (final crash in crashes) {
        final errorType = crash.error.split(':').first;
        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      }

      return {
        'total_crashes': crashes.length,
        'error_breakdown': errorTypes,
        'last_crash': lastCrash?.toIso8601String(),
        'pending_reports': _pendingReports.length,
        'retry_counts': _retryCounts,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get crash report stats: $e');
      }
      return {
        'total_crashes': 0,
        'error_breakdown': {},
        'last_crash': null,
        'pending_reports': 0,
        'retry_counts': {},
      };
    }
  }
}

class CrashReport {
  final String error;
  final String? stackTrace;
  final String? context;
  final String? library;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;
  final Map<String, dynamic> deviceInfo;

  CrashReport({
    required this.error,
    this.stackTrace,
    this.context,
    this.library,
    required this.timestamp,
    required this.additionalData,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stack_trace': stackTrace,
      'context': context,
      'library': library,
      'timestamp': timestamp.toIso8601String(),
      'additional_data': additionalData,
      'device_info': deviceInfo,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      error: json['error'],
      stackTrace: json['stack_trace'],
      context: json['context'],
      library: json['library'],
      timestamp: DateTime.parse(json['timestamp']),
      additionalData: Map<String, dynamic>.from(json['additional_data'] ?? {}),
      deviceInfo: Map<String, dynamic>.from(json['device_info'] ?? {}),
    );
  }
}

// Enhanced Error Handling Service for User-Facing Errors
class ErrorHandlingService {
  static const String _lastErrorKey = 'last_user_error';
  static const String _errorHistoryKey = 'error_history';
  
  static Future<void> handleError({
    required Object error,
    required String context,
    bool showUserFeedback = true,
  }) async {
    // Log the error for debugging
    if (kDebugMode) {
      print('Error in $context: $error');
    }
    
    // Report to crash reporting if appropriate
    await CrashReportingService.reportCrash(
      error: error,
      context: 'User-facing error in $context',
    );
    
    // Store error for potential user feedback
    await _storeErrorForFeedback(error, context);
    
    // In production, we might want to show a user-friendly error message
    // This would typically be handled by the UI layer
  }
  
  static Future<void> _storeErrorForFeedback(Object error, String context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorJson = {
        'error': error.toString(),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Store last error
      await prefs.setString(_lastErrorKey, jsonEncode(errorJson));
      
      // Maintain error history (keep last 10 errors)
      final historyJson = prefs.getString(_errorHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      history.add(errorJson);
      
      // Keep only last 10 errors
      if (history.length > 10) {
        history.removeRange(0, history.length - 10);
      }
      
      await prefs.setString(_errorHistoryKey, jsonEncode(history));
    } catch (e) {
      // Ignore storage errors for error reporting to avoid infinite loops
    }
  }
  
  static Future<Map<String, dynamic>?> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorJson = prefs.getString(_lastErrorKey);
      return errorJson != null ? jsonDecode(errorJson) : null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<List<dynamic>> getErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_errorHistoryKey) ?? '[]';
      return jsonDecode(historyJson);
    } catch (e) {
      return [];
    }
  }
  
  static Future<void> clearErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorKey);
      await prefs.remove(_errorHistoryKey);
    } catch (e) {
      // Ignore
    }
  }
}

// Enhanced Retryable Operation Helper
class RetryableOperation {
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
    bool exponentialBackoff = true,
  }) async {
    int attempt = 0;
    
    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) {
          rethrow; // Re-throw the last error if max attempts reached
        }
        
        // Calculate delay
        Duration waitTime;
        if (exponentialBackoff) {
          waitTime = delay * (pow(2, attempt - 1) as int);
        } else {
          waitTime = delay;
        }
        
        // Wait before retrying
        await Future.delayed(waitTime);
      }
    }
  }
}

// Helper class for retryable operations with UI feedback
class RetryHelper {
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
    String? errorMessage,
  }) async {
    return await RetryableOperation.execute<T>(
      operation,
      maxAttempts: maxAttempts,
      delay: delay,
    );
  }
}