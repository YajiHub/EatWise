import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

class EditableFoodItemCard extends StatefulWidget {
  final FoodItem item;
  final String verificationStatus;
  final String verificationSource;
  final ValueChanged<FoodItem> onChanged;
  final bool initiallyExpanded;

  const EditableFoodItemCard({
    super.key,
    required this.item,
    this.verificationStatus = 'estimated',
    this.verificationSource = 'ai',
    required this.onChanged,
    this.initiallyExpanded = false,
  });

  @override
  State<EditableFoodItemCard> createState() => _EditableFoodItemCardState();
}

class _EditableFoodItemCardState extends State<EditableFoodItemCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _tagalogCtrl;
  late TextEditingController _portionCtrl;
  late TextEditingController _portionDescCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatsCtrl;
  bool _expanded = false;
  bool _ratioValid = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _initControllers();
  }

  @override
  void didUpdateWidget(EditableFoodItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item && !_expanded) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.item.name);
    _tagalogCtrl = TextEditingController(text: widget.item.nameTagalog);
    _portionCtrl = TextEditingController(text: widget.item.portionSizeGrams > 0 ? widget.item.portionSizeGrams.toStringAsFixed(0) : '');
    _portionDescCtrl = TextEditingController(text: widget.item.portionDescription);
    _calCtrl = TextEditingController(text: widget.item.calories > 0 ? widget.item.calories.toStringAsFixed(0) : '');
    _proteinCtrl = TextEditingController(text: widget.item.proteinG > 0 ? widget.item.proteinG.toStringAsFixed(1) : '');
    _carbsCtrl = TextEditingController(text: widget.item.carbsG > 0 ? widget.item.carbsG.toStringAsFixed(1) : '');
    _fatsCtrl = TextEditingController(text: widget.item.fatsG > 0 ? widget.item.fatsG.toStringAsFixed(1) : '');
    _updateRatioValid();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagalogCtrl.dispose();
    _portionCtrl.dispose();
    _portionDescCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _updateRatioValid() {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final p = double.tryParse(_proteinCtrl.text) ?? 0;
    final c = double.tryParse(_carbsCtrl.text) ?? 0;
    final f = double.tryParse(_fatsCtrl.text) ?? 0;
    if (cal <= 0) {
      _ratioValid = true;
      return;
    }
    final calculated = (p * 4) + (c * 4) + (f * 9);
    final diff = (calculated - cal).abs();
    _ratioValid = diff <= cal * 0.2;
  }

  FoodItem _buildItem() {
    final cal = double.tryParse(_calCtrl.text) ?? widget.item.calories;
    final p = double.tryParse(_proteinCtrl.text) ?? widget.item.proteinG;
    final c = double.tryParse(_carbsCtrl.text) ?? widget.item.carbsG;
    final f = double.tryParse(_fatsCtrl.text) ?? widget.item.fatsG;
    final portion = double.tryParse(_portionCtrl.text) ?? widget.item.portionSizeGrams;

    return widget.item.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? widget.item.name : _nameCtrl.text.trim(),
      nameTagalog: _tagalogCtrl.text.trim(),
      portionSizeGrams: portion,
      portionDescription: _portionDescCtrl.text.trim().isEmpty ? widget.item.portionDescription : _portionDescCtrl.text.trim(),
      calories: cal,
      proteinG: p,
      carbsG: c,
      fatsG: f,
      confidence: 1.0,
      reasoning: '${widget.item.reasoning} [Edited by user]',
    );
  }

  void _notifyParent() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(_buildItem());
    });
  }

  void _onMacroChanged() {
    // Auto-calculate calories from protein (×4), carbs (×4), fats (×9)
    final p = double.tryParse(_proteinCtrl.text) ?? 0;
    final c = double.tryParse(_carbsCtrl.text) ?? 0;
    final f = double.tryParse(_fatsCtrl.text) ?? 0;
    final calFromMacros = (p * 4) + (c * 4) + (f * 9);
    if (calFromMacros > 0) {
      _calCtrl.text = calFromMacros.toStringAsFixed(0);
    }
    _updateRatioValid();
    setState(() {});
    _notifyParent();
  }

  void _onCalChanged() {
    _updateRatioValid();
    setState(() {});
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.verificationStatus == 'verified';
    final isUserEdited = widget.item.confidence >= 1.0 && widget.item.reasoning.contains('[Edited by user]');

    final borderColor = isUserEdited
        ? Colors.blue.shade300
        : isVerified
            ? Colors.green.shade300
            : Colors.orange.shade200;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isUserEdited || isVerified ? 1.5 : 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_expanded) _buildEditForm(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isVerified = widget.verificationStatus == 'verified';
    final isUserEdited = widget.item.confidence >= 1.0 && widget.item.reasoning.contains('[Edited by user]');

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusBadge(isVerified, isUserEdited),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.item.calories.toStringAsFixed(0)} cal',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.edit, size: 20),
                  color: _expanded ? Colors.grey.shade500 : AppColors.primary,
                  tooltip: _expanded ? 'Collapse' : 'Edit values',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            if (widget.item.nameTagalog.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.item.nameTagalog,
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${widget.item.portionDescription} (~${widget.item.portionSizeGrams.toStringAsFixed(0)}g)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (widget.item.reasoning.isNotEmpty && !(widget.item.reasoning.contains('[Edited by user]'))) ...[
              const SizedBox(height: 4),
              Text(
                widget.item.reasoning,
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _macroBadge('P', '${widget.item.proteinG.toStringAsFixed(1)}g', AppColors.protein),
                _macroBadge('C', '${widget.item.carbsG.toStringAsFixed(1)}g', AppColors.carbs),
                _macroBadge('F', '${widget.item.fatsG.toStringAsFixed(1)}g', AppColors.fats),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isVerified, bool isUserEdited) {
    if (isUserEdited) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✏️', style: TextStyle(fontSize: 11)),
            SizedBox(width: 2),
            Text('edited', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: TextStyle(fontSize: 11)),
            SizedBox(width: 2),
            Text('verified', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: const Text('⚠️ estimated', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
    );
  }

  Widget _macroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Food Name', isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => _notifyParent(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _tagalogCtrl,
                  decoration: const InputDecoration(labelText: 'Tagalog', isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => _notifyParent(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _portionCtrl,
                  decoration: const InputDecoration(labelText: 'Portion (g)', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _notifyParent(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _portionDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder(), hintText: 'e.g. 1 piece, 1 cup'),
                  onChanged: (_) => _notifyParent(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _calCtrl,
                  decoration: const InputDecoration(labelText: 'Calories', isDense: true, border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onCalChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _proteinCtrl,
                  decoration: const InputDecoration(labelText: 'Protein (g)', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _onMacroChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _carbsCtrl,
                  decoration: const InputDecoration(labelText: 'Carbs (g)', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _onMacroChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _fatsCtrl,
                  decoration: const InputDecoration(labelText: 'Fats (g)', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _onMacroChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _ratioValid ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 16,
                color: _ratioValid ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                _ratioValid ? 'Macro ratio valid' : 'Macro ratio may be off',
                style: TextStyle(fontSize: 12, color: _ratioValid ? Colors.green : Colors.orange),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _expanded = false),
                icon: const Icon(Icons.done, size: 18),
                label: const Text('Done', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
