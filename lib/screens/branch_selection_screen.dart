import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'prevention_home_screen.dart';

/// Main Entry Hub of AgriVision:
/// Allows the farmer/user to select between:
/// 1) Detection Branch (Reactive / Post-Symptom - CNN leaf image classifier)
/// 2) Prevention Branch (Proactive / Pre-Symptom - Weather ANN risk model)
class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({super.key});

  void _navigateToDetection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToPrevention(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreventionHomeScreen()),
    );
  }

  void _showProjectInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgriVision Dual-Branch System',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Department of Computer Science & Engineering',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow('Institution', 'Maharaja Surajmal Institute of Technology (MSIT), New Delhi'),
            _buildInfoRow('Academic Session', 'B.Tech (CSE) 2023–27'),
            _buildInfoRow('Project Supervisor', 'Mr. Deepak'),
            _buildInfoRow('Project Team', 'Sameer Diwakar (02396302723)\nRohit Khandelwal (04596302723)\nVinay Pratap Singh Chauhan (04696302723)'),
            _buildInfoRow('Current Milestone', 'M3: Weather ANN Risk Branch & M4: Fusion Groundwork'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Brand and Info Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AgriVision AI',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Detection & Prevention System',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showProjectInfoModal(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Project & Team Details',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Title & Core Philosophy
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'STAGE-AWARE PIPELINE',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose Your System Branch',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Warn before visible damage occurs, or diagnose confirmed symptoms. Select the appropriate branch for your crop stage.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withAlpha(225),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'SELECT AN OPERATIONAL BRANCH',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 14),

              // =============================================================
              // BRANCH 1: DETECTION BRANCH (Reactive / Post-Symptom)
              // =============================================================
              _buildBranchCard(
                context: context,
                badgeText: 'REACTIVE • STATE B',
                badgeColor: AppTheme.accentLight,
                badgeTextColor: AppTheme.primaryDark,
                icon: Icons.camera_alt_rounded,
                iconBgColor: const Color(0xFFE8F5E9),
                iconColor: AppTheme.primary,
                title: 'Detection Branch',
                subtitle: 'Leaf Image → CNN Classifier → Treatment Advisory',
                description:
                    'Upload or capture leaf photographs when visible spots, lesions, or powdery patches appear to identify the exact pathogen and receive targeted remedies.',
                highlights: [
                  'Deep-learning visual classification',
                  'Confidence scoring & pathogen confirmation',
                  'Biological, chemical & cultural treatments',
                ],
                buttonText: 'Launch Detection Scanner',
                buttonColor: AppTheme.primary,
                buttonTextColor: Colors.white,
                onTap: () => _navigateToDetection(context),
              ),

              const SizedBox(height: 20),

              // =============================================================
              // BRANCH 2: PREVENTION BRANCH (Proactive / Pre-Symptom)
              // =============================================================
              _buildBranchCard(
                context: context,
                badgeText: 'PROACTIVE • STATE A • M3/M4',
                badgeColor: const Color(0xFFFFE082),
                badgeTextColor: const Color(0xFF6D4C41),
                icon: Icons.cloud_sync_rounded,
                iconBgColor: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF57F17),
                title: 'Prevention Branch',
                subtitle: 'Weather Data → ANN Risk Model → Preventive Advisory',
                description:
                    'Predict infection risk 3–6 days before visible symptoms appear using temperature, relative humidity, leaf wetness duration, and rainfall parameters.',
                highlights: [
                  'Weather-driven ANN regression model (R² benchmark 0.96–0.98)',
                  '7-input engineered microclimate evaluation',
                  'Proactive irrigation & preventive spray scheduling',
                ],
                buttonText: 'Launch Prevention Engine',
                buttonColor: const Color(0xFF2D6A4F),
                buttonTextColor: Colors.white,
                onTap: () => _navigateToPrevention(context),
                isFeatured: true,
              ),

              const SizedBox(height: 24),

              // Fusion Philosophy Explainer Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stage-Aware Fusion Logic',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'High risk & no visible symptoms → Act immediately with preventive spray & irrigation control.\n\nSymptom confirmed on leaf → Use Detection Branch for disease diagnosis & curative remedies.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Academic Attribution Footer
              Center(
                child: Text(
                  'MSIT CSE 2023–27 • Supervisor: Mr. Deepak\nSameer Diwakar • Rohit Khandelwal • Vinay Pratap Singh Chauhan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withAlpha(180),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchCard({
    required BuildContext context,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required List<String> highlights,
    required String buttonText,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onTap,
    bool isFeatured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isFeatured ? AppTheme.primary : AppTheme.borderColor,
          width: isFeatured ? 2.0 : 1.2,
        ),
        boxShadow: isFeatured ? AppTheme.softShadow : AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badge & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),

                // Highlights Bullet list
                Column(
                  children: highlights.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Action Button
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    elevation: 2,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

