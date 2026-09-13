import 'package:flutter/material.dart';
import 'package:eatwise/core/constants/app_colors.dart';

/// Athletic Viewfinder HUD Overlay with neon corner brackets and target reticle.
/// Matching Figma node 1:2 and Stitch Obsidian specifications.
class ScannerHudOverlay extends StatelessWidget {
  final String scanMode; // 'meal' or 'barcode'
  final bool isAnalyzing;
  final VoidCallback onGalleryTap;

  const ScannerHudOverlay({
    super.key,
    required this.scanMode,
    this.isAnalyzing = false,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── High-Tech Viewfinder Corner Brackets & Grid ──
        CustomPaint(
          size: Size.infinite,
          painter: _ViewfinderPainter(
            color: AppColors.primary,
            isBarcode: scanMode == 'barcode',
          ),
        ),

        // ── Top Telemetry HUD Badge ──
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scanMode == 'barcode' ? 'BARCODE SCANNER' : 'AI FOOD VISION',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Gallery Button
              GestureDetector(
                onTap: onGalleryTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Guidance Pill ──
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                scanMode == 'barcode'
                    ? 'Align product barcode within viewfinder'
                    : 'Center Filipino meal or plate in frame',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  final bool isBarcode;

  _ViewfinderPainter({required this.color, required this.isBarcode});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Viewfinder dimensions
    final boxW = isBarcode ? w * 0.75 : w * 0.82;
    final boxH = isBarcode ? h * 0.50 : h * 0.76;
    final left = (w - boxW) / 2;
    final top = (h - boxH) / 2;
    final right = left + boxW;
    final bottom = top + boxH;

    // Darkened letterbox outside the viewfinder
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTRB(0, 0, w, top), bgPaint);
    canvas.drawRect(Rect.fromLTRB(0, bottom, w, h), bgPaint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), bgPaint);
    canvas.drawRect(Rect.fromLTRB(right, top, w, bottom), bgPaint);

    // Corner brackets
    final cornerLength = isBarcode ? 20.0 : 28.0;
    const strokeWidth = 3.0;

    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCorner(double x, double y, double dx, double dy) {
      final path = Path()
        ..moveTo(x, y + dy * cornerLength)
        ..lineTo(x, y)
        ..lineTo(x + dx * cornerLength, y);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, bracketPaint);
    }

    // Top-Left
    drawCorner(left, top, 1, 1);
    // Top-Right
    drawCorner(right, top, -1, 1);
    // Bottom-Left
    drawCorner(left, bottom, 1, -1);
    // Bottom-Right
    drawCorner(right, bottom, -1, -1);

    // Center Crosshair reticle
    const crossSize = 10.0;
    final cx = w / 2;
    final cy = h / 2;
    final reticlePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx + crossSize, cy), reticlePaint);
    canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy + crossSize), reticlePaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isBarcode != isBarcode;
}
