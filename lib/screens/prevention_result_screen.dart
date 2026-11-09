import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prevention_model.dart';
import '../services/prevention_history_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class PreventionResultScreen extends StatefulWidget {
  final WeatherInputData inputData;
  final AnnRiskPrediction prediction;

  const PreventionResultScreen({
    super.key,
    required this.inputData,
    required this.prediction,
  });

  @override
  State<PreventionResultScreen> createState() => _PreventionResultScreenState();
}

class _PreventionResultScreenState extends State<PreventionResultScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _autoSaveRecord();
  }

  Future<void> _autoSaveRecord() async {
    final record = PreventionHistoryRecord(
      id: 'prev_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      inputData: widget.inputData,
      prediction: widget.prediction,
    );

    await PreventionHistoryService.saveRecord(record);
    if (mounted) {
      setState(() => _isSaved = true);
    }
  }

  Color _getRiskColor(double score) {
    if (score >= 0.65) return AppTheme.diseasedRed;
    if (score >= 0.35) return AppTheme.warningOrange;
    return AppTheme.healthyGreen;
  }

  Color _getRiskBgColor(double score) {
    if (score >= 0.65) return const Color(0xFFFFEBEE);
    if (score >= 0.35) return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F5E9);
  }

  void _switchToDetectionBranch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pred = widget.prediction;
    final input = widget.inputData;
    final riskColor = _getRiskColor(pred.riskScore);
    final riskBgColor = _getRiskBgColor(pred.riskScore);
    final riskPercent = (pred.riskScore * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Symptom Risk Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Risk Gauge Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: riskColor.withAlpha(120), width: 1.5),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              input.cropName.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              input.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: riskColor.withAlpha(100)),
                          ),
                          child: Text(
                            pred.riskCategory,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Circular Risk Meter Display
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: pred.riskScore,
                            strokeWidth: 12,
                            backgroundColor: AppTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$riskPercent%',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'RISK SCORE',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '(${pred.riskScore.toStringAsFixed(2)})',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Lead Time Gained Alert (Milestone M4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: riskBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: riskColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${pred.estimatedLeadTimeDays} Days Lead Time Gained over Detect-and-Treat Baseline',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Target Pathogen Identified
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bug_report_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Target Pathogen: ${pred.dominantPathogen}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary Alert Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      pred.isThresholdExceeded
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: riskColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pred.advisory.summaryAlert,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Pre-Symptom Preventive Advisory (State A Actions)
              Text(
                'PREVENTIVE ADVISORY (STATE A: PRE-SYMPTOM)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // 1. Irrigation & Canopy Moisture Control
              _buildAdvisoryCard(
                icon: Icons.water_drop_rounded,
                iconColor: Colors.blue,
                title: 'Irrigation & Canopy Management',
                content: pred.advisory.irrigationGuidance,
              ),

              const SizedBox(height: 12),

              // 2. Chemical & Bio Preventives Schedule
              _buildListAdvisoryCard(
                icon: Icons.sanitizer_rounded,
                iconColor: AppTheme.primary,
                title: 'Preventive Spray & Bio-Control Schedule',
                subtitle:
                    'Apply prophylactic protection ahead of spore release window:',
                items: pred.advisory.chemicalAndBioPreventives,
              ),

              const SizedBox(height: 12),

              // 3. Field Sanitation & Residue Control
              _buildListAdvisoryCard(
                icon: Icons.cleaning_services_rounded,
                iconColor: Colors.brown,
                title: 'Field Sanitation & Crop Residue',
                subtitle:
                    'Eliminate primary inoculum sources and improve airflow:',
                items: pred.advisory.fieldSanitationSteps,
              ),

              const SizedBox(height: 12),

              // 4. Field Scouting Protocol
              _buildAdvisoryCard(
                icon: Icons.search_rounded,
                iconColor: Colors.purple,
                title: 'Field Scouting & Leaf Surveillance',
                content: pred.advisory.scoutingProtocol,
              ),

              const SizedBox(height: 24),

              // ANN Model Formulation Transparency Card (M3 Week 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded,
                            color: AppTheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'ANN Regression Model Architecture',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSpecRow('Model Type', 'Artificial Neural Network (Dense MLP Regression)'),
                    _buildSpecRow('Inputs', '7 Features (4 Weather + 3 Engineered Biology Features)'),
                    _buildSpecRow('Engineered Inputs', 'H_roll (Rolling Hum), L_cum (Cum Wetness), I_w (Infection Flag)'),
                    _buildSpecRow('Loss & Optimizer', 'MSE Loss • Adam Optimizer (Adaptive Learning Rate)'),
                    _buildSpecRow('Evaluation Benchmark', 'R² = ${pred.modelR2Benchmark} (Literature Benchmark: 0.96–0.98)'),
                    _buildSpecRow('Decision Logic', 'Continuous Score [0–1] evaluated against threshold (0.65)'),

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),

                    Text(
                      'Feature Contributions to This Assessment:',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...pred.featureContributions.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (entry.value / 0.35).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.background,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryLight),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${(entry.value * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =============================================================
              // M4 STAGE-AWARE FUSION CALLOUT (Connecting Reactive Branch)
              // =============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.camera_enhance_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'State B: Symptoms Already Visible?',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If visible necrotic lesions, yellow spots, or rust pustules have already appeared on your crop, transition to the Detection Branch to confirm disease class with deep CNN leaf classification.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _switchToDetectionBranch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.primaryDark,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Switch to Detection Branch Scanner',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Actions: Return to Hub
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Assess Another Microclimate',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              if (_isSaved)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Assessment automatically saved to farm history',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListAdvisoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((it) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      it,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

