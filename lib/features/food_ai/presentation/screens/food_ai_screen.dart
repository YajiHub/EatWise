import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/database/philippine_barcode_db.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/features/food_ai/presentation/providers/gemini_provider.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/meal_type_selector.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/scanner_hud_overlay.dart';

class FoodAIScreen extends ConsumerStatefulWidget {
  const FoodAIScreen({super.key});

  @override
  ConsumerState<FoodAIScreen> createState() => _FoodAIScreenState();
}

class _FoodAIScreenState extends ConsumerState<FoodAIScreen> {
  final _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  MealAnalysis? _result;
  List<ValidatedFoodItem>? _validatedItems;
  String? _error;
  bool _saved = false;
  Map<int, FoodItem> _editedItems = {};
  String _selectedMealType = 'unknown';
  String _scanMode = 'meal';
  
  // Barcode scanning
  MobileScannerController? _barcodeController;
  bool _isBarcodeScanning = false;
  bool _barcodeDetected = false; // prevent duplicate detections

  List<FoodItem> get _currentItems {
    if (_validatedItems == null) return _result?.foods ?? [];
    return List.generate(_validatedItems!.length, (i) {
      return _editedItems[i] ?? _validatedItems![i].item;
    });
  }

  double get _totalCal => _currentItems.fold(0.0, (s, f) => s + f.calories);
  double get _totalP => _currentItems.fold(0.0, (s, f) => s + f.proteinG);
  double get _totalC => _currentItems.fold(0.0, (s, f) => s + f.carbsG);
  double get _totalF => _currentItems.fold(0.0, (s, f) => s + f.fatsG);

  @override
  void dispose() {
    _barcodeController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_scanMode == 'barcode') {
      _startBarcodeScan();
      return;
    }
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (photo == null) return;

      setState(() {
        _capturedImage = photo;
        _result = null;
        _validatedItems = null;
        _error = null;
        _editedItems = {};
        _isAnalyzing = true;
      });

      final bytes = await photo.readAsBytes();
      final service = ref.read(foodLogServiceProvider);

      try {
        final result = await service.analyzeImage(bytes);
        if (!mounted) return;
        setState(() {
          _result = result.mealAnalysis;
          _validatedItems = result.items;
          _selectedMealType = result.mealAnalysis.mealType;
          _isAnalyzing = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() { _error = e.toString(); _isAnalyzing = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Camera error: $e');
    }
  }

  void _startBarcodeScan() {
    if (_isBarcodeScanning) return;

    // Clean up any previous controller
    _barcodeController?.dispose();
    _barcodeController = null;

    _barcodeDetected = false; // reset detection guard

    setState(() {
      _isBarcodeScanning = true;
      _barcodeController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBarcodeScannerSheet(),
    ).whenComplete(() {
      _barcodeController?.dispose();
      _barcodeController = null;
      if (mounted) setState(() => _isBarcodeScanning = false);
    });
  }

  Widget _buildBarcodeScannerSheet() {
    final size = MediaQuery.of(context).size;
    final usableHeight = size.height * 0.7; // safer than 0.75

    return Container(
      height: usableHeight,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            if (_barcodeController != null)
              MobileScanner(
                controller: _barcodeController!,
                onDetect: _onBarcodeDetected,
                errorBuilder: (ctx, err) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      const Text('Camera error', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go back', style: TextStyle(color: Colors.white)),
                      ),
                    ]),
                  );
                },
              )
            else
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),

