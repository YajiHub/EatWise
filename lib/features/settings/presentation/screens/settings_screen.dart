import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/theme/theme_mode_provider.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/fasting_timer_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _fastingNotif = false;
  bool _dailySummaryNotif = false;
  bool _unitsMetric = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadToggles();
  }

  Future<void> _loadToggles() async {
    final f = await AppDatabase.getSetting('notif_fasting_enabled');
    final d = await AppDatabase.getSetting('notif_daily_summary_enabled');
    final u = await AppDatabase.getSetting('units');
    if (!mounted) return;
    setState(() {
      _fastingNotif = f == 'true';
      _dailySummaryNotif = d == 'true';
      _unitsMetric = u != 'imperial';
      _loaded = true;
    });
  }

  Future<void> _setFastingNotif(bool v) async {
    setState(() => _fastingNotif = v);
    await AppDatabase.setSetting('notif_fasting_enabled', v ? 'true' : 'false');
  }

  Future<void> _setDailySummaryNotif(bool v) async {
    setState(() => _dailySummaryNotif = v);
    await AppDatabase.setSetting('notif_daily_summary_enabled', v ? 'true' : 'false');
  }

  Future<void> _setUnits(bool metric) async {
    setState(() => _unitsMetric = metric);
    await AppDatabase.setSetting('units', metric ? 'metric' : 'imperial');
  }

  @override
  Widget build(BuildContext context) {
    final eatFrom = ref.watch(fastingEndTimeProvider); // fast-end = eating starts
    final eatUntil = ref.watch(fastingStartTimeProvider); // fast-start = eating ends
    final scheduleLabel = _scheduleLabel(eatFrom, eatUntil);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sectionHeader('AI Configuration'),
                _aiKeysCard(),
                const SizedBox(height: 16),
                _sectionHeader('Fasting'),
                _fastingCard(eatFrom, eatUntil, scheduleLabel),
                const SizedBox(height: 16),
                _sectionHeader('Notifications'),
                _notificationsCard(),
                const SizedBox(height: 16),
                _sectionHeader('Appearance'),
                _appearanceCard(),
                const SizedBox(height: 16),
                _unitsCard(),
                const SizedBox(height: 24),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _fastingCard(TimeOfDay eatFrom, TimeOfDay eatUntil, String scheduleLabel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nights_stay, size: 20, color: AppColors.fasting),
                const SizedBox(width: 8),
                Text('Fasting Window',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: _showSchedulePresets,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(scheduleLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeChip(
                  label: 'Eat from',
                  time: eatFrom,
                  onPick: () => _pickTime(isEatUntil: false),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                ),
                _timeChip(
                  label: 'Eat until',
                  time: eatUntil,
                  onPick: () => _pickTime(isEatUntil: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined,
                color: AppColors.fasting),
            title: const Text('Fasting reminders'),
            subtitle: const Text(
                'Alert me when my eating window opens and closes.'),
            value: _fastingNotif,
            onChanged: _setFastingNotif,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.summarize_outlined,
                color: AppColors.primary),
            title: const Text('Daily summary'),
            subtitle:
                const Text('A daily recap of calories and macros logged.'),
            value: _dailySummaryNotif,
            onChanged: _setDailySummaryNotif,
          ),
        ],
      ),
    );
  }

  Widget _appearanceCard() {
    final mode = ref.watch(themeModeProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.phone_android, size: 16)),
                ButtonSegment(
                    value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: {mode},
              onSelectionChanged: (v) =>
                  ref.read(themeModeProvider.notifier).set(v.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.straighten, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Units', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Metric')),
                ButtonSegment(value: false, label: Text('Imperial')),
              ],
              selected: {_unitsMetric},
              onSelectionChanged: (v) => _setUnits(v.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.eating.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, size: 20, color: AppColors.eating),
            const SizedBox(height: 4),
            Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.eating)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            const Icon(Icons.edit, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(TimeOfDay eatFrom, TimeOfDay eatUntil) {
    final eatFromMin = eatFrom.hour * 60 + eatFrom.minute;
    final eatUntilMin = eatUntil.hour * 60 + eatUntil.minute;
    final eatingMin = eatUntilMin >= eatFromMin
        ? eatUntilMin - eatFromMin
        : (1440 - eatFromMin) + eatUntilMin;
    final fastingMin = 1440 - eatingMin;
    return '${fastingMin ~/ 60}:${eatingMin ~/ 60}';
  }

  Future<void> _pickTime({required bool isEatUntil}) async {
    final eatFrom = ref.read(fastingEndTimeProvider);
    final eatUntil = ref.read(fastingStartTimeProvider);
    final initial = isEatUntil ? eatUntil : eatFrom;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (picked != null) {
      _applyTimes(isEatUntil ? eatFrom : picked, isEatUntil ? picked : eatUntil);
    }
  }

  void _showSchedulePresets() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('Choose Fasting Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _presetOption(ctx, '12:12', '12h fast, 12h eat',
                      const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)),
                  _presetOption(ctx, '14:10', '14h fast, 10h eat',
                      const TimeOfDay(hour: 10, minute: 0), const TimeOfDay(hour: 20, minute: 0)),
                  _presetOption(ctx, '16:8', '16h fast, 8h eat (popular)',
                      const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 20, minute: 0)),
                  _presetOption(ctx, '18:6', '18h fast, 6h eat',
                      const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 20, minute: 0)),
                  _presetOption(ctx, '20:4', '20h fast, 4h eat',
                      const TimeOfDay(hour: 16, minute: 0), const TimeOfDay(hour: 20, minute: 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetOption(BuildContext ctx, String label, String description,
      TimeOfDay eatFrom, TimeOfDay eatUntil) {
    return ListTile(
      leading: const Icon(Icons.schedule, size: 22),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        Navigator.pop(ctx);
        _applyTimes(eatFrom, eatUntil);
      },
    );
  }

  void _applyTimes(TimeOfDay eatFrom, TimeOfDay eatUntil) {
    ref.read(fastingEndTimeProvider.notifier).state = eatFrom;
    ref.read(fastingStartTimeProvider.notifier).state = eatUntil;
    AppDatabase.setSetting('fasting_end_hour', eatFrom.hour.toString());
    AppDatabase.setSetting('fasting_end_minute', eatFrom.minute.toString());
    AppDatabase.setSetting('fasting_start_hour', eatUntil.hour.toString());
    AppDatabase.setSetting('fasting_start_minute', eatUntil.minute.toString());
    AppDatabase.setSetting('fasting_schedule', '');
  }

  Widget _aiKeysCard() {
    final hasGemini = AiConfig.geminiApiKey.isNotEmpty;
    final hasGroq = AiConfig.groqApiKey.isNotEmpty;
    final hasOpenRouter = AiConfig.openRouterApiKey.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Engine & API Keys',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hardware encrypted (Android Keystore / iOS Keychain)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _apiKeyTile(
            title: 'Google Gemini',
            subtitle: hasGemini ? 'Configured (${_maskKey(AiConfig.geminiApiKey)})' : 'Required for food photo scan & chat',
            isConfigured: hasGemini,
            badgeLabel: hasGemini ? 'Active' : 'Missing',
            badgeColor: hasGemini ? AppColors.primary : Colors.amber.shade800,
            icon: Icons.auto_awesome,
            iconColor: AppColors.primary,
            onTap: () => _showApiKeyDialog(
              providerName: 'Google Gemini',
              providerDesc: 'Powers photo food recognition, barcode nutrition insights, and the AI nutrition assistant. Free keys available at aistudio.google.com.',
              currentKey: AiConfig.geminiApiKey,
              onSave: (k) async {
                await AiConfig.setGeminiApiKey(k);
                if (mounted) setState(() {});
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _apiKeyTile(
            title: 'Groq (Llama 3.3)',
            subtitle: hasGroq ? 'Configured (${_maskKey(AiConfig.groqApiKey)})' : 'Ultra-fast secondary fallback',
            isConfigured: hasGroq,
            badgeLabel: hasGroq ? 'Active' : 'Optional',
            badgeColor: hasGroq ? AppColors.primary : Colors.grey,
            icon: Icons.bolt,
            iconColor: Colors.deepOrange,
            onTap: () => _showApiKeyDialog(
              providerName: 'Groq',
              providerDesc: 'Ultra-low latency LLM inference used as a high-speed fallback if Gemini hits rate limits.',
              currentKey: AiConfig.groqApiKey,
              onSave: (k) async {
                await AiConfig.setGroqApiKey(k);
                if (mounted) setState(() {});
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _apiKeyTile(
            title: 'OpenRouter',
            subtitle: hasOpenRouter ? 'Configured (${_maskKey(AiConfig.openRouterApiKey)})' : 'Optional third fallback',
            isConfigured: hasOpenRouter,
            badgeLabel: hasOpenRouter ? 'Active' : 'Optional',
            badgeColor: hasOpenRouter ? AppColors.primary : Colors.grey,
            icon: Icons.hub_outlined,
            iconColor: Colors.purple,
            onTap: () => _showApiKeyDialog(
              providerName: 'OpenRouter',
              providerDesc: 'Universal AI router used as an emergency failover provider.',
              currentKey: AiConfig.openRouterApiKey,
              onSave: (k) async {
                await AiConfig.setOpenRouterApiKey(k);
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiKeyTile({
    required String title,
    required String subtitle,
    required bool isConfigured,
    required String badgeLabel,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          badgeLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: badgeColor,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showApiKeyDialog({
    required String providerName,
    required String providerDesc,
    required String currentKey,
    required Future<void> Function(String) onSave,
  }) {
    final controller = TextEditingController(text: currentKey);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('$providerName Key', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                providerDesc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Paste key here',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                        tooltip: obscure ? 'Show key' : 'Hide key',
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            controller.text = data.text!.trim();
                          }
                        },
                        tooltip: 'Paste from clipboard',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await onSave('');
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('$providerName API key removed.')),
                    );
                  }
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final key = controller.text.trim();
                await onSave(key);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        key.isNotEmpty
                            ? '$providerName key saved to secure storage.'
                            : '$providerName key cleared.',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _maskKey(String key) {
    if (key.isEmpty) return 'Not set';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }
}
