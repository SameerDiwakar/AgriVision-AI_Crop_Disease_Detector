/// Configuration file for AgriVision app.
/// Store API Keys and configuration endpoints here.

class AppConfig {
  /// Plant.id (Kindwise) v3 API Key
  /// Replace with your active Plant.id API key from https://api.plant.id/
  static const String plantIdApiKey = '5ncueCeooobCC03FPDv2NL8gv9AdQs8C1BazODOblqEcgvNsFn';

  /// Base URL for Plant.id v3 identification endpoint
  static const String plantIdApiUrl =
      'https://api.plant.id/v3/identification?details=treatment,description,local_name,common_names';
}
