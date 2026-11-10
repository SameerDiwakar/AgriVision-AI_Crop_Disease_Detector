import 'dart:math';

/// Represents the raw and engineered weather parameters for the ANN Risk Model
class WeatherInputData {
  final String cropName;
  final String location;
  final double temperature; // °C
  final double relativeHumidity; // %
  final double leafWetnessHours; // Hours (0 - 24)
  final double rainfall; // mm

  // Engineered biological features
  final double rollingHumidityAvg; // Rolling humidity average (multi-day)
  final double cumulativeLeafWetness; // Cumulative leaf wetness duration
  final bool infectionWindowFlag; // Infection window flag (favourable conditions)

  WeatherInputData({
    required this.cropName,
    required this.location,
    required this.temperature,
    required this.relativeHumidity,
    required this.leafWetnessHours,
    required this.rainfall,
    required this.rollingHumidityAvg,
    required this.cumulativeLeafWetness,
    required this.infectionWindowFlag,
  });

  /// Factory that takes the 4 raw parameters and computes the 3 engineered features
  /// using plant pathology empirical formulation with optional past 3-day history.
  factory WeatherInputData.fromRaw({
    required String cropName,
    required String location,
    required double temperature,
    required double relativeHumidity,
    required double leafWetnessHours,
    required double rainfall,
    List<double>? pastHumidityDays,
    List<double>? pastWetnessDays,
  }) {
    // 1. Calculate F5: Rolling Humidity Average (3-day default window)
    double rollHum;
    if (pastHumidityDays != null && pastHumidityDays.isNotEmpty) {
      final all = [...pastHumidityDays, relativeHumidity];
      rollHum = all.reduce((a, b) => a + b) / all.length;
    } else {
      // If no history, estimate rolling humidity with slight temporal weighting
      rollHum = relativeHumidity * 0.95 + 2.0;
    }
    rollHum = rollHum.clamp(0.0, 100.0);

    // 2. Calculate F6: Cumulative Leaf Wetness Duration (3-day cumulative window)
    double cumWetness;
    if (pastWetnessDays != null && pastWetnessDays.isNotEmpty) {
      final all = [...pastWetnessDays, leafWetnessHours];
      cumWetness = all.reduce((a, b) => a + b);
    } else {
      // Estimate cumulative wetness over past 48-72h based on current wetness & rainfall
      final rainBonus = rainfall > 5.0 ? min(rainfall * 0.4, 8.0) : 0.0;
      cumWetness = (leafWetnessHours * 2.2) + rainBonus;
    }
    cumWetness = cumWetness.clamp(0.0, 72.0);

    // 3. Calculate F7: Infection Window Flag
    // Favourable infection conditions:
    // Temperature in pathogen sporulation window (12°C - 28°C),
    // Relative Humidity >= 78%, and Leaf Wetness >= 5.5 hours.
    final bool isTempFavourable = temperature >= 12.0 && temperature <= 28.5;
    final bool isHumidityFavourable = relativeHumidity >= 78.0;
    final bool isWetnessFavourable = leafWetnessHours >= 5.5 || rainfall >= 6.0;

    final bool infectionWindow =
        isTempFavourable && isHumidityFavourable && isWetnessFavourable;

    return WeatherInputData(
      cropName: cropName,
      location: location,
      temperature: temperature,
      relativeHumidity: relativeHumidity,
      leafWetnessHours: leafWetnessHours,
      rainfall: rainfall,
      rollingHumidityAvg: double.parse(rollHum.toStringAsFixed(1)),
      cumulativeLeafWetness: double.parse(cumWetness.toStringAsFixed(1)),
      infectionWindowFlag: infectionWindow,
    );
  }

  Map<String, dynamic> toJson() => {
        'cropName': cropName,
        'location': location,
        'temperature': temperature,
        'relativeHumidity': relativeHumidity,
        'leafWetnessHours': leafWetnessHours,
        'rainfall': rainfall,
        'rollingHumidityAvg': rollingHumidityAvg,
        'cumulativeLeafWetness': cumulativeLeafWetness,
        'infectionWindowFlag': infectionWindowFlag,
      };

  factory WeatherInputData.fromJson(Map<String, dynamic> json) =>
      WeatherInputData(
        cropName: json['cropName'] as String? ?? 'General Crop',
        location: json['location'] as String? ?? 'Field Station',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 24.0,
        relativeHumidity:
            (json['relativeHumidity'] as num?)?.toDouble() ?? 70.0,
        leafWetnessHours:
            (json['leafWetnessHours'] as num?)?.toDouble() ?? 6.0,
        rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0.0,
        rollingHumidityAvg:
            (json['rollingHumidityAvg'] as num?)?.toDouble() ?? 70.0,
        cumulativeLeafWetness:
            (json['cumulativeLeafWetness'] as num?)?.toDouble() ?? 12.0,
        infectionWindowFlag: json['infectionWindowFlag'] as bool? ?? false,
      );
}

