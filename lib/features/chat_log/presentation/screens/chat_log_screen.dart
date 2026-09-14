import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/features/dashboard/providers/profile_provider.dart';
import 'package:eatwise/features/dashboard/providers/stats_provider.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/features/food_ai/presentation/providers/gemini_provider.dart';

const _uuid = Uuid();
const _maxImages = 5;
const _maxInputLength = 2000;
const _maxHistory = 200;

// ── Chat message model ──
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final MealAnalysis? mealResult;
  final List<ValidatedFoodItem>? validatedItems;
  final String? error;
  final List<String> imagePaths;
  final DateTime timestamp;
  bool pendingApproval;
  bool approved;
  bool isEditing;
  Map<int, FoodItem>? editedItems;
  String? selectedMealType;

  String? get imagePath => imagePaths.isNotEmpty ? imagePaths.first : null;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.mealResult,
    this.validatedItems,
    this.error,
    List<String>? imagePaths,
    DateTime? timestamp,
    this.pendingApproval = false,
    this.approved = false,
    this.isEditing = false,
    this.editedItems,
    this.selectedMealType,
  })  : id = id ?? _uuid.v4(),
        imagePaths = imagePaths ?? [],
        timestamp = timestamp ?? DateTime.now();
}

// ── Riverpod provider ──
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void add(ChatMessage msg) {
    state = [...state, msg];
    _capHistory();
  }

  void clear() => state = [];

  void _capHistory() {
    if (state.length > _maxHistory) {
      state = state.sublist(state.length - _maxHistory);
    }
  }

  void updateText(String id, String newText) {
    state = [
      for (final m in state)
        if (m.id == id)
          ChatMessage(
            id: m.id,
            text: newText,
            isUser: m.isUser,
            imagePaths: m.imagePaths,
            timestamp: m.timestamp,
            isEditing: false,
          )
        else
          m,
    ];
  }

  void startEditing(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          ChatMessage(
            id: m.id, text: m.text, isUser: m.isUser,
            imagePaths: m.imagePaths, timestamp: m.timestamp,
            isEditing: true, editedItems: m.editedItems,
            selectedMealType: m.selectedMealType,
            pendingApproval: m.pendingApproval, approved: m.approved,
            mealResult: m.mealResult, validatedItems: m.validatedItems, error: m.error,
          )
        else
          m,
    ];
  }

  void cancelEditing(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          ChatMessage(
            id: m.id, text: m.text, isUser: m.isUser,
            imagePaths: m.imagePaths, timestamp: m.timestamp,
            isEditing: false, editedItems: m.editedItems,
            selectedMealType: m.selectedMealType,
            pendingApproval: m.pendingApproval, approved: m.approved,
            mealResult: m.mealResult, validatedItems: m.validatedItems, error: m.error,
          )
        else
          m,
    ];
  }

  void removeMessage(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void removeMessagesAfter(String id) {
    final idx = state.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    state = state.sublist(0, idx + 1);
  }

  void approveMessage(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          ChatMessage(
            id: m.id, text: m.text, isUser: m.isUser,
            mealResult: m.mealResult, validatedItems: m.validatedItems,
            imagePaths: m.imagePaths, timestamp: m.timestamp,
            selectedMealType: m.selectedMealType,
            pendingApproval: false, approved: true,
            editedItems: m.editedItems,
          )
        else
          m,
    ];
  }

  void discardMessage(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          ChatMessage(
            id: m.id, text: m.text, isUser: m.isUser,
            mealResult: m.mealResult, validatedItems: m.validatedItems,
            imagePaths: m.imagePaths, timestamp: m.timestamp,
            pendingApproval: false, editedItems: m.editedItems,
          )
        else
          m,
    ];
  }

  void notify() {
    if (state.isNotEmpty) state = List.from(state);
  }
}

// ── Screen ──
class ChatLogScreen extends ConsumerStatefulWidget {
  const ChatLogScreen({super.key});
  @override
  ConsumerState<ChatLogScreen> createState() => _ChatLogScreenState();
}

