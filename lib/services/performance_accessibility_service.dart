import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceService {
  static const String _cacheSizeKey = 'max_cache_size_mb';

  // Image optimization
  static Future<Uint8List> optimizeImage(Uint8List imageBytes, {int? quality}) async {
    // In a real implementation, you would use flutter_image_compress
    // For now, return the original bytes
    return imageBytes;
  }

  // Memory management
  static Future<void> clearImageCache() async {
    // Clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static Future<int> getCacheSize() async {
    // Return approximate cache size in MB
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheSizeKey) ?? 100;
  }

  // Animation optimization
  static Duration getAnimationDuration(Duration defaultDuration, BuildContext context) {
    // Check if user prefers reduced motion
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    return reduceMotion ? Duration.zero : defaultDuration;
  }

  // Lazy loading helper
  static Widget buildLazyWidget(Widget Function() builder) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 100), builder),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data as Widget;
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Database optimization
  static Future<void> optimizeDatabase() async {
    // Implement database optimization logic
    // This would include vacuum operations, index rebuilding, etc.
  }
}

class AccessibilityService {
  static const String _highContrastKey = 'high_contrast_mode';
  static const String _largeTextKey = 'large_text_mode';
  static const String _voiceInputKey = 'voice_input_enabled';
  static const String _hapticFeedbackKey = 'haptic_feedback_enabled';
  static const String _screenReaderKey = 'screen_reader_enabled';
  static const String _invertColorsKey = 'invert_colors';

  static Future<bool> isHighContrastEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  static Future<bool> isLargeTextEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_largeTextKey) ?? false;
  }

  static Future<bool> isVoiceInputEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceInputKey) ?? true;
  }

  static Future<bool> isHapticFeedbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticFeedbackKey) ?? true;
  }

  static Future<bool> isScreenReaderEnabled() async {
    // Check if accessibility services are enabled (TalkBack, VoiceOver, etc.)
    try {
      // This is a simplified check - in reality, platform-specific checks would be needed
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_screenReaderKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isInvertColorsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_invertColorsKey) ?? false;
  }

  static Future<void> setAccessibilityPreferences({
    bool? highContrast,
    bool? largeText,
    bool? voiceInput,
    bool? hapticFeedback,
    bool? screenReader,
    bool? invertColors,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (highContrast != null) {
      await prefs.setBool(_highContrastKey, highContrast);
    }
    if (largeText != null) {
      await prefs.setBool(_largeTextKey, largeText);
    }
    if (voiceInput != null) {
      await prefs.setBool(_voiceInputKey, voiceInput);
    }
    if (hapticFeedback != null) {
      await prefs.setBool(_hapticFeedbackKey, hapticFeedback);
    }
    if (screenReader != null) {
      await prefs.setBool(_screenReaderKey, screenReader);
    }
    if (invertColors != null) {
      await prefs.setBool(_invertColorsKey, invertColors);
    }
  }

  // Get text scale factor based on accessibility settings
  static double getTextScaleFactor(BuildContext context) {
    final double baseScale = MediaQuery.of(context).textScaler.scale(1.0);
    // Apply large text multiplier if enabled
    final bool isLargeTextEnabledSync = _isLargeTextEnabledSync();
    return baseScale * (isLargeTextEnabledSync ? 1.3 : 1.0);
  }

  // Synchronous version for cases where we can't use async
  static bool _isLargeTextEnabledSync() {
    // This is a simplified implementation
    // In a real app, you'd want to use platform channels or a more robust solution
    return false; // Placeholder
  }

  // Check if colors meet WCAG contrast ratios
  static bool meetsContrastRatio(Color foreground, Color background, {bool largeText = false}) {
    // Calculate relative luminance
    double getLuminance(Color color) {
      double r = color.r;
      double g = color.g;
      double b = color.b;
      
      r = r > 0.03928 ? (pow((r + 0.055) / 1.055, 2.4) as double) : r / 12.92;
      g = g > 0.03928 ? (pow((g + 0.055) / 1.055, 2.4) as double) : g / 12.92;
      b = b > 0.03928 ? (pow((b + 0.055) / 1.055, 2.4) as double) : b / 12.92;
      
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }
    
    final double lum1 = getLuminance(foreground);
    final double lum2 = getLuminance(background);
    final double lighter = max(lum1, lum2);
    final double darker = min(lum1, lum2);
    final double contrastRatio = (lighter + 0.05) / (darker + 0.05);
    
    // WCAG 2.1 standards:
    // AA normal text: 4.5:1
    // AA large text: 3:1
    // AAA normal text: 7:1
    // AAA large text: 4.5:1
    return largeText ? contrastRatio >= 3.0 : contrastRatio >= 4.5;
  }

  // Get accessible color based on background
  static Color getAccessibleColor(Color background, {bool preferLight = true}) {
    // Try white or black text based on background luminance
    final double luminance = _computeLuminance(background);
    return luminance > 0.5 
        ? (preferLight ? Colors.black87 : Colors.white) 
        : (preferLight ? Colors.white : Colors.black87);
  }

  static double _computeLuminance(Color color) {
    final double r = color.r;
    final double g = color.g;
    final double b = color.b;
    
    final double adjustedR = r > 0.03928 ? (pow((r + 0.055) / 1.055, 2.4) as double) : r / 12.92;
    final double adjustedG = g > 0.03928 ? (pow((g + 0.055) / 1.055, 2.4) as double) : g / 12.92;
    final double adjustedB = b > 0.03928 ? (pow((b + 0.055) / 1.055, 2.4) as double) : b / 12.92;
    
    return 0.2126 * adjustedR + 0.7152 * adjustedG + 0.0722 * adjustedB;
  }

  // Haptic feedback helper
  static Future<void> triggerHapticFeedback(HapticFeedbackType type) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_hapticFeedbackKey) ?? true;

    if (!enabled) return;

    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  // Vibration pattern helper
  static Future<void> vibrate(List<int> pattern, {int repeat = -1}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_hapticFeedbackKey) ?? true;

    if (!enabled) return;

    try {
      // Note: Vibration API varies by platform
      // This is a placeholder for actual vibration implementation
      // On Android: VibrationService.vibrate(pattern, repeat);
      // On iOS: AudioToolbox services
    } catch (e) {
      // Ignore vibration errors
    }
  }
}

