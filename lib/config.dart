/// Configuration file for AgriVision app.
/// Store API Keys and configuration endpoints here.

class AppConfig {
  /// Plant.id (Kindwise) v3 API Key
  /// Replace with your active Plant.id API key from https://api.plant.id/
  static const String plantIdApiKey = '2b10dhopZGxkF6KQ3iKlNNYe';

  /// Base URL for Plant.id v3 identification endpoint
  static const String plantIdApiUrl =
       'https://my-api.plantnet.org/v2/identify/all';
}