class _ChatLogScreenState extends ConsumerState<ChatLogScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _sendLocked = false;
  final List<String> _pendingImagePaths = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isQuestion(String text) {
    if (text.length < 2) return false;
    if (text.contains('?')) return true;
    if (RegExp(r'^(what|how|why|when|where|who|is |are |do |does |can |could |would |will |did |tell me|explain)\b', caseSensitive: false).hasMatch(text)) return true;
    final foodKeywords = RegExp(r'\b(ate|had|eat|drank|i\s+had|i\s+ate|rice|egg|chicken|fish|pork|beef|meal|lunch|dinner|breakfast|snack|food|skyflakes|pandesal|adobo|sinigang|banana|turon|taho|bbq|tocino|longganisa|tinola|sisig|lechon|pancit|lumpia|halo|mango|pizza|burger|pasta|salad|soup|bread|milk|coffee|juice|water)\b', caseSensitive: false);
    if (foodKeywords.hasMatch(text)) return false;
    return false;
  }

  List<({String role, String text})> _buildPriorMessages() {
    final msgs = ref.read(chatMessagesProvider);
    return msgs
        .where((m) => m.isUser || m.text.isNotEmpty)
        .map((m) => (role: m.isUser ? 'user' : 'assistant', text: m.isUser ? m.text : m.text))
        .toList();
  }

  void _addInfoMessage(String text) {
    ref.read(chatMessagesProvider.notifier).add(
      ChatMessage(text: text, isUser: false),
    );
  }

  void _sendMessage() {
    if (_sendLocked || _isLoading) return;
    final text = _controller.text.trim();
    if ((text.isEmpty && _pendingImagePaths.isEmpty) || _isLoading) return;

    if (text.length > _maxInputLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message too long. Please keep it under 2,000 characters.')),
      );
      return;
    }

    _sendLocked = true;
    final imagePaths = List<String>.from(_pendingImagePaths);
    final userMsg = ChatMessage(text: text, isUser: true, imagePaths: imagePaths, timestamp: DateTime.now());
    ref.read(chatMessagesProvider.notifier).add(userMsg);
    _controller.clear();
    setState(() {
      _isLoading = true;
      _pendingImagePaths.clear();
    });
    _scrollToBottom();

    if (imagePaths.isNotEmpty) {
      _handleImageLog(text, imagePaths);
      return;
    }

    if (text.length < 3) {
      _addInfoMessage('Please describe what you ate with at least a few words. '
          'For example: "I had chicken adobo with rice"');
      _done();
      return;
    }

    if (!_isQuestion(text)) {
      final meaningfulWords = text
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 3)
          .length;
      if (meaningfulWords <= 1) {
        _addInfoMessage('I need a bit more detail to estimate nutrition. '
            'Try describing the food, approximate portion, and how it was cooked.');
        _done();
        return;
      }
    }

    if (_isQuestion(text)) {
      _handleConversation(text);
    } else {
      _handleFoodLog(text);
    }
  }

  void _done() {
    _sendLocked = false;
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_pendingImagePaths.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images per message.')),
      );
      return;
    }
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (photo != null && mounted) {
        setState(() => _pendingImagePaths.add(photo.path));
      }
    } catch (_) {}
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImagePaths.removeAt(index));
  }

  void _handleConversation(String text) {
    final chat = ref.read(askAiServiceProvider);
    final prior = _buildPriorMessages();
    chat.sendMessageWithHistory(text, prior).then((result) {
      if (!mounted) return;
      ref.read(chatMessagesProvider.notifier).add(ChatMessage(text: result.text, isUser: false, timestamp: DateTime.now()));
      _done();
    }).catchError((e) {
      if (!mounted) return;
      final msg = e.toString().contains('AllProvidersExhausted')
          ? 'All AI services are busy right now. Please try again in a minute.'
          : 'Could not get a response. Check your internet and try again.';
      ref.read(chatMessagesProvider.notifier).add(
          ChatMessage(text: msg, isUser: false, error: e.toString(), timestamp: DateTime.now()));
      _done();
    });
  }

  void _handleFoodLog(String text) {
    final svc = ref.read(foodLogServiceProvider);
    svc.analyzeText(text).then((analysis) {
      if (!mounted) return;
      final msg = ChatMessage(
        text: analysis.mealAnalysis.summary,
        isUser: false,
        mealResult: analysis.mealAnalysis,
        validatedItems: analysis.items,
        pendingApproval: true,
        selectedMealType: analysis.mealAnalysis.mealType,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).add(msg);
      _done();
    }).catchError((e) {
      if (!mounted) return;
      final msg = e.toString().contains('All food providers')
          ? 'AI logging is temporarily unavailable. Please try again shortly, or add this meal manually.'
          : 'Could not analyze that. Try adding more detail — '
              'like portion size, how it was cooked, or the brand name.';
      ref.read(chatMessagesProvider.notifier).add(
          ChatMessage(text: msg, isUser: false, error: e.toString(), timestamp: DateTime.now()));
      _done();
    });
  }

  void _handleImageLog(String text, List<String> imagePaths) async {
    try {
      final bytesList = <Uint8List>[];
      for (final path in imagePaths) {
        bytesList.add(await File(path).readAsBytes());
      }
      final svc = ref.read(foodLogServiceProvider);
      final analysis = await svc.analyzeMultipleImages(
        bytesList,
        fallbackText: text.isNotEmpty ? text : null,
      );
      if (!mounted) return;
      final msg = ChatMessage(
        text: analysis.mealAnalysis.summary,
        isUser: false,
        mealResult: analysis.mealAnalysis,
        validatedItems: analysis.items,
        pendingApproval: true,
        selectedMealType: analysis.mealAnalysis.mealType,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).add(msg);
      _done();
    } catch (e) {
      if (!mounted) return;
      ref.read(chatMessagesProvider.notifier).add(
          ChatMessage(
              text: 'Could not analyze that photo. Try describing the meal in text instead.',
              isUser: false,
              error: e.toString(),
              timestamp: DateTime.now()));
      _done();
    }
  }

  void _onItemChanged(String msgId, int itemIndex, FoodItem edited) {
    final msgs = ref.read(chatMessagesProvider);
    final idx = msgs.indexWhere((m) => m.id == msgId);
    if (idx == -1) return;
    msgs[idx].editedItems ??= {};
    msgs[idx].editedItems![itemIndex] = edited;
    ref.read(chatMessagesProvider.notifier).notify();
  }

  void _onMealTypeChanged(String msgId, String mealType) {
    final msgs = ref.read(chatMessagesProvider);
    final idx = msgs.indexWhere((m) => m.id == msgId);
    if (idx == -1) return;
    msgs[idx].selectedMealType = mealType;
    ref.read(chatMessagesProvider.notifier).notify();
  }

  List<FoodItem> _getCurrentItems(ChatMessage msg) {
    final originals = msg.mealResult?.foods ?? [];
    if (msg.editedItems == null || msg.editedItems!.isEmpty) return originals;
    return List.generate(originals.length, (i) => msg.editedItems![i] ?? originals[i]);
  }

  Future<void> _approveLog(ChatMessage msg) async {
    final items = _getCurrentItems(msg);
    if (items.isEmpty) return;

    final meal = MealAnalysis(
      foods: items,
      totalCalories: items.fold(0.0, (s, f) => s + f.calories),
      totalProtein: items.fold(0.0, (s, f) => s + f.proteinG),
      totalCarbs: items.fold(0.0, (s, f) => s + f.carbsG),
      totalFats: items.fold(0.0, (s, f) => s + f.fatsG),
      summary: msg.mealResult?.summary ?? msg.text,
      mealType: msg.selectedMealType ?? _inferMealType(),
    );

    try {
      await AppDatabase.insertFoodLog(
        logDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mealType: meal.mealType,
        source: msg.imagePaths.isNotEmpty ? 'photo' : 'chat',
        meal: meal,
        imagePath: msg.imagePath,
      );
      ref.read(logVersionProvider.notifier).update((v) => v + 1);
      if (!mounted) return;
      ref.read(chatMessagesProvider.notifier).approveMessage(msg.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged: ${meal.summary.isNotEmpty ? meal.summary : "${meal.totalCalories.toStringAsFixed(0)} cal"}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  String _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    return 'dinner';
  }

  void _discardLog(ChatMessage msg) {
    ref.read(chatMessagesProvider.notifier).discardMessage(msg.id);
  }

  void _onDeleteMessage(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatMessagesProvider.notifier).removeMessage(msg.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onCopyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  void _onEditMessage(ChatMessage msg) {
    ref.read(chatMessagesProvider.notifier).startEditing(msg.id);
  }

  void _onConfirmEdit(ChatMessage msg, String newText) {
    if (newText.trim().isEmpty) return;
    ref.read(chatMessagesProvider.notifier).updateText(msg.id, newText.trim());
    ref.read(chatMessagesProvider.notifier).removeMessagesAfter(msg.id);
    setState(() {
      _isLoading = true;
      _sendLocked = true;
    });
    _scrollToBottom();

    final imagePaths = msg.imagePaths;
    if (imagePaths.isNotEmpty) {
      _handleImageLog(newText.trim(), imagePaths);
    } else if (_isQuestion(newText.trim())) {
      _handleConversation(newText.trim());
    } else {
      _handleFoodLog(newText.trim());
    }
  }

  void _onCancelEdit(ChatMessage msg) {
    ref.read(chatMessagesProvider.notifier).cancelEditing(msg.id);
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('All messages will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatMessagesProvider.notifier).clear();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageList() {
    return Consumer(builder: (context, ref, _) {
      final messages = ref.watch(chatMessagesProvider);
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        itemCount: messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const _TypingIndicator();
          }
          final msg = messages[index];
          final prevMsg = index > 0 ? messages[index - 1] : null;
          final showHeader = prevMsg == null || prevMsg.isUser != msg.isUser;

          return _MessageBubble(
            key: ValueKey(msg.id),
            message: msg,
            showHeader: showHeader,
            onItemChanged: (itemIndex, item) => _onItemChanged(msg.id, itemIndex, item),
            onMealTypeChanged: (type) => _onMealTypeChanged(msg.id, type),
            currentItems: _getCurrentItems(msg),
            onApprove: msg.pendingApproval ? () => _approveLog(msg) : null,
            onDiscard: msg.pendingApproval ? () => _discardLog(msg) : null,
            onCopy: () => _onCopyMessage(msg),
            onDelete: () => _onDeleteMessage(msg),
            onEdit: msg.isUser ? () => _onEditMessage(msg) : null,
            onConfirmEdit: (newText) => _onConfirmEdit(msg, newText),
            onCancelEdit: () => _onCancelEdit(msg),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'EatWise Coach',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                Row(
                  children: [
                    Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Active • Nutrition AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(statsProvider);
              final streak = statsAsync.valueOrNull?.currentStreak ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.carbs.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '🔥 ${streak}d',
                  style: const TextStyle(
                    color: AppColors.carbs,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Consumer(builder: (context, ref, _) {
            final profile = ref.watch(profileProvider);
            return GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? (profile.avatarUrl!.startsWith('http')
                          ? NetworkImage(profile.avatarUrl!)
                          : FileImage(File(profile.avatarUrl!))) as ImageProvider
                      : null,
                  child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                      ? Text(
                          (profile.name.isNotEmpty ? profile.name[0] : 'E').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'New chat',
            onPressed: _showClearChatDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _isLoading || ref.watch(chatMessagesProvider).isNotEmpty ? _buildMessageList() : _EmptyState(onSuggestionTap: (t) {
            _controller.text = t;
            _sendMessage();
          })),
          if (_pendingImagePaths.isNotEmpty)
            _MultiImagePreview(paths: _pendingImagePaths, onRemove: _removePendingImage),
          _InputBar(
            controller: _controller,
            isLoading: _isLoading,
            onSend: _sendMessage,
            onPickImage: _pickImage,
            imageCount: _pendingImagePaths.length,
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator ──
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1),
            ),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF181C24),
              child: Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _animController,
            builder: (_, child) {
              final t = _animController.value;
              return Row(
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final opacity = ((t - delay) % 1.0).clamp(0.0, 0.6) / 0.6;
                  return Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 4.0 : 0),
                    child: Opacity(
                      opacity: 0.3 + (0.7 * opacity),
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──
class _EmptyState extends StatelessWidget {
  final void Function(String text) onSuggestionTap;
  const _EmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.08),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Welcome! Meet your AI Nutrition Coach',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log Filipino meals naturally or snap a photo. I estimate exact macros calibrated with verified nutritional data.',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'QUICK LOG EXAMPLES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              '1 bowl Sinigang na Baboy & 1 cup rice',
              'Chicken Inasal with sinangag',
              '2 boiled eggs & 1 pandesal',
              'Tapsilog with sunny side egg',
              '1 bowl Arroz Caldo with egg',
            ].map((t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                label: Text(
                  t,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
                side: BorderSide(
                  color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => onSuggestionTap(t),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ── Multi-image preview ──
class _MultiImagePreview extends StatelessWidget {
  final List<String> paths;
  final void Function(int index) onRemove;
  const _MultiImagePreview({required this.paths, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(paths[i]), width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 144, cacheHeight: 144),
            ),
            Positioned(
              top: 2, right: 2,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ──
class _InputBar extends ConsumerWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final void Function(ImageSource source) onPickImage;
  final int imageCount;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onPickImage,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 6, 8, bottomPad > 8 ? bottomPad : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -1), blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AttachImageButton(
            disabled: isLoading || imageCount >= _maxImages,
            onPickImage: onPickImage,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLength: _maxInputLength,
                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                decoration: const InputDecoration(
                  hintText: 'e.g. 2 eggs and rice',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _IconBtn(
            icon: Icons.mic_none_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Voice logging needs speech recognition — coming soon.'),
                duration: Duration(seconds: 2),
              ),
            ),
            disabled: isLoading,
            semanticLabel: 'Voice input',
          ),
          const SizedBox(width: 4),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
                )
              : _IconBtn(icon: Icons.send_rounded, onTap: onSend, disabled: false, fill: true, semanticLabel: 'Send'),
        ],
      ),
    );
  }
}

class _AttachImageButton extends StatelessWidget {
  final bool disabled;
  final void Function(ImageSource source) onPickImage;

  const _AttachImageButton({
    required this.disabled,
    required this.onPickImage,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.add_a_photo_outlined),
                title: Text('Attach an image'),
                subtitle: Text('Add a meal photo for a more accurate estimate.'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Attach image',
      child: Tooltip(
        message: 'Attach image',
        child: InkWell(
          onTap: disabled ? null : () => _showPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: disabled ? 0.05 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 21,
              color: disabled ? Theme.of(context).disabledColor : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;
  final bool fill;
  final String? semanticLabel;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.disabled,
    this.fill = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: fill ? AppColors.primary : Colors.transparent, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: fill ? Colors.white : (disabled ? Colors.grey.shade300 : AppColors.primary)),
        ),
      ),
    );
  }
}

// ── Message bubble ──
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showHeader;
  final void Function(int i, FoodItem) onItemChanged;
  final ValueChanged<String> onMealTypeChanged;
  final List<FoodItem> currentItems;
  final VoidCallback? onApprove;
  final VoidCallback? onDiscard;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onConfirmEdit;
  final VoidCallback? onCancelEdit;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.showHeader,
    required this.onItemChanged,
    required this.onMealTypeChanged,
    required this.currentItems,
    this.onApprove,
    this.onDiscard,
    this.onCopy,
    this.onDelete,
    this.onEdit,
    this.onConfirmEdit,
    this.onCancelEdit,
  });

  void _showContextMenu(BuildContext context) {
    final isUser = message.isUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            _ContextMenuItem(icon: Icons.copy, label: 'Copy text', onTap: () { Navigator.pop(ctx); onCopy?.call(); }),
            if (isUser && onEdit != null)
              _ContextMenuItem(icon: Icons.edit, label: 'Edit message', onTap: () { Navigator.pop(ctx); onEdit?.call(); }),
            _ContextMenuItem(icon: Icons.delete_outline, label: 'Delete', onTap: () { Navigator.pop(ctx); onDelete?.call(); }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: message.isUser ? AppColors.primary : AppColors.secondary,
                    child: Icon(message.isUser ? Icons.person : Icons.auto_awesome, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.isUser ? 'You' : 'MacroAI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (message.isUser)
            _UserBubble(
              message: message,
              isEditing: message.isEditing,
              onConfirmEdit: onConfirmEdit,
              onCancelEdit: onCancelEdit,
            )
          else
            _AiBubble(
              text: message.text,
              mealResult: message.mealResult,
              validatedItems: message.validatedItems,
              selectedMealType: message.selectedMealType,
              currentItems: currentItems,
              pendingApproval: message.pendingApproval,
              approved: message.approved,
              messageId: message.id,
              onItemChanged: onItemChanged,
              onMealTypeChanged: onMealTypeChanged,
              onApprove: onApprove,
              onDiscard: onDiscard,
            ),
          if (showHeader) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: isDestructive ? Colors.red : Colors.grey.shade700),
      title: Text(label, style: TextStyle(fontSize: 15, color: isDestructive ? Colors.red : null)),
      onTap: onTap,
      dense: true,
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isEditing;
  final ValueChanged<String>? onConfirmEdit;
  final VoidCallback? onCancelEdit;

  const _UserBubble({
    required this.message,
    required this.isEditing,
    this.onConfirmEdit,
    this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.imagePaths.isNotEmpty) ...[
              _buildImageGrid(),
              const SizedBox(height: 4),
            ],
            if (isEditing)
              _buildEditMode(context)
            else if (message.text.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18), topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final paths = message.imagePaths;
    if (paths.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(paths.first), width: 180, height: 180, fit: BoxFit.cover, cacheWidth: 360, cacheHeight: 360),
      );
    }
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: paths.map((p) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(p), width: paths.length <= 2 ? 140 : 110, height: paths.length <= 2 ? 140 : 110, fit: BoxFit.cover, cacheWidth: 220, cacheHeight: 220),
      )).toList(),
    );
  }

  Widget _buildEditMode(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 15),
            textInputAction: TextInputAction.send,
            onSubmitted: (v) => onConfirmEdit?.call(v),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onCancelEdit?.call(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onConfirmEdit?.call(controller.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Save & Rerun', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;
  final MealAnalysis? mealResult;
  final List<ValidatedFoodItem>? validatedItems;
  final String? selectedMealType;
  final List<FoodItem> currentItems;
  final bool pendingApproval, approved;
  final String messageId;
  final void Function(int i, FoodItem) onItemChanged;
  final ValueChanged<String> onMealTypeChanged;
  final VoidCallback? onApprove, onDiscard;

  const _AiBubble({
    required this.text,
    this.mealResult,
    this.validatedItems,
    this.selectedMealType,
    required this.currentItems,
    required this.pendingApproval,
    required this.approved,
    required this.messageId,
    required this.onItemChanged,
    required this.onMealTypeChanged,
    this.onApprove,
    this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4), topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Text(text, style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
            if (mealResult != null) ...[
              const SizedBox(height: 8),
              _MealResultCard(
                messageId: messageId,
                mealResult: mealResult!,
                validatedItems: validatedItems,
                selectedMealType: selectedMealType,
                currentItems: currentItems,
                pendingApproval: pendingApproval,
                approved: approved,
                onItemChanged: onItemChanged,
                onMealTypeChanged: onMealTypeChanged,
                onApprove: onApprove,
                onDiscard: onDiscard,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Compact Meal Result Card (Figma 1:197) ──
class _MealResultCard extends StatelessWidget {
  final String messageId;
  final MealAnalysis mealResult;
  final List<ValidatedFoodItem>? validatedItems;
  final String? selectedMealType;
  final List<FoodItem> currentItems;
  final bool pendingApproval, approved;
  final void Function(int i, FoodItem) onItemChanged;
  final ValueChanged<String> onMealTypeChanged;
  final VoidCallback? onApprove, onDiscard;

  const _MealResultCard({
    required this.messageId,
    required this.mealResult,
    this.validatedItems,
    this.selectedMealType,
    required this.currentItems,
    required this.pendingApproval,
    required this.approved,
    required this.onItemChanged,
    required this.onMealTypeChanged,
    this.onApprove,
    this.onDiscard,
  });

  void _showItemEditSheet(BuildContext context, int index, FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemEditModalSheet(
        item: item,
        onSaved: (editedItem) => onItemChanged(index, editedItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCal = currentItems.fold<double>(0, (s, f) => s + f.calories);
    final totalP = currentItems.fold<double>(0, (s, f) => s + f.proteinG);
    final totalC = currentItems.fold<double>(0, (s, f) => s + f.carbsG);
    final totalF = currentItems.fold<double>(0, (s, f) => s + f.fatsG);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryName = currentItems.isNotEmpty
        ? (currentItems.length == 1
            ? currentItems.first.name
            : '${currentItems.first.name} & more')
        : 'Logged Meal';
    final portionSummary = currentItems
        .map((f) => f.portionDescription.isNotEmpty
            ? f.portionDescription
            : '${f.portionSizeGrams.toStringAsFixed(0)}g')
        .join(' • ');


    return Container(
      margin: const EdgeInsets.only(left: 4, top: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dish Heading ──
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (portionSummary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          portionSummary,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (approved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LOGGED',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Compact Telemetry Strip (Figma 1:197) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF090D17) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${totalCal.toStringAsFixed(0)} ',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'KCAL',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _miniMacro('${totalP.toStringAsFixed(0)}g', 'Pro', AppColors.protein),
                  _macroDot(isDark),
                  _miniMacro('${totalC.toStringAsFixed(0)}g', 'Carb', AppColors.carbs),
                  _macroDot(isDark),
                  _miniMacro('${totalF.toStringAsFixed(0)}g', 'Fat', AppColors.fats),
                ],
              ),
            ),

            // ── Compact Itemized List (1 row per ingredient) ──
            if (currentItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'DETECTED INGREDIENTS (TAP TO EDIT)',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(currentItems.length, (i) {
                final item = currentItems[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showItemEditSheet(context, i, item),
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141923) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0x14FFFFFF) : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B202C) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.portionSizeGrams.toStringAsFixed(0)}g',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.calories.toStringAsFixed(0)} cal',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // ── Approval and Logging Action ──
            if (pendingApproval) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onDiscard,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Discard', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onApprove,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF00C853)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  'LOG MEAL',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (approved) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 5),
                  Text(
                    'Logged to Daily Fuel timeline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniMacro(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _macroDot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '•',
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Modal Bottom Sheet for Editing Item Grams & Macros ──
class _ItemEditModalSheet extends StatefulWidget {
  final FoodItem item;
  final ValueChanged<FoodItem> onSaved;

  const _ItemEditModalSheet({
    required this.item,
    required this.onSaved,
  });

  @override
  State<_ItemEditModalSheet> createState() => _ItemEditModalSheetState();
}

class _ItemEditModalSheetState extends State<_ItemEditModalSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _portionCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatsCtrl;

  late double _baseGrams;
  late double _baseCal;
  late double _baseP;
  late double _baseC;
  late double _baseF;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _baseGrams = widget.item.portionSizeGrams > 0 ? widget.item.portionSizeGrams : 100;
    _baseCal = widget.item.calories;
    _baseP = widget.item.proteinG;
    _baseC = widget.item.carbsG;
    _baseF = widget.item.fatsG;

    _portionCtrl = TextEditingController(text: _baseGrams.toStringAsFixed(0));
    _calCtrl = TextEditingController(text: _baseCal.toStringAsFixed(0));
    _proteinCtrl = TextEditingController(text: _baseP.toStringAsFixed(1));
    _carbsCtrl = TextEditingController(text: _baseC.toStringAsFixed(1));
    _fatsCtrl = TextEditingController(text: _baseF.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _portionCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  void _onGramsChanged(double newGrams) {
    if (newGrams <= 0) return;
    final ratio = _baseGrams > 0 ? (newGrams / _baseGrams) : 1.0;
    setState(() {
      _portionCtrl.text = newGrams.toStringAsFixed(0);
      _calCtrl.text = (_baseCal * ratio).toStringAsFixed(0);
      _proteinCtrl.text = (_baseP * ratio).toStringAsFixed(1);
      _carbsCtrl.text = (_baseC * ratio).toStringAsFixed(1);
      _fatsCtrl.text = (_baseF * ratio).toStringAsFixed(1);
    });
  }

  void _adjustGrams(double delta) {
    final cur = double.tryParse(_portionCtrl.text) ?? _baseGrams;
    final updated = math.max(10.0, cur + delta);
    _onGramsChanged(updated);
  }

  void _save() {
    final updated = widget.item.copyWith(
      name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : widget.item.name,
      portionSizeGrams: double.tryParse(_portionCtrl.text) ?? widget.item.portionSizeGrams,
      portionDescription: '${_portionCtrl.text}g',
      calories: double.tryParse(_calCtrl.text) ?? widget.item.calories,
      proteinG: double.tryParse(_proteinCtrl.text) ?? widget.item.proteinG,
      carbsG: double.tryParse(_carbsCtrl.text) ?? widget.item.carbsG,
      fatsG: double.tryParse(_fatsCtrl.text) ?? widget.item.fatsG,
    );
    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1420) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Ingredient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Name Field
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Ingredient Name',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Portion Grams Stepper
          Text(
            'PORTION SIZE (GRAMS)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _stepperButton(Icons.remove, () => _adjustGrams(-10), isDark),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _portionCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    suffixText: 'g',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null && d > 0) _onGramsChanged(d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _stepperButton(Icons.add, () => _adjustGrams(10), isDark),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Preset Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _presetChip('50g', () => _onGramsChanged(50), isDark),
              _presetChip('100g', () => _onGramsChanged(100), isDark),
              _presetChip('150g', () => _onGramsChanged(150), isDark),
              _presetChip('200g', () => _onGramsChanged(200), isDark),
              _presetChip('+25g', () => _adjustGrams(25), isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Macro Breakdown Grid
          Row(
            children: [
              _macroField('Calories', _calCtrl, AppColors.primary),
              const SizedBox(width: 8),
              _macroField('Protein (g)', _proteinCtrl, AppColors.protein),
              const SizedBox(width: 8),
              _macroField('Carbs (g)', _carbsCtrl, AppColors.carbs),
              const SizedBox(width: 8),
              _macroField('Fats (g)', _fatsCtrl, AppColors.fats),
            ],
          ),
          const SizedBox(height: 20),

          // Save button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _save,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF00C853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Center(
                  child: Text(
                    'UPDATE INGREDIENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B202C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181D28) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _macroField(String label, TextEditingController ctrl, Color color) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 9.5, color: color),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
