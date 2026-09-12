import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/core/ai/local_food_db.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/features/food_ai/presentation/providers/gemini_provider.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/editable_food_item_card.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/meal_type_selector.dart';

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
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
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

    // 1. Try OpenFoodFacts product API lookup first
    FoodItem? foodItem = await _lookupOpenFoodFactsBarcode(rawValue);
    String sourceName = 'OpenFoodFacts';

    // 2. Fall back to local food database if OFF doesn't have it
    if (foodItem == null) {
      final match = LocalFoodDatabase().search(rawValue);
      if (match != null) {
        sourceName = match.dataSource;
        foodItem = FoodItem(
          name: match.matchedName,
          nameTagalog: '',
          portionSizeGrams: match.gramsPerServing ?? 100,
          portionDescription: match.servingDescription ?? '1 serving',
          calories: match.calPer100g * ((match.gramsPerServing ?? 100) / 100),
          proteinG: match.proteinPer100g * ((match.gramsPerServing ?? 100) / 100),
          carbsG: match.carbsPer100g * ((match.gramsPerServing ?? 100) / 100),
          fatsG: match.fatPer100g * ((match.gramsPerServing ?? 100) / 100),
          confidence: match.confidence,
          reasoning: 'Barcode lookup: ${match.dataSource}',
        );
      }
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
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final response = await http.get(uri, headers: {
        'User-Agent': 'EatWise/1.0 (contact@eatwise.app)',
      }).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data['status'] != 1) return null;

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
        reasoning: 'Barcode lookup: OpenFoodFacts ($barcode)',
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Food Scanner')),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.cover,
              width: 600,
              height: 300,
              cacheWidth: 600,
              cacheHeight: 300,
            ),
            if (_isAnalyzing)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Analyzing your meal...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('MacroAI is estimating the macros', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              margin: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.photo_library,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(
                _scanMode == 'barcode'
                    ? 'Barcode mode — point at a packaged good'
                    : 'Align your meal within the frame',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'meal',
                    icon: Icon(Icons.restaurant, size: 16),
                    label: Text('Meal')),
                ButtonSegment(
                    value: 'barcode',
                    icon: Icon(Icons.qr_code, size: 16),
                    label: Text('Barcode')),
              ],
              selected: {_scanMode},
              onSelectionChanged: (v) => setState(() => _scanMode = v.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 4),
              ),
              child: const Icon(Icons.camera, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Analyzing your meal...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () { setState(() { _error = null; _capturedImage = null; }); },
              child: const Text('Try Again'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultCards() {
    final items = _currentItems;
    final hasEdits = _editedItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Icon(Icons.analytics_outlined, color: AppColors.secondary, size: 28),
                const SizedBox(height: 8),
                Text(
                  _result!.summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                if (hasEdits) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('✏️ Customized — totals recalculated', style: TextStyle(fontSize: 11, color: Colors.blue)),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Meal Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _totalChip('Calories', '_totalCal.toStringAsFixed(0)', AppColors.primary),
                    _totalChip('Protein', '${_totalP.toStringAsFixed(0)}g', AppColors.protein),
                    _totalChip('Carbs', '${_totalC.toStringAsFixed(0)}g', AppColors.carbs),
                    _totalChip('Fats', '${_totalF.toStringAsFixed(0)}g', AppColors.fats),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            EditableFoodItemCard(
              key: ValueKey('scan_item_$i'),
              item: items[i],
              verificationStatus: _validatedItems != null && i < _validatedItems!.length
                  ? (_validatedItems![i].status == VerificationStatus.verified ? 'verified' : 'estimated')
                  : 'estimated',
              verificationSource: _validatedItems != null && i < _validatedItems!.length
                  ? _validatedItems![i].source
                  : 'ai',
              onChanged: (edited) => _onItemChanged(i, edited),
            ),
          ],
          const SizedBox(height: 14),
          MealTypeSelector(
            selectedMealType: _selectedMealType,
            onChanged: (type) => setState(() => _selectedMealType = type),
          ),
          const SizedBox(height: 16),
          if (_saved)
            OutlinedButton.icon(
              onPressed: _discardResult,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Another Meal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _discardResult,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Discard', style: TextStyle(color: Colors.red)),
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
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _approveResult,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Approve & Log'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _totalChip(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}
