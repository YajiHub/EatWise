import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/features/dashboard/models/weight_entry.dart';
import 'package:eatwise/features/dashboard/providers/weight_provider.dart';

class WeightEntrySheet extends ConsumerStatefulWidget {
  final String? initialDate;

  const WeightEntrySheet({super.key, this.initialDate});

  @override
  ConsumerState<WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends ConsumerState<WeightEntrySheet> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate != null
        ? DateTime.tryParse(widget.initialDate!) ?? DateTime.now()
        : DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) return;
    final weightKg = double.tryParse(weightText);
    if (weightKg == null || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight')),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    double? heightCm;
    final heightText = _heightController.text.trim();
    if (heightText.isNotEmpty) {
      final h = double.tryParse(heightText);
      if (h != null && h >= 100 && h <= 250) heightCm = h;
    }

    final entry = WeightEntry(
      date: dateStr,
      weightKg: weightKg,
      heightCm: heightCm,
      createdAt: DateTime.now(),
    );

    await insertWeightEntry(ref, entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final heightAsync = ref.watch(heightCmProvider);
    final hasHeight = heightAsync.valueOrNull != null && heightAsync.valueOrNull! > 0;

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
              const Text('Log Weight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _weightController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('kg', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasHeight) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: UnderlineInputBorder(),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('cm', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              const Text('Date: ', style: TextStyle(fontSize: 16, color: Colors.grey)),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }
}
