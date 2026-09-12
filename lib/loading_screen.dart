import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eatwise/core/constants/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  final String? error;

  const LoadingScreen({super.key, this.message, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                ),
                const SizedBox(height: 20),
                const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: AppColors.primary.withValues(alpha: 0.3),
              highlightColor: AppColors.primary.withValues(alpha: 0.1),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 24),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade400,
              highlightColor: Colors.grey.shade200,
              child: Container(
                width: 180, height: 14,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)),
              ),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 120, height: 10,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 32),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 140, height: 36,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // All initialization already done in main() — just a brief frame to show loading.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      // Navigate to app
      // The EatWiseApp will be shown via the runApp below, so this is a no-op signal.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(error: _error);
  }
}
