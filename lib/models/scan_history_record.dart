import '../models/plant_disease_model.dart';

/// Model representing a saved crop scan record in local storage.
class ScanHistoryRecord {
  final String id;
  final DateTime timestamp;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final bool isHealthy;
  final bool isPlant;
  final String description;
  final List<String> biologicalTreatment;
  final List<String> chemicalTreatment;
  final List<String> prevention;

  final String? imageBase64;

  ScanHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
    required this.isPlant,
    required this.description,
    required this.biologicalTreatment,
    required this.chemicalTreatment,
    required this.prevention,
    this.imageBase64,
  });

  /// Factory to construct a history record from an active diagnosis result & image file path
  factory ScanHistoryRecord.fromResult({
    required PlantDiseaseResult result,
    required String imagePath,
    String? imageBase64,
  }) {
    final now = DateTime.now();
    return ScanHistoryRecord(
      id: 'scan_${now.millisecondsSinceEpoch}',
      timestamp: now,
      imagePath: imagePath,
      diseaseName: result.diseaseName,
      confidence: result.confidence,
      isHealthy: result.isHealthy,
      isPlant: result.isPlant,
      description: result.description,
      biologicalTreatment: List<String>.from(result.biologicalTreatment),
      chemicalTreatment: List<String>.from(result.chemicalTreatment),
      prevention: List<String>.from(result.prevention),
      imageBase64: imageBase64 ?? result.rawImageBase64,
    );
  }

  /// Converts record to JSON map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'isHealthy': isHealthy,
      'isPlant': isPlant,
      'description': description,
      'biologicalTreatment': biologicalTreatment,
      'chemicalTreatment': chemicalTreatment,
      'prevention': prevention,
      'imageBase64': imageBase64,
    };
  }

  /// Constructs record from JSON map stored in local storage
  factory ScanHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ScanHistoryRecord(
      id: json['id'] as String? ?? 'scan_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      imagePath: json['imagePath'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown Disease',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isHealthy: json['isHealthy'] as bool? ?? false,
      isPlant: json['isPlant'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      biologicalTreatment: (json['biologicalTreatment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chemicalTreatment: (json['chemicalTreatment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      prevention: (json['prevention'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageBase64: json['imageBase64'] as String?,
    );
  }

  /// Converts history record back into PlantDiseaseResult for viewing in ResultsScreen
  PlantDiseaseResult toPlantDiseaseResult() {
    return PlantDiseaseResult(
      isPlant: isPlant,
      isHealthy: isHealthy,
      diseaseName: diseaseName,
      confidence: confidence,
      description: description,
      biologicalTreatment: biologicalTreatment,
      chemicalTreatment: chemicalTreatment,
      prevention: prevention,
      rawImageBase64: imageBase64,
    );
  }
}
