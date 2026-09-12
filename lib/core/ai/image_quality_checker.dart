import 'dart:typed_data';

/// Validates image quality before sending to vision AI
/// Prevents processing of unsuitable images that would waste API calls
class ImageQualityChecker {
  /// Recommended sizes for good quality
  static const int minWidth = 100;
  static const int maxWidth = 4000;
  static const int minHeight = 100;
  static const int maxHeight = 4000;
  
  /// File size limits (in bytes)
  static const int minFileSize = 5000; // 5KB
  static const int maxFileSize = 20971520; // 20MB
  
  /// JPEG quality detection thresholds
  static const int minBrightnessVariation = 20; // Avoid completely solid colors
  
  ImageQualityResult checkImageBytes(Uint8List imageBytes) {
    final issues = <String>[];
    var quality = 0.0;

    // 1. File size check
    if (imageBytes.isEmpty) {
      issues.add('Image file is empty');
      return ImageQualityResult(isValid: false, issues: issues, quality: 0);
    }

    if (imageBytes.length < minFileSize) {
      issues.add('Image file is too small (${(imageBytes.length / 1024).toStringAsFixed(1)}KB, min 5KB)');
    } else if (imageBytes.length > maxFileSize) {
      issues.add('Image file is too large (${(imageBytes.length / 1048576).toStringAsFixed(1)}MB, max 20MB)');
      return ImageQualityResult(isValid: false, issues: issues, quality: 0);
    }

    // 2. Basic JPEG/PNG format check
    if (!_isValidImageFormat(imageBytes)) {
      issues.add('Image format not supported (JPEG or PNG required)');
      return ImageQualityResult(isValid: false, issues: issues, quality: 0);
    }

    // 3. Brightness and contrast analysis
    final brightnessAnalysis = _analyzeBrightness(imageBytes);
    quality += brightnessAnalysis.quality * 0.3;

    if (brightnessAnalysis.isTooDark) {
      issues.add('Image is too dark - may be hard to analyze');
    }
    if (brightnessAnalysis.isTooLight) {
      issues.add('Image is too bright/washed out - may lack detail');
    }
    if (brightnessAnalysis.lowVariance) {
      issues.add('Image lacks contrast - texture may be unclear');
    }

    // 4. Edge detection for focus quality
    final edgeQuality = _estimateFocusQuality(imageBytes);
    quality += edgeQuality * 0.3;
    
    if (edgeQuality < 0.4) {
      issues.add('Image appears blurry or out of focus');
    }

    // 5. Size reasonableness
    quality += 0.4; // Base score for passing earlier checks

    // Determine validity based on issue count
    final isValid = issues.length <= 1 && quality >= 0.4;

    return ImageQualityResult(
      isValid: isValid,
      issues: issues,
      quality: quality.clamp(0.0, 1.0),
      recommendation: _getRecommendation(issues, quality, edgeQuality),
    );
  }

  bool _isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // Check JPEG magic number (FF D8)
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;

    // Check PNG magic number (89 50 4E 47)
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    return false;
  }

  _BrightnessAnalysis _analyzeBrightness(Uint8List bytes) {
    int pixelCount = 0;
    int totalBrightness = 0;
    int brightnessMin = 255;
    int brightnessMax = 0;

    // Sample every 10th byte to estimate brightness
    // This is a rough approximation for image quality
    for (var i = 0; i < bytes.length && pixelCount < 1000; i += 10) {
      final byte = bytes[i];
      totalBrightness += byte;
      brightnessMin = (byte < brightnessMin) ? byte : brightnessMin;
      brightnessMax = (byte > brightnessMax) ? byte : brightnessMax;
      pixelCount++;
    }

    if (pixelCount == 0) {
      return _BrightnessAnalysis(quality: 0, isTooDark: true, isTooLight: false, lowVariance: true);
    }

    final avgBrightness = totalBrightness ~/ pixelCount;
    final variance = brightnessMax - brightnessMin;

    bool isTooDark = avgBrightness < 50;
    bool isTooLight = avgBrightness > 220;
    bool lowVariance = variance < minBrightnessVariation;

    double quality = 1.0;
    if (isTooDark || isTooLight) quality -= 0.4;
    if (lowVariance) quality -= 0.3;

    return _BrightnessAnalysis(
      quality: quality.clamp(0.0, 1.0),
      isTooDark: isTooDark,
      isTooLight: isTooLight,
      lowVariance: lowVariance,
    );
  }

  /// Rough estimation of focus quality by looking at byte transitions
  /// More edge transitions = better focus
  double _estimateFocusQuality(Uint8List bytes) {
    if (bytes.length < 100) return 0.3;

    int edgeCount = 0;
    int sampleSize = (bytes.length / 100).toInt().clamp(10, 500);

    for (var i = 1; i < bytes.length && edgeCount < 100; i += sampleSize) {
      final diff = (bytes[i] - bytes[i - 1]).abs();
      if (diff > 30) {
        // Significant change indicates edges/detail
        edgeCount++;
      }
    }

    // Normalize: 0-100 edge changes out of samples = 0-1.0 quality
    return (edgeCount / 50).clamp(0.0, 1.0);
  }

  String _getRecommendation(List<String> issues, double quality, double focusQuality) {
    if (issues.isEmpty) {
      return 'Image quality is good. Processing...';
    }

    if (issues.any((i) => i.contains('too large'))) {
      return 'Image is too large - consider compressing or taking a clearer photo';
    }

    if (focusQuality < 0.3 || issues.any((i) => i.contains('blurry'))) {
      return 'Image is blurry - try taking a clearer, well-lit photo';
    }

    if (issues.any((i) => i.contains('too dark'))) {
      return 'Image is too dark - improve lighting and try again';
    }

    if (issues.any((i) => i.contains('too bright'))) {
      return 'Image is too bright - avoid glare and try again';
    }

    if (issues.any((i) => i.contains('contrast'))) {
      return 'Image lacks detail - ensure good lighting on the food';
    }

    return 'Image quality is acceptable but could be improved';
  }
}

class _BrightnessAnalysis {
  final double quality;
  final bool isTooDark;
  final bool isTooLight;
  final bool lowVariance;

  _BrightnessAnalysis({
    required this.quality,
    required this.isTooDark,
    required this.isTooLight,
    required this.lowVariance,
  });
}

class ImageQualityResult {
  final bool isValid;
  final List<String> issues;
  final double quality;
  final String? recommendation;

  const ImageQualityResult({
    required this.isValid,
    required this.issues,
    required this.quality,
    this.recommendation,
  });

  /// Can be processed but with warnings
  bool get canProceedWithWarnings => !isValid && quality >= 0.3;

  /// Should probably not be processed
  bool get shouldReject => !isValid && quality < 0.3;
}
