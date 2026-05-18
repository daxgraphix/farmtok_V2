class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final int uvIndex;
  final double rainfallProbability;
  final List<ForecastDay> forecast;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.rainfallProbability,
    required this.forecast,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};

    return WeatherData(
      temperature: (main['temp'] as num? ?? 0).toDouble(),
      humidity: (main['humidity'] as num? ?? 0).toDouble(),
      windSpeed: (wind['speed'] as num? ?? 0).toDouble(),
      uvIndex: (json['uvi'] as num? ?? 0).toInt(),
      rainfallProbability: ((rain['1h'] as num? ?? 0).toDouble()) * 100,
      forecast: [],
      timestamp: DateTime.now(),
    );
  }

  // Smart recommendations based on weather
  bool get isSafeForSpraying => windSpeed < 15 && humidity < 80 && rainfallProbability < 40;
  bool get highFungalRisk => humidity > 80;
  bool get shouldDelaySpraying => rainfallProbability > 40;

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'uvIndex': uvIndex,
      'rainfallProbability': rainfallProbability,
      'forecast': forecast.map((f) => f.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ForecastDay {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String condition;
  final double rainfallProbability;

  ForecastDay({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.rainfallProbability,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'condition': condition,
      'rainfallProbability': rainfallProbability,
    };
  }
}