import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prevention_model.dart';
import '../services/prevention_ann_service.dart';
import '../services/prevention_history_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'prevention_history_screen.dart';
import 'prevention_result_screen.dart';

class PreventionHomeScreen extends StatefulWidget {
  const PreventionHomeScreen({super.key});

  @override
  State<PreventionHomeScreen> createState() => _PreventionHomeScreenState();
}

class _PreventionHomeScreenState extends State<PreventionHomeScreen> {
  String _selectedCrop = 'Wheat';
  final TextEditingController _customCropController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: 'Karnal, Haryana');

  double _temperature = 21.0; // °C
  double _relativeHumidity = 88.0; // %
  double _leafWetnessHours = 9.5; // Hours
  double _rainfall = 12.0; // mm

  bool _isFetchingLiveWeather = false;
  List<PreventionHistoryRecord> _recentRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecentRecords();
  }

  @override
  void dispose() {
    _customCropController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentRecords() async {
    final list = await PreventionHistoryService.getRecords();
    if (mounted) {
      setState(() {
        _recentRecords = list.take(3).toList();
      });
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _selectedCrop = preset['crop'] as String;
      _locationController.text = preset['location'] as String;
      _temperature = (preset['temp'] as num).toDouble();
      _relativeHumidity = (preset['humidity'] as num).toDouble();
      _leafWetnessHours = (preset['wetness'] as num).toDouble();
      _rainfall = (preset['rainfall'] as num).toDouble();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded ${preset['label']} preset'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Future<void> _fetchLiveWeather() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name first.')),
      );
      return;
    }

    setState(() {
      _isFetchingLiveWeather = true;
    });

    final WeatherInputData liveData =
        await PreventionAnnService.fetchLiveWeatherData(
      locationQuery: location,
      cropName: _selectedCrop == 'Other / Custom'
          ? _customCropController.text
          : _selectedCrop,
    );

    if (mounted) {
      setState(() {
        _isFetchingLiveWeather = false;
        _temperature = liveData.temperature;
        _relativeHumidity = liveData.relativeHumidity;
        _leafWetnessHours = liveData.leafWetnessHours;
        _rainfall = liveData.rainfall;
        _locationController.text = liveData.location;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Fetched weather for ${liveData.location}: ${_temperature.toStringAsFixed(1)}°C, ${_relativeHumidity.toStringAsFixed(0)}% RH'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  void _runRiskPrediction() {
    final cropName = _selectedCrop == 'Other / Custom'
        ? (_customCropController.text.trim().isNotEmpty
            ? _customCropController.text.trim()
            : 'Custom Crop')
        : _selectedCrop;

    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Field Location';

    final inputData = WeatherInputData.fromRaw(
      cropName: cropName,
      location: location,
      temperature: _temperature,
      relativeHumidity: _relativeHumidity,
      leafWetnessHours: _leafWetnessHours,
      rainfall: _rainfall,
    );

    final AnnRiskPrediction prediction =
        PreventionAnnService.predictDiseaseRisk(inputData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreventionResultScreen(
          inputData: inputData,
          prediction: prediction,
        ),
      ),
    ).then((_) => _loadRecentRecords());
  }

  void _switchToDetectionBranch() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreventionHistoryScreen()),
    ).then((_) => _loadRecentRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Disease Prevention'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _openHistory,
            tooltip: 'Assessment History',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: _switchToDetectionBranch,
            tooltip: 'Go to Leaf Scanner',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro headline
              Text(
                'Pre-Symptom Risk Assessment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter field weather conditions to estimate disease outbreak probability.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              // Quick Preset Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: PreventionAnnService.presetFieldStations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset =
                        PreventionAnnService.presetFieldStations[index];
                    return ActionChip(
                      label: Text(
                        preset['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () => _applyPreset(preset),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Card 1: Crop & Location
              _buildCleanCard(
                title: 'Crop & Location',
                icon: Icons.grass_rounded,
                children: [
                  Text(
                    'Plant / Crop',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.primary),
                        items: [
                          ...PreventionAnnService.commonCrops,
                          'Other / Custom'
                        ].map((crop) {
                          return DropdownMenuItem<String>(
                            value: crop,
                            child: Text(
                              crop,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCrop = val);
                        },
                      ),
                    ),
                  ),

                  if (_selectedCrop == 'Other / Custom') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customCropController,
                      decoration: InputDecoration(
                        hintText: 'Enter crop name (e.g. Barley, Mustard)',
                        filled: true,
                        fillColor: AppTheme.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Text(
                    'Field Location',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Karnal, Haryana',
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                size: 18, color: AppTheme.primary),
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _isFetchingLiveWeather ? null : _fetchLiveWeather,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          elevation: 0,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isFetchingLiveWeather
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_outlined, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card 2: Weather Parameters (Minimal, no math formulas, no clutter)
              _buildCleanCard(
                title: 'Weather Conditions',
                icon: Icons.wb_sunny_outlined,
                children: [
                  _buildCleanSlider(
                    label: 'Temperature',
                    value: _temperature,
                    min: 5.0,
                    max: 45.0,
                    unit: '°C',
                    onChanged: (v) => setState(() => _temperature = v),
                    color: Colors.orange,
                  ),
                  const Divider(height: 24),
                  _buildCleanSlider(
                    label: 'Relative Humidity',
                    value: _relativeHumidity,
                    min: 10.0,
                    max: 100.0,
                    unit: '%',
                    onChanged: (v) => setState(() => _relativeHumidity = v),
                    color: Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildCleanSlider(
                    label: 'Leaf Wetness Duration',
                    value: _leafWetnessHours,
                    min: 0.0,
                    max: 24.0,
                    unit: ' hrs',
                    onChanged: (v) => setState(() => _leafWetnessHours = v),
                    color: Colors.teal,
                  ),
                  const Divider(height: 24),
                  _buildCleanSlider(
                    label: 'Daily Rainfall',
                    value: _rainfall,
                    min: 0.0,
                    max: 50.0,
                    unit: ' mm',
                    onChanged: (v) => setState(() => _rainfall = v),
                    color: Colors.indigo,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Primary Action Button
              ElevatedButton(
                onPressed: _runRiskPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Assess Outbreak Risk',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Risk Assessments (Clean list)
              if (_recentRecords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Assessments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _openHistory,
                      child: Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: _recentRecords.map((rec) {
                    final isHigh = rec.prediction.riskScore >= 0.65;
                    final isMod = rec.prediction.riskScore >= 0.35 && !isHigh;
                    final color = isHigh
                        ? AppTheme.diseasedRed
                        : (isMod ? AppTheme.warningOrange : AppTheme.primary);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withAlpha(25),
                          child: Icon(Icons.shield_outlined, color: color, size: 16),
                        ),
                        title: Text(
                          '${rec.inputData.cropName} • ${rec.inputData.location}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${(rec.prediction.riskScore * 100).toStringAsFixed(0)}% Risk (${rec.prediction.riskCategory})',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PreventionResultScreen(
                                inputData: rec.inputData,
                                prediction: rec.prediction,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCleanSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentPale,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppTheme.primaryDark,
            overlayColor: AppTheme.primary.withAlpha(30),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => onChanged(double.parse(v.toStringAsFixed(1))),
          ),
        ),
      ],
    );
  }
}
