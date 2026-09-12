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
  } catch (_) {
    // .env is not packaged in production assets — keys are read from secure storage
  }
  try {
    await SecureStorageService.initializeFromEnv();
    await AiConfig.loadKeys();
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

