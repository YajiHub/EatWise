import 'package:flutter/material.dart';
import 'package:eatwise/core/constants/app_colors.dart';

class MealTypeSelector extends StatelessWidget {
  final String? selectedMealType;
  final ValueChanged<String> onChanged;

  const MealTypeSelector({
    super.key,
    required this.selectedMealType,
    required this.onChanged,
  });

  static const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  static String mealTypeLabel(String type) {
    return switch (type) {
      'breakfast' => '☀️ Breakfast',
      'lunch'     => '🌤 Lunch',
      'dinner'    => '🌙 Dinner',
      'snack'     => '🍪 Snack',
      _           => '🍪 Snack',
    };
  }

  static IconData mealTypeIcon(String type) {
    return switch (type) {
      'breakfast' => Icons.wb_sunny_outlined,
      'lunch'     => Icons.wb_sunny,
      'dinner'    => Icons.nights_stay_outlined,
      'snack'     => Icons.cookie_outlined,
      _           => Icons.restaurant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedMealType ?? 'snack';
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Type',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _mealTypes.map((type) {
            final isSelected = selected == type;

            // Colors based on selection state — explicit to avoid theme blending issues
            final bgColor = isSelected
                ? AppColors.primary
                : isDark
                    ? cs.surfaceContainerHighest
                    : const Color(0xFFF3F3F3);

            final textColor = isSelected
                ? Colors.white
                : isDark
                    ? cs.onSurface
                    : const Color(0xFF3D3D3D);

            final borderColor = isSelected
                ? AppColors.primary
                : isDark
                    ? cs.outlineVariant
                    : const Color(0xFFD0D0D0);

            return GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  mealTypeLabel(type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                    height: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
