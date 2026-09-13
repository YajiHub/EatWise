import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like API keys
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for API credentials
  static const _geminiKey = 'gemini_api_key';
  static const _groqKey = 'groq_api_key';
  static const _openRouterKey = 'openrouter_api_key';

  /// Initialize secure storage with keys from .env if not already set
  static Future<void> initializeFromEnv() async {
    try {
      final currentGemini = await getGeminiApiKey();
      final gemini = dotenv.env['GEMINI_API_KEY'];
      if ((currentGemini == null || currentGemini.isEmpty) && gemini != null && gemini.isNotEmpty) {
        await setGeminiApiKey(gemini);
      }

      final currentGroq = await getGroqApiKey();
      final groq = dotenv.env['GROQ_API_KEY'];
      if ((currentGroq == null || currentGroq.isEmpty) && groq != null && groq.isNotEmpty) {
        await setGroqApiKey(groq);
      }

      final currentOpenRouter = await getOpenRouterApiKey();
      final openRouter = dotenv.env['OPENROUTER_API_KEY'];
      if ((currentOpenRouter == null || currentOpenRouter.isEmpty) && openRouter != null && openRouter.isNotEmpty) {
        await setOpenRouterApiKey(openRouter);
      }

      await _storage.write(key: 'initialized', value: 'true');
      if (kDebugMode) debugPrint('[SecureStorage] Initialized keys from environment');
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] Initialization error: $e');
    }
  }

  // Gemini API Key
  static Future<String?> getGeminiApiKey() async {
    return _storage.read(key: _geminiKey);
  }

  static Future<void> setGeminiApiKey(String key) async {
    await _storage.write(key: _geminiKey, value: key);
  }

  // Groq API Key
  static Future<String?> getGroqApiKey() async {
    return _storage.read(key: _groqKey);
  }

  static Future<void> setGroqApiKey(String key) async {
    await _storage.write(key: _groqKey, value: key);
  }

  // OpenRouter API Key
  static Future<String?> getOpenRouterApiKey() async {
    return _storage.read(key: _openRouterKey);
  }

  static Future<void> setOpenRouterApiKey(String key) async {
    await _storage.write(key: _openRouterKey, value: key);
  }

  /// Check if any API keys are configured
  static Future<bool> hasAnyApiKey() async {
    final gemini = await getGeminiApiKey();
    final groq = await getGroqApiKey();
    final openRouter = await getOpenRouterApiKey();
    return (gemini?.isNotEmpty ?? false) ||
           (groq?.isNotEmpty ?? false) ||
           (openRouter?.isNotEmpty ?? false);
  }

  /// Clear all API keys (for logout/reset)
  static Future<void> clearAllKeys() async {
    await _storage.delete(key: _geminiKey);
    await _storage.delete(key: _groqKey);
    await _storage.delete(key: _openRouterKey);
    await _storage.delete(key: 'initialized');
  }

  /// Get all keys as map (for debugging)
  static Future<Map<String, String?>> getAllKeys() async {
    return {
      'gemini': await getGeminiApiKey(),
      'groq': await getGroqApiKey(),
      'openrouter': await getOpenRouterApiKey(),
    };
  }
}