import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eatwise/core/constants/app_colors.dart';

/// Athletic Dual-Ring Concentric Metric Dial Card (Calorie Budget + Fasting Arc)
/// Matching Figma node 1:375 and Stitch Obsidian specifications.
class AthleticHeroDialCard extends StatelessWidget {
  final double consumed;
  final double target;
  final String fastingLabel;
  final bool showFasting;
  final VoidCallback onTap;
  final VoidCallback? onFastingTap;

  const AthleticHeroDialCard({
    super.key,
    required this.consumed,
    required this.target,
    this.fastingLabel = '16:8 Fasting • Active',
    this.showFasting = true,
    required this.onTap,
    this.onFastingTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = target - consumed;
    final isOver = remaining < 0;
    // Ring represents remaining calorie budget (1.0 = 100% full when 0 eaten)
    final remainingRatio = target > 0
        ? (isOver ? 1.0 : (remaining / target).clamp(0.0, 1.0))
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                // ── Calorie Target Tap Area (Header + Dial) ──
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Column(
                    children: [
                      // ── Top Header Row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_outlined,
                                size: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade500,
                              ),
                            ],
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

                      // ── Progress Dial ──
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(210, 210),
                              painter: _AthleticDialPainter(
                                remainingRatio: remainingRatio,
                                isDark: isDark,
                                isOver: isOver,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  remaining.abs().toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                    color: isOver
                                        ? Colors.red
                                        : (isDark
                                            ? Colors.white
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
                    ],
                  ),
                ),

                // ── Bottom Fasting Capsule (Separate Click Target) ──
                if (showFasting) ...[
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onFastingTap,
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AthleticDialPainter extends CustomPainter {
  final double remainingRatio;
  final bool isDark;
  final bool isOver;

  _AthleticDialPainter({
    required this.remainingRatio,
    required this.isDark,
    required this.isOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? const Color(0x18FFFFFF) // 9% white track
          : const Color(0xFFE2E8F0);

    canvas.drawCircle(center, radius, trackPaint);

    // Active Remaining Budget Arc
    if (remainingRatio > 0) {
      final activeColor = isOver ? Colors.redAccent : AppColors.primary;
      final sweepAngle = 2 * math.pi * remainingRatio;

      // Glow effect (Dark mode)
      if (isDark) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..color = activeColor.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = activeColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AthleticDialPainter oldDelegate) {
    return oldDelegate.remainingRatio != remainingRatio ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOver != isOver;
  }
}
