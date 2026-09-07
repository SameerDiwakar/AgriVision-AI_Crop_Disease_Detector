class PlantDiseaseResult {
  final bool isPlant;
  final bool isHealthy;
  final String diseaseName;
  final double confidence; // 0.0 to 1.0
  final String description;
  final List<String> biologicalTreatment;
  final List<String> chemicalTreatment;
  final List<String> prevention;
  final String? rawImageBase64;

  PlantDiseaseResult({
    required this.isPlant,
    required this.isHealthy,
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.biologicalTreatment,
    required this.chemicalTreatment,
    required this.prevention,
    this.rawImageBase64,
  });

  factory PlantDiseaseResult.fromJson(Map<String, dynamic> json, {String? imageBase64}) {
    final result = json['result'] as Map<String, dynamic>? ?? {};

    // 1. Check is_plant
    final isPlantMap = result['is_plant'] as Map<String, dynamic>?;
    final bool isPlant = isPlantMap?['binary'] as bool? ??
        (isPlantMap?['probability'] != null && (isPlantMap!['probability'] as num) > 0.5);

    // If not a plant, return early with isPlant false
    if (!isPlant) {
      return PlantDiseaseResult(
        isPlant: false,
        isHealthy: false,
        diseaseName: 'Not a Plant',
        confidence: 0.0,
        description: 'The uploaded image does not appear to be a plant leaf.',
        biologicalTreatment: [],
        chemicalTreatment: [],
        prevention: [],
        rawImageBase64: imageBase64,
      );
    }

    // 2. Check is_healthy
    final isHealthyMap = result['is_healthy'] as Map<String, dynamic>?;
    final bool isHealthy = isHealthyMap?['binary'] as bool? ?? false;

    // 3. Get disease suggestions
    final diseaseMap = result['disease'] as Map<String, dynamic>? ?? {};
    final suggestions = diseaseMap['suggestions'] as List<dynamic>? ?? [];

    String name = isHealthy ? 'Healthy Plant' : 'Unknown Disease';
    double prob = 0.0;
    String desc = '';
    List<String> bio = [];
    List<String> chem = [];
    List<String> prev = [];

    if (suggestions.isNotEmpty) {
      final firstSuggestion = suggestions[0] as Map<String, dynamic>;
      name = firstSuggestion['name'] as String? ?? name;
      prob = (firstSuggestion['probability'] as num?)?.toDouble() ?? 0.0;

      final details = firstSuggestion['details'] as Map<String, dynamic>? ?? {};
      
      // Description field
      final descData = details['description'];
      if (descData is Map<String, dynamic>) {
        desc = descData['value'] as String? ?? '';
      } else if (descData is String) {
        desc = descData;
      }

      // Treatment fields
      final treatmentMap = details['treatment'] as Map<String, dynamic>? ?? {};
      bio = _parseStringList(treatmentMap['biological']);
      chem = _parseStringList(treatmentMap['chemical']);
      prev = _parseStringList(treatmentMap['prevention']);
    }

    // Fallbacks if treatment arrays are empty
    if (isHealthy) {
      if (bio.isEmpty) bio = ['No treatment required. Maintain current watering and soil fertilization.'];
      if (chem.isEmpty) chem = ['No chemical pesticides or fungicides needed.'];
      if (prev.isEmpty) prev = ['Inspect crop leaves weekly for early signs of pests or lesions.'];
    } else {
      if (bio.isEmpty) {
        bio = ['Prune and burn affected foliage to prevent fungal/bacterial spreading.'];
      }
      if (chem.isEmpty) {
        chem = ['Consult local agricultural extensión officers for recommended fungicides/bactericides.'];
      }
      if (prev.isEmpty) {
        prev = ['Ensure proper plant spacing for ventilation and avoid overhead watering.'];
      }
    }

    return PlantDiseaseResult(
      isPlant: isPlant,
      isHealthy: isHealthy,
      diseaseName: name,
      confidence: prob,
      description: desc.isNotEmpty
          ? desc
          : (isHealthy
              ? 'This plant appears healthy with no visible pathogen symptoms detected.'
              : 'Pathogen detected on leaf sample. Follow treatment guidelines below.'),
      biologicalTreatment: bio,
      chemicalTreatment: chem,
      prevention: prev,
      rawImageBase64: imageBase64,
    );
  }

  static List<String> _parseStringList(dynamic item) {
    if (item == null) return [];
    if (item is List) {
      return item.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (item is String && item.trim().isNotEmpty) {
      return [item.trim()];
    }
    return [];
  }
}
