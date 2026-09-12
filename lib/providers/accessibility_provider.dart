import 'package:flutter/foundation.dart';
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

  AccessibilityNotifier() : super(AccessibilityState()) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("pt-BR");
    // Velocidade um pouco reduzida para melhor compreensão de idosos
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

  /// Fala o texto fornecido se a leitura de voz estiver ativada.
  Future<void> speak(String text) async {
    if (!state.voiceReadingEnabled || text.isEmpty) return;
    
    // Interrompe qualquer fala anterior antes de começar a nova
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Interrompe a fala atual.
  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  void updateFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
  }

  void toggleVoiceReading(bool value) {
    state = state.copyWith(voiceReadingEnabled: value);
    if (!value) stop();
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
    stop();
    state = AccessibilityState();
  }
}
