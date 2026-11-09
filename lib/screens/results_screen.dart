import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/plant_disease_model.dart';
import '../theme/app_theme.dart';
import '../widgets/treatment_card.dart';
import 'prevention_home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final PlantDiseaseResult result;
  final Uint8List? imageBytes;

  const ResultsScreen({
    super.key,
    required this.result,
    this.imageBytes,
  });

  Widget _buildLeafThumbnail() {
    final bytes = imageBytes ??
        (result.rawImageBase64 != null && result.rawImageBase64!.isNotEmpty
            ? base64Decode(result.rawImageBase64!)
            : null);

    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: 100,
      height: 100,
      color: AppTheme.accentPale,
      child: const Icon(Icons.eco_rounded, color: AppTheme.primary, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double confidencePct = (result.confidence * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Thumbnail & Diagnosis Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor, width: 1.2),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leaf Thumbnail with Hero transition
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Hero(
                        tag: 'leafImageHero',
                        child: _buildLeafThumbnail(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Disease Title, Status Chip & Confidence Ring
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: result.isHealthy
                                  ? AppTheme.healthyBackground
                                  : AppTheme.diseasedBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: result.isHealthy
                                    ? AppTheme.healthyGreen
                                    : AppTheme.diseasedRed,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  result.isHealthy
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_rounded,
                                  size: 14,
                                  color: result.isHealthy
                                      ? AppTheme.healthyGreen
                                      : AppTheme.diseasedRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  result.isHealthy ? 'Healthy Leaf' : 'Infected / Diseased',
                                  style: TextStyle(
                                    color: result.isHealthy
                                        ? AppTheme.healthyGreen
                                        : AppTheme.diseasedRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Disease Name
                          Text(
                            result.diseaseName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.25,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Confidence Ring & Percentage Text
                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  value: result.confidence.clamp(0.05, 1.0),
                                  strokeWidth: 3.5,
                                  backgroundColor: AppTheme.accentPale,
                                  color: result.isHealthy
                                      ? AppTheme.healthyGreen
                                      : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${confidencePct.toStringAsFixed(1)}% AI Confidence',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Overview Description Card
              if (result.description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnosis Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section Header: Actionable Remedies
              Text(
                'Recommended Treatments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expand each card below to view detailed recovery steps.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Biological Treatment Expandable Card
              TreatmentCard(
                title: 'Biological & Organic Remedies',
                icon: Icons.eco_rounded,
                themeColor: const Color(0xFF2D6A4F),
                items: result.biologicalTreatment,
                initiallyExpanded: true, // First card open by default
              ),

              // 2. Chemical Treatment Expandable Card
              TreatmentCard(
                title: 'Chemical Treatments',
                icon: Icons.science_rounded,
                themeColor: const Color(0xFFE07A5F),
                items: result.chemicalTreatment,
                initiallyExpanded: false,
              ),

              // 3. Prevention Expandable Card
              TreatmentCard(
                title: 'Prevention & Crop Care',
                icon: Icons.shield_rounded,
                themeColor: const Color(0xFF3D405B),
                items: result.prevention,
                initiallyExpanded: false,
              ),

              const SizedBox(height: 24),

              // Bottom Action Button: Scan Another Leaf
              ElevatedButton.icon(
                onPressed: () {
                  // Pop back to home/capture
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: const Text('Scan Another Leaf'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 3,
                ),
              ),

              const SizedBox(height: 12),

              // Stage-Aware Link to Prevention Branch
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreventionHomeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_sync_rounded, color: AppTheme.primary),
                label: const Text('Assess Weather Risk for This Field'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