/// Risk level classification based on the continuous score
enum RiskLevel {
  low, // Score < 0.35
  moderate, // Score 0.35 - 0.65
  high, // Score >= 0.65 (Critical threshold)
}

/// Represents the output of the ANN Regression Risk Model
class AnnRiskPrediction {
  final double riskScore; // 0.0 to 1.0 continuous score
  final RiskLevel riskLevel;
  final String riskCategory; // 'Low / Safe', 'Moderate / Watch', 'High / Critical'
  final bool isThresholdExceeded; // True if riskScore >= 0.65
  final String dominantPathogen;
  final int estimatedLeadTimeDays; // Estimated days before visible symptom onset
  final double modelR2Benchmark; // 0.96 - 0.98 literature benchmark
  final Map<String, double> featureContributions; // Weight impact of the 7 features
  final PreventiveAdvisory advisory;
  final DateTime assessedAt;

  AnnRiskPrediction({
    required this.riskScore,
    required this.riskLevel,
    required this.riskCategory,
    required this.isThresholdExceeded,
    required this.dominantPathogen,
    required this.estimatedLeadTimeDays,
    required this.modelR2Benchmark,
    required this.featureContributions,
    required this.advisory,
    required this.assessedAt,
  });

  Map<String, dynamic> toJson() => {
        'riskScore': riskScore,
        'riskCategory': riskCategory,
        'isThresholdExceeded': isThresholdExceeded,
        'dominantPathogen': dominantPathogen,
        'estimatedLeadTimeDays': estimatedLeadTimeDays,
        'modelR2Benchmark': modelR2Benchmark,
        'featureContributions': featureContributions,
        'advisory': advisory.toJson(),
        'assessedAt': assessedAt.toIso8601String(),
      };

  factory AnnRiskPrediction.fromJson(Map<String, dynamic> json) {
    final double score = (json['riskScore'] as num?)?.toDouble() ?? 0.0;
    RiskLevel level = RiskLevel.low;
    if (score >= 0.65) {
      level = RiskLevel.high;
    } else if (score >= 0.35) {
      level = RiskLevel.moderate;
    }

    return AnnRiskPrediction(
      riskScore: score,
      riskLevel: level,
      riskCategory: json['riskCategory'] as String? ?? 'Low / Safe',
      isThresholdExceeded: json['isThresholdExceeded'] as bool? ?? false,
      dominantPathogen:
          json['dominantPathogen'] as String? ?? 'General Fungal Pathogen',
      estimatedLeadTimeDays: json['estimatedLeadTimeDays'] as int? ?? 5,
      modelR2Benchmark:
          (json['modelR2Benchmark'] as num?)?.toDouble() ?? 0.97,
      featureContributions: (json['featureContributions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      advisory: PreventiveAdvisory.fromJson(
          json['advisory'] as Map<String, dynamic>? ?? {}),
      assessedAt: json['assessedAt'] != null
          ? DateTime.parse(json['assessedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Preventive Action Advisory
class PreventiveAdvisory {
  final String irrigationGuidance;
  final List<String> chemicalAndBioPreventives;
  final List<String> fieldSanitationSteps;
  final String scoutingProtocol;
  final String summaryAlert;

  PreventiveAdvisory({
    required this.irrigationGuidance,
    required this.chemicalAndBioPreventives,
    required this.fieldSanitationSteps,
    required this.scoutingProtocol,
    required this.summaryAlert,
  });

  Map<String, dynamic> toJson() => {
        'irrigationGuidance': irrigationGuidance,
        'chemicalAndBioPreventives': chemicalAndBioPreventives,
        'fieldSanitationSteps': fieldSanitationSteps,
        'scoutingProtocol': scoutingProtocol,
        'summaryAlert': summaryAlert,
      };

  factory PreventiveAdvisory.fromJson(Map<String, dynamic> json) =>
      PreventiveAdvisory(
        irrigationGuidance: json['irrigationGuidance'] as String? ?? '',
        chemicalAndBioPreventives: (json['chemicalAndBioPreventives'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fieldSanitationSteps: (json['fieldSanitationSteps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        scoutingProtocol: json['scoutingProtocol'] as String? ?? '',
        summaryAlert: json['summaryAlert'] as String? ?? '',
      );
}

/// Storage record for Prevention History
class PreventionHistoryRecord {
  final String id;
  final DateTime timestamp;
  final WeatherInputData inputData;
  final AnnRiskPrediction prediction;

  PreventionHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.inputData,
    required this.prediction,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'inputData': inputData.toJson(),
        'prediction': prediction.toJson(),
      };

  factory PreventionHistoryRecord.fromJson(Map<String, dynamic> json) =>
      PreventionHistoryRecord(
        id: json['id'] as String? ?? 'prev_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        inputData: WeatherInputData.fromJson(
            json['inputData'] as Map<String, dynamic>? ?? {}),
        prediction: AnnRiskPrediction.fromJson(
            json['prediction'] as Map<String, dynamic>? ?? {}),
      );
}

