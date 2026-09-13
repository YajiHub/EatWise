import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eatwise/core/constants/app_colors.dart';

/// Athletic Dual-Ring Concentric Metric Dial Card (Calorie Budget + Fasting Arc)
/// Matching Figma node 1:375 and Stitch Obsidian specifications.
class AthleticHeroDialCard extends StatelessWidget {
  final double consumed;
  final double target;
  final String fastingLabel;
  final double fastingProgress;
  final VoidCallback onTap;

  const AthleticHeroDialCard({
    super.key,
    required this.consumed,
    required this.target,
    this.fastingLabel = '16:8 Fasting • Active',
    this.fastingProgress = 0.7,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = target - consumed;
    final isOver = remaining < 0;
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Radial Emerald Bloom (Dark Mode Only)
            if (isDark)
              Positioned(
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  // ── Top Header Row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAILY CALORIE TARGET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOver
                              ? Colors.red.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isOver
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          isOver ? 'Over Budget' : 'On Track',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: isOver ? Colors.red : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Concentric Progress Dial ──
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(210, 210),
                          painter: _ConcentricDialPainter(
                            calorieRatio: ratio,
                            fastingRatio: fastingProgress.clamp(0.0, 1.0),
                            isDark: isDark,
                            isOver: isOver,
                          ),
                        ),

                        // Center Readout
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              remaining.abs().toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                height: 1.0,
                                color: isOver
                                    ? Colors.redAccent
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOver ? 'KCAL OVER' : 'KCAL REMAINING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${consumed.toStringAsFixed(0)} eaten of ${target.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Bottom Fasting Capsule ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceCard
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark
                            ? AppColors.surfaceCardBorder
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.fasting,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fastingLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentricDialPainter extends CustomPainter {
  final double calorieRatio;
  final double fastingRatio;
  final bool isDark;
  final bool isOver;

  _ConcentricDialPainter({
    required this.calorieRatio,
    required this.fastingRatio,
    required this.isDark,
    required this.isOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Outer Ring (Calorie Budget) ──
    final outerRadius = size.width / 2 - 12;
    final outerTrackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? const Color(0x14FFFFFF) // 8% white
          : const Color(0xFFE2E8F0);

    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    if (calorieRatio > 0) {
      final sweepAngle = 2 * math.pi * calorieRatio;
      final outerActivePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = isOver ? Colors.redAccent : AppColors.primary;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        outerActivePaint,
      );
    }

    // ── Inner Ring (Fasting Progress) ──
    final innerRadius = outerRadius - 16;
    final innerTrackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? const Color(0x0FFFFFFF) // 6% white
          : const Color(0xFFF1F5F9);

    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    if (fastingRatio > 0) {
      final fastingSweep = 2 * math.pi * fastingRatio;
      final innerActivePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.fasting;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        fastingSweep,
        false,
        innerActivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricDialPainter oldDelegate) {
    return oldDelegate.calorieRatio != calorieRatio ||
        oldDelegate.fastingRatio != fastingRatio ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOver != isOver;
  }
}
