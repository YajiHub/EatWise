import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/food_ai/presentation/providers/gemini_provider.dart';

class AskAiMessage {
  final String text;
  final bool isUser;
  const AskAiMessage({required this.text, required this.isUser});
}

class AskAiMessagesNotifier extends StateNotifier<List<AskAiMessage>> {
  AskAiMessagesNotifier() : super([]);

  void add(AskAiMessage msg) => state = [...state, msg];
  void clear() => state = [];
}

final askAiMessagesProvider =
    StateNotifierProvider<AskAiMessagesNotifier, List<AskAiMessage>>((ref) {
  return AskAiMessagesNotifier();
});

class AskAiScreen extends ConsumerStatefulWidget {
  const AskAiScreen({super.key});
  @override
  ConsumerState<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends ConsumerState<AskAiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() => _loading = true);
    _controller.clear();

    ref.read(askAiMessagesProvider.notifier).add(AskAiMessage(text: text, isUser: true));

    ref.read(askAiServiceProvider).sendMessage(text).then((r) {
      if (!mounted) return;
      ref.read(askAiMessagesProvider.notifier).add(AskAiMessage(text: r.text, isUser: false));
      setState(() => _loading = false);
      _scrollToTop();
    }).catchError((e) {
      if (!mounted) return;
      final msg = e.toString().contains('AllProvidersExhausted')
          ? 'All AI services are busy. Please try again in a minute.'
          : 'Could not get a response. Check your internet and try again.';
      ref.read(askAiMessagesProvider.notifier).add(AskAiMessage(text: msg, isUser: false));
      setState(() => _loading = false);
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _newConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New conversation?'),
        content: const Text('All messages will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(aiOrchestratorProvider).clearChatHistory();
              ref.read(askAiMessagesProvider.notifier).clear();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.04);
    final messages = ref.watch(askAiMessagesProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ask MacroAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New conversation',
            onPressed: _newConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final m = messages[i];
                      return m.isUser
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16).copyWith(bottomRight: Radius.circular(4)),
                                  ),
                                  child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: Radius.circular(4)),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                  ),
                                  child: Text(m.text, style: const TextStyle(fontSize: 15)),
                                ),
                              ),
                            );
                    },
                  ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 72, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Ask MacroAI anything about nutrition', style: TextStyle(fontSize: 17, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'How accurate are your estimates?\nWhat are the macros in chicken adobo?\nIs intermittent fasting effective?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _inputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 0 ? bottomInset : 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Ask about nutrition, macros, fasting...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: Icon(_loading ? Icons.hourglass_top : Icons.send, color: Colors.white, size: 20),
              onPressed: _loading ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
