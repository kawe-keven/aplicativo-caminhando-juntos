import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  AccessibilityNotifier() : super(AccessibilityState());

  Future<void> speak(String text) async {
    if (!state.voiceReadingEnabled) return;
    await _tts.speak(text);
  }

  void updateFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
  }

  void toggleVoiceReading(bool value) {
    state = state.copyWith(voiceReadingEnabled: value);
  }

  void toggleSoundAlerts(bool value) {
    state = state.copyWith(soundAlertsEnabled: value);
  }

  void toggleMetaVibration(bool value) {
    state = state.copyWith(metaVibrationEnabled: value);
  }

  void toggleHighContrast(bool value) {
    state = state.copyWith(highContrastEnabled: value);
  }

  void reset() {
    state = AccessibilityState();
  }
}
