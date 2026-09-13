import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatwise/core/storage/secure_storage_service.dart';

class AiConfig {
  AiConfig._();

  static String _cachedGeminiKey = '';
  static String _cachedGroqKey = '';
  static String _cachedOpenRouterKey = '';

  /// Pre-loads API keys from secure storage into memory for synchronous access.
  static Future<void> loadKeys() async {
    _cachedGeminiKey = (await SecureStorageService.getGeminiApiKey()) ?? '';
    _cachedGroqKey = (await SecureStorageService.getGroqApiKey()) ?? '';
    _cachedOpenRouterKey = (await SecureStorageService.getOpenRouterApiKey()) ?? '';
  }

  static String _envLookup(String name) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[name] ?? '';
      }
    } catch (_) {}
    return '';
  }

  static String get geminiApiKey {
    if (_cachedGeminiKey.isNotEmpty) return _cachedGeminiKey;
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    final key = _envLookup('GEMINI_API_KEY');
    if (kDebugMode && key.isEmpty) {
      debugPrint('[AiConfig] ⚠️ GEMINI_API_KEY not configured');
    }
    return key;
  }

  static String get groqApiKey {
    if (_cachedGroqKey.isNotEmpty) return _cachedGroqKey;
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    final key = _envLookup('GROQ_API_KEY');
    if (kDebugMode && key.isEmpty) {
      debugPrint('[AiConfig] ⚠️ GROQ_API_KEY not configured');
    }
    return key;
  }

  static String get openRouterApiKey {
    if (_cachedOpenRouterKey.isNotEmpty) return _cachedOpenRouterKey;
    const envKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    final key = _envLookup('OPENROUTER_API_KEY');
    if (kDebugMode && key.isEmpty) {
      debugPrint('[AiConfig] ⚠️ OPENROUTER_API_KEY not configured');
    }
    return key;
  }

  static Future<void> setGeminiApiKey(String key) async {
    _cachedGeminiKey = key;
    await SecureStorageService.setGeminiApiKey(key);
  }

  static Future<void> setGroqApiKey(String key) async {
    _cachedGroqKey = key;
    await SecureStorageService.setGroqApiKey(key);
  }

  static Future<void> setOpenRouterApiKey(String key) async {
    _cachedOpenRouterKey = key;
    await SecureStorageService.setOpenRouterApiKey(key);
  }

  /// Async getters that properly read from secure storage
  static Future<String> getGeminiApiKeyAsync() async {
    final secureKey = await SecureStorageService.getGeminiApiKey();
    if (secureKey != null && secureKey.isNotEmpty) return secureKey;
    return geminiApiKey;
  }

  static Future<String> getGroqApiKeyAsync() async {
    final secureKey = await SecureStorageService.getGroqApiKey();
    if (secureKey != null && secureKey.isNotEmpty) return secureKey;
    return groqApiKey;
  }

  static Future<String> getOpenRouterApiKeyAsync() async {
    final secureKey = await SecureStorageService.getOpenRouterApiKey();
    if (secureKey != null && secureKey.isNotEmpty) return secureKey;
    return openRouterApiKey;
  }

  static const openRouterModel = 'google/gemini-2.5-flash:free';
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/cgi';

  static const geminiModel = 'gemini-2.5-flash';
  static const geminiFallbackModel = 'gemini-3.1-flash-lite';
  static const groqModel = 'llama-3.3-70b-versatile';

  static bool get isGroqConfigured => groqApiKey.isNotEmpty;

  static const bool enableGeminiGrounding = true;
}
