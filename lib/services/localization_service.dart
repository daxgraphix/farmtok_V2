import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguageCode = 'en';

  static final Map<String, Locale> _supportedLocales = {
    'English': Locale('en', 'US'),
    'Swahili': Locale('sw', 'KE'),
  };

  static Map<String, Map<String, String>> _localizedValues = {};
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load English strings
      final String enJson = await rootBundle.loadString('lib/l10n/en.json');
      final Map<String, dynamic> enMap = jsonDecode(enJson);
      _localizedValues['en'] = _flattenJsonMap(enMap);
      
      // Load Swahili strings
      final String swJson = await rootBundle.loadString('lib/l10n/sw.json');
      final Map<String, dynamic> swMap = jsonDecode(swJson);
      _localizedValues['sw'] = _flattenJsonMap(swMap);
      
      _isInitialized = true;
    } catch (e) {
      // Fallback to basic strings if JSON loading fails
      _localizedValues = {
        'en': {
          'welcome': 'Welcome to FarmTok',
          'scan_crop': 'Scan Crop',
          'ask_ai': 'Ask AI',
          'weather': 'Weather',
          'analytics': 'Analytics',
          'profile': 'Profile',
          'healthy_plant': 'Healthy Plant',
          'disease_detected': 'Disease Detected',
          'treatment': 'Treatment',
          'prevention': 'Prevention',
          'loading': 'Loading...',
          'error': 'Error occurred',
          'retry': 'Retry',
          'save': 'Save',
          'cancel': 'Cancel',
          'confirm': 'Confirm',
          'settings': 'Settings',
          'language': 'Language',
          'units': 'Units',
          'notifications': 'Notifications',
          'about': 'About',
          'logout': 'Logout',
          'crop_scan': 'Crop Scan',
          'ai_assistant': 'AI Assistant',
          'weather_intelligence': 'Weather Intelligence',
          'farming_tips': 'Farming Tips',
          'recent_activity': 'Recent Activity',
          'quick_actions': 'Quick Actions',
          'good_morning': 'Good morning',
          'good_afternoon': 'Good afternoon',
          'good_evening': 'Good evening',
        },
        'sw': {
          'welcome': 'Karibu FarmTok',
          'scan_crop': 'Chambua Mazao',
          'ask_ai': 'Uliza AI',
          'weather': 'Hali ya Hewa',
          'analytics': 'Uchambuzi',
          'profile': 'Wasifu',
          'healthy_plant': 'Mimea Yenye Afya',
          'disease_detected': 'Ugonjwa Umebainika',
          'treatment': 'Matibabu',
          'prevention': 'Kinga',
          'loading': 'Inapakia...',
          'error': 'Hitilafu imetokea',
          'retry': 'Jaribu tena',
          'save': 'Hifadhi',
          'cancel': 'Ghairi',
          'confirm': 'Thibitisha',
          'settings': 'Mipangilio',
          'language': 'Lugha',
          'units': 'Vipimo',
          'notifications': 'Taarifa',
          'about': 'Kuhusu',
          'logout': 'Toka',
          'crop_scan': 'Uchunguzi wa Mazao',
          'ai_assistant': 'Msaidizi wa AI',
          'weather_intelligence': 'Ujuzi wa Hali ya Hewa',
          'farming_tips': 'Vidokezo vya Kilimo',
          'recent_activity': 'Shughuli za Hivi Karibuni',
          'quick_actions': 'Vitendo vya Haraka',
          'good_morning': 'Habari za asubuhi',
          'good_afternoon': 'Habari za mchana',
          'good_evening': 'Habari za jioni',
        }
      };
      _isInitialized = true;
    }
  }

  static Future<Locale> getCurrentLocale() async {
    final String languageCode = await getCurrentLanguageCode();
    return Locale(languageCode);
  }

  static Future<String> getCurrentLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(_languageKey);
    return langCode ?? _defaultLanguageCode;
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static String translate(String key, {String? languageCode}) {
    if (!_isInitialized) {
      // Return key if not initialized yet
      return key;
    }
    
    final String lang = languageCode ?? getCurrentLanguageCodeSync();
    final Map<String, String>? translations = _localizedValues[lang];
    
    if (translations != null && translations.containsKey(key)) {
      return translations[key]!;
    }
    
    // Fallback to default language
    final Map<String, String>? defaultTranslations = _localizedValues[_defaultLanguageCode];
    if (defaultTranslations != null && defaultTranslations.containsKey(key)) {
      return defaultTranslations[key]!;
    }
    
    // Return key if not found
    return key;
  }

  static String getCurrentLanguageCodeSync() {
    // Synchronous version for cases where we can't use async
    // This is not ideal but works for simple cases
    return _defaultLanguageCode;
  }

  static List<Locale> getSupportedLocales() {
    return _supportedLocales.values.toList();
  }

  static List<String> getSupportedLanguageCodes() {
    return ['en', 'sw'];
  }

  static bool isLanguageSupported(String languageCode) {
    return _localizedValues.containsKey(languageCode);
  }

  static String getText(String key, {String? languageCode}) {
    return translate(key, languageCode: languageCode);
  }

  static Map<String, String> _flattenJsonMap(Map<String, dynamic> map, {String prefix = ''}) {
    final Map<String, String> result = {};
    map.forEach((key, value) {
      final String newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenJsonMap(value, prefix: newKey));
      } else if (value is String) {
        result[newKey] = value;
      } else {
        result[newKey] = value.toString();
      }
    });
    return result;
  }
}

// Extension for easy localization
extension LocalizationExtension on String {
  String tr() {
    return LocalizationService.translate(this);
  }
  
  String trWithArgs(List<String> args) {
    String translated = LocalizationService.translate(this);
    for (int i = 0; i < args.length; i++) {
      translated = translated.replaceAll('{$i}', args[i]);
    }
    return translated;
  }
}

// Localized Text Widget with automatic language updates
class LocalizedText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextWidthBasis? textWidthBasis;
  final StrutStyle? strutStyle;

  const LocalizedText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textWidthBasis,
    this.strutStyle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: LocalizationService.getCurrentLanguageCode(),
      builder: (context, snapshot) {
        final languageCode = snapshot.data ?? 'en';
        final text = LocalizationService.translate(textKey, languageCode: languageCode);
        
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          textWidthBasis: textWidthBasis,
          strutStyle: strutStyle,
        );
      },
    );
  }
}

// Widget that rebuilds when language changes
class LocalizedWidgetBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, String languageCode) builder;

  const LocalizedWidgetBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: LocalizationService.getCurrentLanguageCode(),
      builder: (context, snapshot) {
        final languageCode = snapshot.data ?? 'en';
        return builder(context, languageCode);
      },
    );
  }
}