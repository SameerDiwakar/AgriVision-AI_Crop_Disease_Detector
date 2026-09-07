import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/plant_disease_model.dart';

class PlantApiServiceException implements Exception {
  final String message;
  final bool isApiKeyError;

  PlantApiServiceException(this.message, {this.isApiKeyError = false});

  @override
  String toString() => message;
}

class PlantApiService {
  /// Identifies leaf disease from image bytes using Plant.id v3 REST API
  static Future<PlantDiseaseResult> identifyLeafDisease(Uint8List imageBytes) async {
    try {
      // 1. Convert bytes to Base64 data URI
      final String base64Image = base64Encode(imageBytes);
      final String dataUri = 'data:image/jpeg;base64,$base64Image';

      // 2. Construct API URL & Headers
      final Uri uri = Uri.parse(AppConfig.plantIdApiUrl);
      final Map<String, String> headers = {
        'Api-Key': AppConfig.plantIdApiKey,
        'Content-Type': 'application/json',
      };

      // 3. Construct JSON Body
      final Map<String, dynamic> body = {
        'images': [dataUri],
        'health': 'all',
        'similar_images': true,
      };

      // 4. Execute HTTP POST Request with timeout
      final http.Response response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      // 5. Inspect HTTP Status Code
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw PlantApiServiceException(
          'Invalid API Key. Please update your Plant.id API key in lib/config.dart.',
          isApiKeyError: true,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PlantApiServiceException(
          'Plant.id Server Error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }

      // 6. Decode JSON Response
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
}
