import 'dart:async';
import 'package:caminhandojuntos/services/weather_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

final weatherServiceProvider = Provider((ref) => WeatherService());

class WeatherState {
  final String formattedDate;
  final String temperature;
  final bool isLoading;

  WeatherState({
    required this.formattedDate,
    this.temperature = '--',
    this.isLoading = false,
  });

  WeatherState copyWith({
    String? formattedDate,
    String? temperature,
    bool? isLoading,
  }) {
    return WeatherState(
      formattedDate: formattedDate ?? this.formattedDate,
      temperature: temperature ?? this.temperature,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;
  Timer? _timer;

  WeatherNotifier(this._weatherService)
      : super(WeatherState(formattedDate: _getFormattedDate())) {
    _init();
  }

  static String _getFormattedDate() {
    final now = DateTime.now();
    // Exemplo: "Segunda-feira, 8 de setembro"
    return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
  }

  void _init() {
    _updateDate();
    _fetchWeather();
    
    // Timer to update date (every minute to catch midnight)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newDate = _getFormattedDate();
      if (newDate != state.formattedDate) {
        state = state.copyWith(formattedDate: newDate);
      }
    });
  }

  void _updateDate() {
    state = state.copyWith(formattedDate: _getFormattedDate());
  }

  Future<void> _fetchWeather() async {
    state = state.copyWith(isLoading: true);
    
    try {
      Position? position;
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }

      // Default location (São Paulo) if GPS fails or denied
      double lat = position?.latitude ?? -23.5505;
      double lon = position?.longitude ?? -46.6333;

      final temp = await _weatherService.fetchTemperature(lat, lon);
      
      if (temp != null) {
        state = state.copyWith(
          temperature: '${temp.round()}°C',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Weather Provider Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
