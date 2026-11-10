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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Risk Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Risk Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
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
                              input.cropName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              input.location,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskBgColor,
                            borderRadius: BorderRadius.circular(8),
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

                    // Risk Progress Meter
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: pred.riskScore,
                            strokeWidth: 10,
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
                              'Outbreak Risk',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Lead time alert
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: riskBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: riskColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Act within ${pred.estimatedLeadTimeDays} days before symptoms appear',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Primary Threat: ${pred.dominantPathogen}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Advisory Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor.withAlpha(60)),
                ),
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

              const SizedBox(height: 20),

              // Recommended Actions Section
              Text(
                'Preventive Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // 1. Irrigation
              _buildAdvisoryCard(
                icon: Icons.water_drop_outlined,
                iconColor: Colors.blue,
                title: 'Irrigation Management',
                content: pred.advisory.irrigationGuidance,
              ),

              const SizedBox(height: 10),

              // 2. Sprays
              _buildListAdvisoryCard(
                icon: Icons.sanitizer_outlined,
                iconColor: AppTheme.primary,
                title: 'Preventive Spray Schedule',
                items: pred.advisory.chemicalAndBioPreventives,
              ),

              const SizedBox(height: 10),

              // 3. Field Sanitation
              _buildListAdvisoryCard(
                icon: Icons.cleaning_services_outlined,
                iconColor: Colors.brown,
                title: 'Field Sanitation',
                items: pred.advisory.fieldSanitationSteps,
              ),

              const SizedBox(height: 10),

              // 4. Scouting
              _buildAdvisoryCard(
                icon: Icons.search_rounded,
                iconColor: Colors.purple,
                title: 'Monitoring & Scouting',
                content: pred.advisory.scoutingProtocol,
              ),

              const SizedBox(height: 20),

              // Clean Link to Detection Scanner if symptoms already visible
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Already seeing spots on your leaves?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If lesions have already developed, photograph the leaf to get a confirmed diagnosis and curative treatment.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _switchToDetectionBranch,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Open Leaf Scanner'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Return / New Assessment
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Assess Another Field',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (_isSaved)
                Center(
                  child: Text(
                    'Assessment saved to history',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12,
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
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((it) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
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
}
