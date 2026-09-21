import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
  return AccessibilityNotifier();
});

class AccessibilityState {
  final bool isSpeaking;
  final double fontScale;
  final bool voiceReadingEnabled;
  final bool soundAlertsEnabled;
  final bool metaVibrationEnabled;
  final bool highContrastEnabled;

  AccessibilityState({
    this.isSpeaking = false,
    this.fontScale = 1.2,
    this.voiceReadingEnabled = true,
    this.soundAlertsEnabled = true,
    this.metaVibrationEnabled = true,
    this.highContrastEnabled = false,
  });

  AccessibilityState copyWith({
    bool? isSpeaking,
    double? fontScale,
    bool? voiceReadingEnabled,
    bool? soundAlertsEnabled,
    bool? metaVibrationEnabled,
    bool? highContrastEnabled,
  }) {
    return AccessibilityState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      fontScale: fontScale ?? this.fontScale,
      voiceReadingEnabled: voiceReadingEnabled ?? this.voiceReadingEnabled,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      metaVibrationEnabled: metaVibrationEnabled ?? this.metaVibrationEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
    );
  }
}

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  final FlutterTts _tts = FlutterTts();
  late SharedPreferences _prefs;

  AccessibilityNotifier() : super(AccessibilityState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
    await _initTts();
  }

  void _loadPreferences() {
    state = state.copyWith(
      fontScale: _prefs.getDouble('fontScale') ?? 1.2,
      voiceReadingEnabled: _prefs.getBool('voiceReadingEnabled') ?? true,
      soundAlertsEnabled: _prefs.getBool('soundAlertsEnabled') ?? true,
      metaVibrationEnabled: _prefs.getBool('metaVibrationEnabled') ?? true,
      highContrastEnabled: _prefs.getBool('highContrastEnabled') ?? false,
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("pt-BR");
    await _tts.setSpeechRate(0.45); 
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });

    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });

    _tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> speak(String text) async {
    if (!state.voiceReadingEnabled || text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  void updateFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    _prefs.setDouble('fontScale', scale);
  }

  void toggleVoiceReading(bool value) {
    state = state.copyWith(voiceReadingEnabled: value);
    _prefs.setBool('voiceReadingEnabled', value);
    if (!value) stop();
  }

  void toggleSoundAlerts(bool value) {
    state = state.copyWith(soundAlertsEnabled: value);
    _prefs.setBool('soundAlertsEnabled', value);
  }

  void toggleMetaVibration(bool value) {
    state = state.copyWith(metaVibrationEnabled: value);
    _prefs.setBool('metaVibrationEnabled', value);
  }

  void toggleHighContrast(bool value) {
    state = state.copyWith(highContrastEnabled: value);
    _prefs.setBool('highContrastEnabled', value);
  }

  void reset() {
    stop();
    state = AccessibilityState();
    _prefs.clear();
  }
}
