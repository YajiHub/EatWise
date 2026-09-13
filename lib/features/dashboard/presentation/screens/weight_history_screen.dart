import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eatwise/features/dashboard/models/weight_entry.dart';
import 'package:eatwise/features/dashboard/providers/weight_provider.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weight_entry_sheet.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/constants/app_colors.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final entries = entriesAsync.valueOrNull ?? [];
    final heightAsync = ref.watch(heightCmProvider);
    final heightCm = heightAsync.valueOrNull;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : const Color(0xFFF8F9FA),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.canvasDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEIGHT TELEMETRY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'BODY COMPOSITION TRENDS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Log Weight',
            onPressed: () => _addWeight(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: entriesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No weight entries yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _addWeight(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log Your Weight'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    if (entries.length >= 2) _buildChart(entries, heightCm),
                    const SizedBox(height: 8),
                    ...List.generate(entries.length, (i) => _buildEntryCard(context, ref, entries, i, heightCm)),
                  ],
                ),
    );
  }

  Widget _buildChart(List<WeightEntry> entries, double? heightCm) {
    final reversed = entries.reversed.toList();
    final minW = reversed.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxW = reversed.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    final padding = (maxW - minW) * 0.15;
    final chartMinY = (minW - padding).floorToDouble();
    final chartMaxY = (maxW + padding).ceilToDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Weight Trend', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((chartMaxY - chartMinY) / 4).ceilToDouble().clamp(0.5, double.infinity),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: entries.length > 7 ? (entries.length / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= reversed.length) return const SizedBox.shrink();
                          final d = DateTime.tryParse(reversed[i].date);
                          final label = d != null ? DateFormat('M/d').format(d) : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        reversed.length,
                        (i) => FlSpot(i.toDouble(), reversed[i].weightKg),
                      ),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final i = spot.spotIndex;
                        final entry = reversed[i];
                        final d = DateTime.tryParse(entry.date);
                        final label = d != null ? DateFormat('MMM d').format(d) : entry.date;
                        return LineTooltipItem(
                          '$label\n${entry.weightKg.toStringAsFixed(1)} kg',
                          TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, WidgetRef ref, List<WeightEntry> entries, int i, double? heightCm) {
    final entry = entries[i];
    final d = DateTime.tryParse(entry.date);
    final dateLabel = d != null ? DateFormat('MMM d, yyyy').format(d) : entry.date;
    final isLatest = i == 0;

    double? bmi;
    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;
      bmi = entry.weightKg / (heightM * heightM);
    }

    double? delta;
    if (i < entries.length - 1) {
      delta = entry.weightKg - entries[i + 1].weightKg;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editWeight(context, ref, entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLatest ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLatest ? Icons.monitor_weight : Icons.circle_outlined,
                  size: 20,
                  color: isLatest ? AppColors.primary : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${entry.weightKg.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isLatest ? AppColors.primary : null,
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Latest', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(dateLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (bmi != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _bmiColor(bmi).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BMI ${bmi.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _bmiColor(bmi)),
                  ),
                ),
              if (delta != null && delta != 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (delta < 0 ? Colors.green : Colors.red).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${delta < 0 ? '↓' : '↑'} ${delta.abs().toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: delta < 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _addWeight(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WeightEntrySheet(),
    );
  }

  void _editWeight(BuildContext context, WidgetRef ref, WeightEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditWeightSheet(entry: entry),
    );
  }
}

class _EditWeightSheet extends ConsumerStatefulWidget {
  final WeightEntry entry;
  const _EditWeightSheet({required this.entry});

  @override
  ConsumerState<_EditWeightSheet> createState() => _EditWeightSheetState();
}

class _EditWeightSheetState extends ConsumerState<_EditWeightSheet> {
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.entry.weightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Weight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _weightCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(border: UnderlineInputBorder(), contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('kg', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AppDatabase.deleteWeight(widget.entry.id!);
                    ref.invalidate(weightEntriesProvider);
                    ref.invalidate(latestWeightProvider);
                    ref.invalidate(previousWeightProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final val = double.tryParse(_weightCtrl.text);
                    if (val == null || val <= 0) return;
                    await AppDatabase.updateWeight(widget.entry.id!, val);
                    ref.invalidate(weightEntriesProvider);
                    ref.invalidate(latestWeightProvider);
                    ref.invalidate(previousWeightProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