// Accessibility Widget Wrappers
class AccessibilityBuilder extends StatelessWidget {
  final Widget Function({
    required bool highContrast,
    required bool largeText,
    required bool screenReaderEnabled,
  }) builder;

  const AccessibilityBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AccessibilityService.isHighContrastEnabled(),
      builder: (context, highContrastSnapshot) {
        return FutureBuilder<bool>(
          future: AccessibilityService.isLargeTextEnabled(),
          builder: (context, largeTextSnapshot) {
            return FutureBuilder<bool>(
              future: AccessibilityService.isScreenReaderEnabled(),
              builder: (context, screenReaderSnapshot) {
                return builder(
                  highContrast: highContrastSnapshot.data ?? false,
                  largeText: largeTextSnapshot.data ?? false,
                  screenReaderEnabled: screenReaderSnapshot.data ?? false,
                );
              },
            );
          },
        );
      },
    );
  }
}

class HighContrastBuilder extends StatelessWidget {
  final Widget Function({required bool enabled}) builder;

  const HighContrastBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AccessibilityService.isHighContrastEnabled(),
      builder: (context, snapshot) {
        final bool enabled = snapshot.data ?? false;
        return builder(enabled: enabled);
      },
    );
  }
}

class LargeTextBuilder extends StatelessWidget {
  final Widget Function({required bool enabled}) builder;

  const LargeTextBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AccessibilityService.isLargeTextEnabled(),
      builder: (context, snapshot) {
        final bool enabled = snapshot.data ?? false;
        return builder(enabled: enabled);
      },
    );
  }
}

// Semantic Label Helper for accessibility
class SemanticsHelper {
  static Widget labelWidget({
    required Widget child,
    required String label,
    bool? button,
    bool? checked,
    bool? enabled,
    bool? header,
    bool? hidden,
    bool? image,
    bool? link,
    bool? selected,
    bool? slider,
  }) {
    return Semantics(
      label: label,
      button: button,
      checked: checked,
      enabled: enabled,
      header: header,
      hidden: hidden,
      image: image,
      link: link,
      selected: selected,
      slider: slider,
      child: child,
    );
  }
}

// Focus Management Helper
class FocusEnhancer extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;

  const FocusEnhancer({
    super.key,
    required this.child,
    this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticsHelper.labelWidget(
      label: label ?? '',
      child: Tooltip(
        message: hint ?? '',
        preferBelow: false,
        child: child,
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, heavy, selection }