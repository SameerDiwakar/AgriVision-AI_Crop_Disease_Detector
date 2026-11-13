import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isQuotaError = false;
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
          _isQuotaError = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
        _isNonPlantError = false;
        _isQuotaError = false;
      });
    }
  }

  Future<void> _analyzeLeaf() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNonPlantError = false;
      _isQuotaError = false;
      _loadingMessage = 'Connecting to AgriVision AI...';
    });

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
      final bool isQuota = e is PlantApiServiceException && (e.isQuotaExceeded || e.isApiKeyError);
      setState(() {
        _isLoading = false;
        _isNonPlantError = false;
        _isQuotaError = isQuota;
        _errorMessage = e.toString();
      });
    }
  }

  void _useDemoDiagnosis() async {
    final result = PlantApiService.generateDemoResult(
      imageBase64: _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : null,
    );

    final record = ScanHistoryRecord.fromResult(
      result: result,
      imagePath: _selectedXFile?.path ?? '',
    );
    await HistoryService.saveScan(record);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          result: result,
          imageBytes: _selectedImageBytes,
        ),
      ),
    );
  }

  void _showApiKeyDialog() async {
    final currentKey = await PlantApiService.getActiveApiKey();
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Plant.id API Key Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a free API key at web.plant.id/api (or admin.kindwise.com) and paste it below:',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter Plant.id API key',
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await PlantApiService.setCustomApiKey(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Key updated successfully!'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Configure API Key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Central Image Capture/Preview Area
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _selectedImageBytes != null
                            ? _buildImagePreviewWidget()
                            : _buildPlaceholderWidget(),
              ),

              const SizedBox(height: 20),

              // Bottom Button Bar
              if (!_isLoading) ...[
                if (_selectedImageBytes != null && _errorMessage == null)
                  ElevatedButton.icon(
                    onPressed: _analyzeLeaf,
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Analyze Leaf Disease'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      elevation: 3,
                    ),
                  ),

                if (_selectedImageBytes != null) const SizedBox(height: 12),

                // Dual Selection Option Buttons (Camera / Gallery)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(_selectedImageBytes == null ? 'Camera' : 'Retake'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(_selectedImageBytes == null ? 'Gallery' : 'Choose Other'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentPale,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              size: 56,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload a Leaf Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Capture a close-up photo of the crop leaf displaying visible disease symptoms.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewWidget() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
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
    final bool isQuota = _isQuotaError;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isNonPlant ? AppTheme.warningOrange : AppTheme.diseasedRed)
                    .withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNonPlant
                    ? Icons.no_photography_rounded
                    : (isQuota ? Icons.cloud_off_rounded : Icons.wifi_off_rounded),
                size: 48,
                color: isNonPlant ? AppTheme.warningOrange : AppTheme.diseasedRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNonPlant
                  ? "Doesn't Look Like a Plant"
                  : (isQuota ? 'API Quota Limit Reached' : 'Analysis Failed'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isQuota
                    ? 'The Plant.id API key free credits have been exhausted (70/70 used). You can enter a new API key or proceed with demo diagnosis.'
                    : (_errorMessage ?? 'An unknown error occurred.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (isQuota) ...[
              ElevatedButton.icon(
                onPressed: _showApiKeyDialog,
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Update API Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(220, 46),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _useDemoDiagnosis,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Continue with Demo Diagnosis'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(220, 46),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isNonPlantError = false;
                  _isQuotaError = false;
                });
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Try Another Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
