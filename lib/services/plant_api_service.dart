import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/plant_disease_model.dart';

class PlantApiServiceException implements Exception {
  final String message;
  final bool isApiKeyError;
  final bool isQuotaExceeded;

  PlantApiServiceException(
    this.message, {
    this.isApiKeyError = false,
    this.isQuotaExceeded = false,
  });

  @override
  String toString() => message;
}

class PlantApiService {
  static const String _customKeyStorage = 'custom_plant_id_api_key';

  /// Retrieves the active API key: user-configured key from SharedPreferences if set,
  /// or defaults to AppConfig.plantIdApiKey.
  static Future<String> getActiveApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_customKeyStorage);
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim();
      }
    } catch (_) {}
    return AppConfig.plantIdApiKey;
  }

  /// Sets a custom user API key in SharedPreferences
  static Future<void> setCustomApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(_customKeyStorage);
    } else {
      await prefs.setString(_customKeyStorage, key.trim());
    }
  }

  /// Identifies leaf disease from image bytes using Plant.id v3 REST API
  static Future<PlantDiseaseResult> identifyLeafDisease(Uint8List imageBytes) async {
    try {
      // 1. Convert bytes to Base64 data URI
      final String base64Image = base64Encode(imageBytes);
      final String dataUri = 'data:image/jpeg;base64,$base64Image';

      // 2. Fetch active API Key
      final String apiKey = await getActiveApiKey();

      // 3. Construct API URL & Headers
      final Uri uri = Uri.parse(AppConfig.plantIdApiUrl);
      final Map<String, String> headers = {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      };

      // 4. Construct JSON Body
      final Map<String, dynamic> body = {
        'images': [dataUri],
        'health': 'all',
        'similar_images': true,
      };

      // 5. Execute HTTP POST Request with timeout
      final http.Response response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      // 6. Handle HTTP Status Codes
      if (response.statusCode == 429) {
        throw PlantApiServiceException(
          'Plant.id API quota exhausted (70/70 free credits used). Please update your API key or use demo diagnosis.',
          isQuotaExceeded: true,
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw PlantApiServiceException(
          'Invalid Plant.id API Key. Please provide an active key in settings.',
          isApiKeyError: true,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PlantApiServiceException(
          'Plant.id Server Error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }

      // 7. Decode JSON Response
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      return PlantDiseaseResult.fromJson(
        jsonResponse,
        imageBase64: base64Image,
      );
    } on http.ClientException {
      throw PlantApiServiceException(
        'Unable to connect to plant identification server. Check your connection.',
      );
    } on FormatException {
      throw PlantApiServiceException(
        'Invalid response format received from plant identification API.',
      );
    } catch (e) {
      if (e is PlantApiServiceException) rethrow;
      throw PlantApiServiceException(
        'An unexpected error occurred while analyzing the leaf: $e',
      );
    }
  }

  /// High-fidelity offline/fallback diagnostic model to ensure demos and presentations
  /// continue smoothly even when cloud API quota runs out.
  static PlantDiseaseResult generateDemoResult({String? imageBase64}) {
    return PlantDiseaseResult(
      isPlant: true,
      isHealthy: false,
      diseaseName: 'Early Blight (Alternaria solani)',
      confidence: 0.94,
      description:
          'Early blight is a common foliar fungal disease characterized by concentric circular dark brown lesions with chlorotic yellow halos, causing premature leaf drop and reduced crop yield.',
      biologicalTreatment: [
        'Apply bio-fungicides based on Bacillus subtilis or Trichoderma viride @ 5ml/L.',
        'Prune lower senescent leaves (0-15 cm from ground) to reduce inoculum spread.',
        'Spray cold-pressed neem oil formulation (3-5 ml/L) during early morning.',
      ],
      chemicalTreatment: [
        'Apply protectant fungicide Mancozeb 75% WP @ 2.5g/L or Copper Oxychloride 50% WP @ 2.0g/L.',
        'For progressive infections, alternate with systemic fungicides like Azoxystrobin or Difenoconazole.',
      ],
      prevention: [
        'Ensure proper row spacing (45-60 cm) to facilitate air circulation within the canopy.',
        'Avoid overhead sprinkler watering; deliver irrigation directly to soil base with drip systems.',
        'Follow 3-year crop rotation with non-solanaceous crops to break fungal survival cycles.',
      ],
      rawImageBase64: imageBase64,
    );
  }
}
