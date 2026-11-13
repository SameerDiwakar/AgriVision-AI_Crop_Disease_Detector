/// Configuration file for AgriVision app.
/// Store API Keys and configuration endpoints here.

class AppConfig {
  /// Active Plant Identification API Key (Pl@ntNet / Plant.id)
  static const String plantIdApiKey = '2b10dhopZGxkF6KQ3iKlNNYe';

  /// Primary Identification API endpoint (Pl@ntNet)
  static const String plantIdApiUrl =
      'https://my-api.plantnet.org/v2/identify/all';

  /// Alternate Plant.id v3 identification endpoint
  static const String plantIdBackupUrl =
      'https://api.plant.id/v3/identification?details=treatment,description,local_name,common_names';
}
