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
  // Inputs
  String _selectedCrop = 'Wheat';
  final TextEditingController _customCropController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: 'Karnal, Haryana');

  double _temperature = 21.0; // °C
  double _relativeHumidity = 88.0; // %
  double _leafWetnessHours = 9.5; // Hours
  double _rainfall = 12.0; // mm

  bool _isFetchingLiveWeather = false;
  String? _weatherFetchMessage;
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
        content: Text('Applied preset: ${preset['label']}'),
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
      _weatherFetchMessage = 'Fetching live open-meteo station data...';
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
        _weatherFetchMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Updated live weather for ${liveData.location}: ${_temperature.toStringAsFixed(1)}°C, ${_relativeHumidity.toStringAsFixed(0)}% RH'),
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
        : 'Field Station';

    // 1. Build WeatherInputData (computes F5, F6, F7)
    final inputData = WeatherInputData.fromRaw(
      cropName: cropName,
      location: location,
      temperature: _temperature,
      relativeHumidity: _relativeHumidity,
      leafWetnessHours: _leafWetnessHours,
      rainfall: _rainfall,
    );

    // 2. Formulated ANN Regression Model
    final AnnRiskPrediction prediction =
        PreventionAnnService.predictDiseaseRisk(inputData);

    // 3. Navigate to results screen
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
    // Current live computed engineered features
    final currentInput = WeatherInputData.fromRaw(
      cropName: _selectedCrop,
      location: _locationController.text,
      temperature: _temperature,
      relativeHumidity: _relativeHumidity,
      leafWetnessHours: _leafWetnessHours,
      rainfall: _rainfall,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Prevention Branch'),
            Text(
              'Weather-Driven Proactive Risk Model',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Return to Branch Chooser',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _openHistory,
            tooltip: 'Prevention History',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: _switchToDetectionBranch,
            tooltip: 'Switch to Detection Branch',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stage Fusion Quick Switcher Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Proactive Mode (State A): Forecast disease risk before symptoms appear.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _switchToDetectionBranch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Detection →',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Preset Field Conditions Carousel / Chips
              Text(
                'PRESET FIELD MICROCLIMATES',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderColor),
                      onPressed: () => _applyPreset(preset),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Crop & Location Card
              _buildSectionCard(
                title: 'Crop & Location Parameters',
                icon: Icons.grass_rounded,
                children: [
                  // Crop Selector
                  Text(
                    'Select Target Plant / Crop',
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
                        icon: const Icon(Icons.arrow_drop_down_rounded,
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
                        labelText: 'Enter Plant / Crop Name',
                        hintText: 'e.g. Barley, Soybean, Capsicum',
                        prefixIcon: const Icon(Icons.eco_rounded, size: 20),
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

                  // Location Input + Live Fetch Button
                  Text(
                    'Farm Field Location',
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
                            hintText: 'e.g. Najafgarh, New Delhi / Karnal',
                            prefixIcon: const Icon(Icons.location_on_rounded,
                                size: 20, color: AppTheme.primary),
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
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isFetchingLiveWeather
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_download_rounded,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4 Core Environmental Parameters Section (M3 Week 1)
              _buildSectionCard(
                title: '4 Finalised Weather Parameters',
                subtitle:
                    'Identified from plant pathology literature as primary drivers of disease onset.',
                icon: Icons.thermostat_rounded,
                children: [
                  // Parameter 1: Temperature
                  _buildSliderParameter(
                    label: '01 Temperature (°C)',
                    description:
                        'Defines pathogen-favourable range (optimum: 16–26°C)',
                    value: _temperature,
                    min: 5.0,
                    max: 45.0,
                    unit: '°C',
                    onChanged: (v) => setState(() => _temperature = v),
                    icon: Icons.device_thermostat_rounded,
                    color: Colors.orange,
                  ),
                  const Divider(height: 24),

                  // Parameter 2: Relative Humidity
                  _buildSliderParameter(
                    label: '02 Relative Humidity (%)',
                    description:
                        'Sustained high moisture enables spore germination (>78%)',
                    value: _relativeHumidity,
                    min: 10.0,
                    max: 100.0,
                    unit: '%',
                    onChanged: (v) => setState(() => _relativeHumidity = v),
                    icon: Icons.water_drop_rounded,
                    color: Colors.blue,
                  ),
                  const Divider(height: 24),

                  // Parameter 3: Leaf Wetness Duration
                  _buildSliderParameter(
                    label: '03 Leaf Wetness Duration (Hours)',
                    description:
                        'Single strongest predictor in literature — continuous wet canopy period',
                    value: _leafWetnessHours,
                    min: 0.0,
                    max: 24.0,
                    unit: ' hrs',
                    onChanged: (v) => setState(() => _leafWetnessHours = v),
                    icon: Icons.schedule_rounded,
                    color: Colors.teal,
                  ),
                  const Divider(height: 24),

                  // Parameter 4: Rainfall
                  _buildSliderParameter(
                    label: '04 Daily Rainfall (mm)',
                    description:
                        'Drives splash dispersal of spores & prolongs wetness',
                    value: _rainfall,
                    min: 0.0,
                    max: 50.0,
                    unit: ' mm',
                    onChanged: (v) => setState(() => _rainfall = v),
                    icon: Icons.grain_rounded,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 12),
                  // Drop justification note from Slide 3
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wind speed and dew point were evaluated and excluded to reduce overfitting on modest field datasets and focus on the highest predictive variables.',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.brown.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Feature Engineering Live View (M3 Week 2: 7 Engineered Features)
              _buildSectionCard(
                title: 'Engineered Features (M3 Formulation)',
                subtitle:
                    'Derived features describe the biological infection process over time rather than just single-day weather.',
                icon: Icons.hub_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEngineeredBadge(
                          code: 'F5',
                          title: 'Rolling Humidity Avg',
                          formula: 'H_roll,t = 1/k Σ H_t-i',
                          value:
                              '${currentInput.rollingHumidityAvg.toStringAsFixed(1)}%',
                          highlight: currentInput.rollingHumidityAvg >= 80.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEngineeredBadge(
                          code: 'F6',
                          title: 'Cumulative Wetness',
                          formula: 'L_cum,t = Σ L_t-i',
                          value:
                              '${currentInput.cumulativeLeafWetness.toStringAsFixed(1)} hrs',
                          highlight: currentInput.cumulativeLeafWetness >= 12.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfectionWindowBadge(currentInput.infectionWindowFlag),
                ],
              ),

              const SizedBox(height: 26),

              // Run ANN Regression Prediction Button
              ElevatedButton(
                onPressed: _runRiskPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Compute Disease Risk (ANN Model)',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Recent Risk Assessments (if any)
              if (_recentRecords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT ASSESSMENTS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
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
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(35),
                          child: Icon(Icons.shield_rounded, color: color),
                        ),
                        title: Text(
                          '${rec.inputData.cropName} • ${rec.inputData.location}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Risk: ${(rec.prediction.riskScore * 100).toStringAsFixed(0)}% • ${rec.prediction.riskCategory}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderParameter({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentPale,
                borderRadius: BorderRadius.circular(8),
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
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppTheme.primaryDark,
            overlayColor: AppTheme.primary.withAlpha(40),
            trackHeight: 5,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) =>
                onChanged(double.parse(v.toStringAsFixed(1))),
          ),
        ),
      ],
    );
  }

  Widget _buildEngineeredBadge({
    required String code,
    required String title,
    required String formula,
    required String value,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFF3E0)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? Colors.orange : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.deepOrange : AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            formula,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfectionWindowBadge(bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: isActive ? AppTheme.diseasedRed : AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'F7: Infection Window Flag: ${isActive ? "ACTIVE (I_w = 1)" : "INACTIVE (I_w = 0)"}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppTheme.diseasedRed : AppTheme.primary,
                  ),
                ),
                Text(
                  isActive
                      ? 'Simultaneous favourable temperature, humidity & wetness threshold met.'
                      : 'Environmental conditions currently outside pathogen germination envelope.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

