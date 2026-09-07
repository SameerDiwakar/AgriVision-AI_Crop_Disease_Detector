import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_disease_model.dart';
import '../models/scan_history_record.dart';
import '../services/plant_api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  XFile? _selectedXFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  String _loadingMessage = 'Preparing leaf image...';
  String? _errorMessage;
  bool _isNonPlantError = false;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedXFile = pickedFile;
          _selectedImageBytes = bytes;
          _errorMessage = null;
          _isNonPlantError = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
        _isNonPlantError = false;
      });
    }
  }

  Future<void> _analyzeLeaf() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNonPlantError = false;
      _loadingMessage = 'Connecting to AgriVision AI...';
    });

    // Simulate animated loading messages
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = 'Scanning leaf veins & lesion spots...');
      }
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = 'Comparing against 10,000+ plant diseases...');
      }
    });

    try {
      final PlantDiseaseResult result =
          await PlantApiService.identifyLeafDisease(_selectedImageBytes!);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!result.isPlant) {
        setState(() {
          _isNonPlantError = true;
          _errorMessage =
              "This doesn't look like a plant leaf. Please take another photo focusing clearly on a leaf sample.";
        });
        return;
      }

      // Automatically save diagnosis record to local history
      final record = ScanHistoryRecord.fromResult(
        result: result,
        imagePath: _selectedXFile?.path ?? '',
      );
      await HistoryService.saveScan(record);

      if (!mounted) return;

      // Navigate to Results Screen with Hero transition
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            result: result,
            imageBytes: _selectedImageBytes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isNonPlantError = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaf Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Main Interactive Area
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _buildImagePreviewWidget(),
              ),

              const SizedBox(height: 16),

              // Bottom Action Buttons
              if (!_isLoading) ...[
                if (_selectedImageBytes == null) ...[
                  // Primary Action Buttons for initial pick
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Action buttons when image is chosen
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _analyzeLeaf,
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Analyze Leaf Disease'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose Other'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewWidget() {
    if (_selectedImageBytes == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor, width: 2),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.accentPale,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 54,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Leaf Selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Take a photo of an infected crop leaf or choose an existing photo from gallery.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'leafImageHero',
              child: Image.memory(
                _selectedImageBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Frame overlay guide
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accent.withAlpha(200),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            // Top overlay hint badge
            Positioned(
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(165),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ready to analyze',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.accentPale,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(38),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Leaf...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _loadingMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.accentPale,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final bool isNonPlant = _isNonPlantError;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNonPlant ? AppTheme.warningOrange : AppTheme.diseasedRed,
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isNonPlant ? AppTheme.warningOrange : AppTheme.diseasedRed)
                  .withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNonPlant ? Icons.no_photography_rounded : Icons.wifi_off_rounded,
              size: 52,
              color: isNonPlant ? AppTheme.warningOrange : AppTheme.diseasedRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isNonPlant ? "Doesn't Look Like a Plant" : 'Analysis Failed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isNonPlantError = false;
              });
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Try Another Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(200, 50),
            ),
          ),
        ],
      ),
    );
  }
}