            // Scan frame overlay
            Center(
              child: Container(
                width: 250,
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Align barcode within frame',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Torch button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: _barcodeController != null
                    ? IconButton.filled(
                        onPressed: () => _barcodeController?.toggleTorch(),
                        icon: const Icon(Icons.flash_on),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Prevent duplicate detection calls
    if (_barcodeDetected) return;
    _barcodeDetected = true;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _barcodeDetected = false; // allow retry
      return;
    }

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue?.trim() ?? '';
    // Valid retail barcodes (EAN-8, UPC, EAN-13) are at least 7 characters. Ignore camera artifacts.
    if (rawValue.length < 7) {
      _barcodeDetected = false;
      return;
    }

    await _barcodeController?.stop();
    _barcodeController = null;
    if (!mounted) return;

    // Pop the scanner sheet
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    // 1. Check curated Philippine barcode database first (instant offline match)
    FoodItem? foodItem = PhilippineBarcodeDatabase.lookup(rawValue);
    String sourceName = 'Local Barcode DB';

    // 2. If not in local barcode DB, query live OpenFoodFacts API v3
    if (foodItem == null) {
      foodItem = await _lookupOpenFoodFactsBarcode(rawValue);
      sourceName = 'OpenFoodFacts v3';
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (foodItem != null) {
      final mealAnalysis = MealAnalysis(
        foods: [foodItem],
        totalCalories: foodItem.calories,
        totalProtein: foodItem.proteinG,
        totalCarbs: foodItem.carbsG,
        totalFats: foodItem.fatsG,
        summary: 'Scanned: ${foodItem.name}',
        mealType: _selectedMealType,
      );

      setState(() {
        _result = mealAnalysis;
        _validatedItems = [
          ValidatedFoodItem(
            item: foodItem!,
            status: VerificationStatus.verified,
            source: sourceName,
          )
        ];
        _error = null;
        _editedItems = {};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${foodItem.name} ($sourceName)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode: $rawValue — not found in OpenFoodFacts or local DB'),
            duration: const Duration(seconds: 3),
          ),
        );
        _showBarcodeNotFoundDialog(rawValue);
      }
    }
  }

  Future<FoodItem?> _lookupOpenFoodFactsBarcode(String barcode) async {
    try {
      // OpenFoodFacts API v3 endpoint with field filtering for minimal network payload
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v3/product/$barcode.json'
        '?fields=product_name,product_name_en,generic_name,nutriments,serving_size,serving_quantity',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'EatWise/1.0 (contact@eatwise.app)',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // v3 uses 'status': 'success' and 'result.id': 'product_found' (v2 used 'status': 1)
      final status = data['status'];
      final resultId = data['result'] is Map ? data['result']['id'] : null;
      final isFound = status == 'success' || status == 1 || resultId == 'product_found';
      if (!isFound) return null;

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = (product['product_name'] as String?)?.trim().isNotEmpty == true
          ? (product['product_name'] as String).trim()
          : (product['product_name_en'] as String?)?.trim().isNotEmpty == true
              ? (product['product_name_en'] as String).trim()
              : (product['generic_name'] as String?)?.trim().isNotEmpty == true
                  ? (product['generic_name'] as String).trim()
                  : 'Product ($barcode)';

      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
      final cal100g = (nutriments['energy-kcal_100g'] as num?)?.toDouble() ??
          (nutriments['energy-kcal'] as num?)?.toDouble() ??
          0.0;
      final p100g = (nutriments['proteins_100g'] as num?)?.toDouble() ??
          (nutriments['proteins'] as num?)?.toDouble() ??
          0.0;
      final c100g = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
          (nutriments['carbohydrates'] as num?)?.toDouble() ??
          0.0;
      final f100g = (nutriments['fat_100g'] as num?)?.toDouble() ??
          (nutriments['fat'] as num?)?.toDouble() ??
          0.0;

      final servingG = (product['serving_quantity'] as num?)?.toDouble() ?? 100.0;
      final servingDesc = (product['serving_size'] as String?) ??
          '1 serving (${(servingG > 0 ? servingG : 100.0).toStringAsFixed(0)}g)';
      final scale = (servingG > 0 ? servingG : 100.0) / 100.0;

      final calServing = (nutriments['energy-kcal_serving'] as num?)?.toDouble() ?? (cal100g * scale);
      final pServing = (nutriments['proteins_serving'] as num?)?.toDouble() ?? (p100g * scale);
      final cServing = (nutriments['carbohydrates_serving'] as num?)?.toDouble() ?? (c100g * scale);
      final fServing = (nutriments['fat_serving'] as num?)?.toDouble() ?? (f100g * scale);

      return FoodItem(
        name: name,
        nameTagalog: '',
        portionSizeGrams: servingG > 0 ? servingG : 100.0,
        portionDescription: servingDesc,
        calories: calServing.roundToDouble(),
        proteinG: double.parse(pServing.toStringAsFixed(1)),
        carbsG: double.parse(cServing.toStringAsFixed(1)),
        fatsG: double.parse(fServing.toStringAsFixed(1)),
        confidence: 0.95,
        reasoning: 'Barcode lookup: OpenFoodFacts v3 ($barcode)',
      );
    } catch (e) {
      debugPrint('[BarcodeLookup] OpenFoodFacts error: $e');
      return null;
    }
  }

  void _showBarcodeNotFoundDialog(String barcode) {
    final outerContext = context; // capture state's context before dialog
    showDialog(
      context: outerContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('Barcode $barcode not in local database.\n\nOptions:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Food Instead'),
            onPressed: () {
              Navigator.pop(ctx);
              _scanMode = 'meal';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _takePhoto();
              });
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Manual Entry'),
            onPressed: () {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                outerContext.push('/manual-log');
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (photo == null) return;

      setState(() {
        _capturedImage = photo;
        _result = null;
        _validatedItems = null;
        _error = null;
        _editedItems = {};
        _isAnalyzing = true;
      });

      final bytes = await photo.readAsBytes();
      final service = ref.read(foodLogServiceProvider);

      try {
        final result = await service.analyzeImage(bytes);
        if (!mounted) return;
        setState(() {
          _result = result.mealAnalysis;
          _validatedItems = result.items;
          _selectedMealType = result.mealAnalysis.mealType;
          _isAnalyzing = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() { _error = e.toString(); _isAnalyzing = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gallery error: $e');
    }
  }

  void _onItemChanged(int index, FoodItem edited) {
    setState(() {
      _editedItems[index] = edited;
    });
  }

  void _onItemDeleted(int index) {
    setState(() {
      final current = List<FoodItem>.from(_currentItems);
      if (index < current.length) {
        current.removeAt(index);
        _result = _result?.copyWith(foods: current);
        final newEdits = <int, FoodItem>{};
        for (int i = 0; i < current.length; i++) {
          newEdits[i] = current[i];
        }
        _editedItems = newEdits;
      }
    });
  }

  void _showItemEditSheet(int index, FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodItemEditSheet(
        item: item,
        onSaved: (edited) => _onItemChanged(index, edited),
        onDeleted: () => _onItemDeleted(index),
      ),
    );
  }

  Future<void> _approveResult() async {
    final items = _currentItems;
    if (items.isEmpty || _isSaving) return;

    final meal = MealAnalysis(
      foods: items,
      totalCalories: _totalCal,
      totalProtein: _totalP,
      totalCarbs: _totalC,
      totalFats: _totalF,
      summary: _result?.summary ?? '',
      mealType: _selectedMealType,
    );

    setState(() => _isSaving = true);
    try {
      await _saveToDb(meal);
      if (!mounted) return;
      setState(() { _saved = true; _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Logged: ${meal.totalCalories.toStringAsFixed(0)} cal — $_selectedMealType'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Save failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _discardResult() {
    setState(() {
      _capturedImage = null;
      _result = null;
      _validatedItems = null;
      _error = null;
      _saved = false;
      _editedItems = {};
      _selectedMealType = 'unknown';
    });
  }

  Future<void> _saveToDb(MealAnalysis meal) async {
    await AppDatabase.insertFoodLog(
      logDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      mealType: meal.mealType,
      source: 'photo',
      meal: meal,
    );
    ref.read(logVersionProvider.notifier).update((v) => v + 1);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI VISION SCANNER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'VERIFIED FOOD DATABASE',
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
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Manual Entry',
            onPressed: () => context.push('/manual-log'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 16 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 300, child: _buildPreviewArea()),
            const SizedBox(height: 16),
            if (!_isAnalyzing && _result == null && _error == null) _buildActionButtons(),
            if (_isAnalyzing) _buildLoadingIndicator(),
            if (_error != null) _buildErrorCard(),
            if (_result != null) _buildResultCards(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_capturedImage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(_capturedImage!.path),
                fit: BoxFit.cover,
                width: 600,
                height: 320,
                cacheWidth: 600,
                cacheHeight: 320,
              ),
              // Corner bracket decoration overlay
              CustomPaint(
                painter: _ViewfinderBorderPainter(color: AppColors.primary),
              ),
              if (_isAnalyzing)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ANALYZING FILIPINO MEAL...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Analyzing macros & ingredients',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF080C14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceCardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: ScannerHudOverlay(
          scanMode: _scanMode,
          isAnalyzing: _isAnalyzing,
          onGalleryTap: _pickFromGallery,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mode Pill Switch
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                _buildModeTab('meal', 'Meal Vision', Icons.restaurant_rounded),
                _buildModeTab('barcode', 'Barcode', Icons.qr_code_scanner_rounded),
              ],
            ),
          ),

          // Shutter Trigger Button with Emerald Bloom
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 2),
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          // Gallery Pick Button
          IconButton.filledTonal(
            onPressed: _pickFromGallery,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.grey.shade200,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 22),
            tooltip: 'Choose from Gallery',
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon) {
    final isSelected = _scanMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _scanMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceContainerHigh : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Analyzing meal components...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _capturedImage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCards() {
    final items = _currentItems;
    final hasEdits = _editedItems.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detected Meal Hero Summary Card ──
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'AI MEAL DETECTION',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        '98% MATCH • VERIFIED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _result!.summary,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (hasEdits) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.protein.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✏️ Customized portions — totals recalculated',
                      style: TextStyle(fontSize: 10.5, color: AppColors.protein, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Macro Telemetry Row (Calorie, Protein, Carbs, Fats) ──
          // Zero overflow guaranteed via 4 Expanded columns with FittedBox
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                _buildMacroTelemetryColumn(
                  label: 'CALORIES',
                  value: _totalCal.toStringAsFixed(0),
                  unit: 'kcal',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                _buildMacroDivider(isDark),
                _buildMacroTelemetryColumn(
                  label: 'PROTEIN',
                  value: '${_totalP.toStringAsFixed(0)}g',
                  unit: 'g',
                  color: AppColors.protein,
                  isDark: isDark,
                ),
                _buildMacroDivider(isDark),
                _buildMacroTelemetryColumn(
                  label: 'CARBS',
                  value: '${_totalC.toStringAsFixed(0)}g',
                  unit: 'g',
                  color: AppColors.carbs,
                  isDark: isDark,
                ),
                _buildMacroDivider(isDark),
                _buildMacroTelemetryColumn(
                  label: 'FATS',
                  value: '${_totalF.toStringAsFixed(0)}g',
                  unit: 'g',
                  color: AppColors.fats,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Itemized Components Breakdown (Compact Rows) ──
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DETECTED INGREDIENTS (TAP TO EDIT)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textMutedDark : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...List.generate(items.length, (i) {
              final item = items[i];
              final isVerified = _validatedItems != null &&
                  i < _validatedItems!.length &&
                  _validatedItems![i].status == VerificationStatus.verified;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showItemEditSheet(i, item),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isVerified ? AppColors.primary : AppColors.protein,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'P ${item.proteinG.toStringAsFixed(0)}g • C ${item.carbsG.toStringAsFixed(0)}g • F ${item.fatsG.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2430) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${item.portionSizeGrams.toStringAsFixed(0)}g',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.calories.toStringAsFixed(0)} cal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 6),

          // ── Meal Type Selector ──
          MealTypeSelector(
            selectedMealType: _selectedMealType,
            onChanged: (type) => setState(() => _selectedMealType = type),
          ),

          const SizedBox(height: 16),

          // ── Action Buttons ──
          if (_saved)
            OutlinedButton.icon(
              onPressed: _discardResult,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Another Meal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _discardResult,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Discard',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _approveResult,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF00C853)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'LOG TO DAILY FUEL',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMacroTelemetryColumn({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDivider(bool isDark) {
    return Container(
      height: 28,
      width: 1,
      color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade300,
    );
  }
}

class _ViewfinderBorderPainter extends CustomPainter {
  final Color color;
  _ViewfinderBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.5;
    const cornerLength = 22.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    const pad = 12.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad + cornerLength), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + cornerLength, pad), paint);
    // Top-Right
    canvas.drawLine(Offset(w - pad - cornerLength, pad), Offset(w - pad, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + cornerLength), paint);
    // Bottom-Left
    canvas.drawLine(Offset(pad, h - pad - cornerLength), Offset(pad, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad + cornerLength, h - pad), paint);
    // Bottom-Right
    canvas.drawLine(Offset(w - pad - cornerLength, h - pad), Offset(w - pad, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Modal Bottom Sheet for Editing Item Grams & Macros ──
class _FoodItemEditSheet extends StatefulWidget {
  final FoodItem item;
  final ValueChanged<FoodItem> onSaved;
  final VoidCallback? onDeleted;

  const _FoodItemEditSheet({
    required this.item,
    required this.onSaved,
    this.onDeleted,
  });

  @override
  State<_FoodItemEditSheet> createState() => _FoodItemEditSheetState();
}

class _FoodItemEditSheetState extends State<_FoodItemEditSheet> {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(20, bottomInset + 16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.onDeleted != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Remove Item',
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDeleted!();
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'PORTION ADJUSTMENT',
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
                IconButton.filledTonal(
                  onPressed: () => _adjustGrams(-25),
                  icon: const Icon(Icons.remove_rounded),
                  tooltip: '-25g',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _portionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      suffixText: 'g',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final g = double.tryParse(val);
                      if (g != null && g > 0) _onGramsChanged(g);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _adjustGrams(25),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '+25g',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [50.0, 100.0, 150.0, 200.0, 250.0].map((preset) {
                return ActionChip(
                  label: Text('${preset.toInt()}g'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _onGramsChanged(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'CALCULATED MACROS',
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
                Expanded(
                  child: TextField(
                    controller: _calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _proteinCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fats (g)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Portion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

