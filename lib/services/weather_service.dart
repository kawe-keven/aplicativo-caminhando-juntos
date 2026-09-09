import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static const String _weatherCacheKey = 'cached_temperature';
  static const String _weatherTimestampKey = 'cached_weather_timestamp';
  static const int _cacheExpirationMinutes = 30;

  Future<double?> fetchTemperature(double lat, double lon) async {
    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedTemp = prefs.getDouble(_weatherCacheKey);
      final cachedTimestamp = prefs.getInt(_weatherTimestampKey);

      if (cachedTemp != null && cachedTimestamp != null) {
        final lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        final difference = DateTime.now().difference(lastFetch).inMinutes;
        if (difference < _cacheExpirationMinutes) {
          debugPrint('Weather: Using cached temperature: $cachedTemp');
          return cachedTemp;
        }
      }

      // Fetch from Open-Meteo (No API Key required)
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double temperature = data['current_weather']['temperature'];

        // Save to cache
        await prefs.setDouble(_weatherCacheKey, temperature);
        await prefs.setInt(_weatherTimestampKey, DateTime.now().millisecondsSinceEpoch);

        debugPrint('Weather: New temperature fetched: $temperature');
        return temperature;
      } else {
        debugPrint('Weather API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Weather Service Exception: $e');
    }
    return null;
  }
}
