import 'package:flutter_test/flutter_test.dart';
import 'package:agri_vision/models/prevention_model.dart';
import 'package:agri_vision/services/prevention_ann_service.dart';

void main() {
  group('Weather Parameter & Feature Engineering Tests', () {
    test('Calculates rolling humidity, cumulative wetness, and infection flag correctly', () {
      final input = WeatherInputData.fromRaw(
        cropName: 'Wheat',
        location: 'Karnal, Haryana',
        temperature: 20.0,
        relativeHumidity: 90.0,
        leafWetnessHours: 10.0,
        rainfall: 12.0,
        pastHumidityDays: [88.0, 92.0],
        pastWetnessDays: [9.0, 11.0],
      );

      // F5 Rolling Humidity Avg: (88 + 92 + 90) / 3 = 90.0
      expect(input.rollingHumidityAvg, equals(90.0));

      // F6 Cumulative Leaf Wetness: 9 + 11 + 10 = 30.0 hrs
      expect(input.cumulativeLeafWetness, equals(30.0));

      // F7 Infection Window Flag: Temp 20°C in [12, 28.5], RH 90% >= 78%, Wetness 10h >= 5.5h
      expect(input.infectionWindowFlag, isTrue);
    });

    test('Infection Window Flag is inactive under dry, arid conditions', () {
      final input = WeatherInputData.fromRaw(
        cropName: 'Wheat',
        location: 'Jaipur, Rajasthan',
        temperature: 34.0,
        relativeHumidity: 35.0,
        leafWetnessHours: 0.5,
        rainfall: 0.0,
      );

      expect(input.infectionWindowFlag, isFalse);
    });
  });

  group('ANN Regression Risk Model Tests', () {
    test('High threat microclimate triggers High Risk (score >= 0.65)', () {
      final highRiskInput = WeatherInputData.fromRaw(
        cropName: 'Wheat',
        location: 'Karnal Field',
        temperature: 20.5,
        relativeHumidity: 94.0,
        leafWetnessHours: 12.0,
        rainfall: 15.0,
      );

      final prediction = PreventionAnnService.predictDiseaseRisk(highRiskInput);

      expect(prediction.riskScore, greaterThanOrEqualTo(0.65));
      expect(prediction.riskLevel, equals(RiskLevel.high));
      expect(prediction.isThresholdExceeded, isTrue);
      expect(prediction.estimatedLeadTimeDays, inInclusiveRange(3, 5));
      expect(prediction.dominantPathogen, contains('Puccinia'));
      expect(prediction.advisory.irrigationGuidance.isNotEmpty, isTrue);
      expect(prediction.advisory.chemicalAndBioPreventives.isNotEmpty, isTrue);
    });

    test('Dry arid microclimate produces Safe/Low Risk (score < 0.35)', () {
      final safeInput = WeatherInputData.fromRaw(
        cropName: 'Tomato',
        location: 'Arid Zone',
        temperature: 35.0,
        relativeHumidity: 30.0,
        leafWetnessHours: 0.5,
        rainfall: 0.0,
      );

      final prediction = PreventionAnnService.predictDiseaseRisk(safeInput);

      expect(prediction.riskScore, lessThan(0.35));
      expect(prediction.riskLevel, equals(RiskLevel.low));
      expect(prediction.isThresholdExceeded, isFalse);
    });

    test('Model R² benchmark matches literature specification (0.96 - 0.98)', () {
      final input = WeatherInputData.fromRaw(
        cropName: 'Potato',
        location: 'Field',
        temperature: 22.0,
        relativeHumidity: 80.0,
        leafWetnessHours: 8.0,
        rainfall: 5.0,
      );

      final prediction = PreventionAnnService.predictDiseaseRisk(input);
      expect(prediction.modelR2Benchmark, inInclusiveRange(0.96, 0.98));
    });
  });
}

