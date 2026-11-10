import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'prevention_home_screen.dart';

/// Main Entry Hub of AgriVision:
/// Simple, clean, minimalist branch selection between:
/// 1) Disease Detection (Leaf image diagnostic scanner)
/// 2) Disease Prevention (Weather-driven risk assessment)
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgriVision AI',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Crop Disease Detection & Prevention System',
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
            const SizedBox(height: 10),
            _buildInfoRow('Institution', 'Maharaja Surajmal Institute of Technology (MSIT), New Delhi'),
            _buildInfoRow('Department', 'Computer Science & Engineering (2023–27)'),
            _buildInfoRow('Supervisor', 'Mr. Deepak'),
            _buildInfoRow('Team', 'Sameer Diwakar (02396302723)\nRohit Khandelwal (04596302723)\nVinay Pratap Singh Chauhan (04696302723)'),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            const SizedBox(height: 8),
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
      backgroundColor: AppTheme.background,
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
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AgriVision',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'AI Crop Health System',
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
                    tooltip: 'About AgriVision',
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Clean, Minimalist Welcome Header
              Text(
                'How can we help your crops today?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Diagnose visible symptoms from a photo, or check weather risk to prevent future outbreaks.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // =============================================================
              // CARD 1: DISEASE DETECTION
              // =============================================================
              _buildCleanCard(
                icon: Icons.camera_alt_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: AppTheme.primary,
                title: 'Disease Detection',
                subtitle: 'Diagnose visible leaf symptoms',
                description:
                    'Take or upload a photo of infected leaves to instantly identify diseases and receive curative treatment steps.',
                buttonText: 'Open Scanner',
                onTap: () => _navigateToDetection(context),
              ),

              const SizedBox(height: 16),

              // =============================================================
              // CARD 2: DISEASE PREVENTION
              // =============================================================
              _buildCleanCard(
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Disease Prevention',
                subtitle: 'Forecast risk before symptoms appear',
                description:
                    'Analyze temperature, humidity, and rainfall to estimate pathogen risk and protect crops with early preventive care.',
                buttonText: 'Check Risk',
                onTap: () => _navigateToPrevention(context),
                isPrimary: true,
              ),

              const SizedBox(height: 32),

              // Subtle, minimalist footer
              Center(
                child: Text(
                  'MSIT CSE • Sameer Diwakar, Rohit Khandelwal, Vinay Pratap Singh Chauhan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withAlpha(160),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? AppTheme.primary.withAlpha(80) : AppTheme.borderColor,
          width: 1.2,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      const Icon(Icons.arrow_forward_rounded, size: 16),
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
