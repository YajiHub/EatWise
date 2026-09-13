import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/storage/secure_storage_service.dart';
import 'app.dart';
import 'loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Show loading screen immediately while we initialize
  runApp(const LoadingScreenShell());

  _init().then((_) {
    runApp(
      const ProviderScope(
        child: EatWiseApp(),
      ),
    );
  });
}

Future<void> _init() async {
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('[Init] Loaded .env file successfully');
  } catch (e) {
    debugPrint('[Init] Note: .env not loaded from assets ($e)');
  }
  try {
    await SecureStorageService.initializeFromEnv();
    await AiConfig.loadKeys();
    debugPrint('[Init] AI Providers status: Gemini=${AiConfig.geminiApiKey.isNotEmpty}, Groq=${AiConfig.groqApiKey.isNotEmpty}, OpenRouter=${AiConfig.openRouterApiKey.isNotEmpty}');
  } catch (e) {
    debugPrint('[Init] Error initializing config: $e');
  }
}

/// Minimal MaterialApp wrapper that shows the loading screen during init.
class LoadingScreenShell extends StatelessWidget {
  const LoadingScreenShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

