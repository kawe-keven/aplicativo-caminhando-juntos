import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final String contactName;
  final String contactPhone;

  const EmergencyAlertScreen({
    super.key,
    required this.contactName,
    required this.contactPhone,
  });

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startEmergencyActions();
  }

  Future<void> _startEmergencyActions() async {
    // Configura o áudio para tocar mesmo em modo silencioso (se permitido pelo SO)
    try {
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.defaultToSpeaker},
        ),
      ));

      // 1. Iniciar Alarme Sonoro
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/emergency_alarm.mp3'));
    } catch (e) {
      debugPrint("Erro ao configurar áudio: $e");
    }

    // 2. Iniciar Ligação Direta (Android)
    try {
      final bool? res = await FlutterPhoneDirectCaller.callNumber(widget.contactPhone);
      
      // Fallback: Se a ligação direta falhar (permissão negada ou outro erro), abre o discador
      if (res == null || !res) {
        final Uri telUri = Uri.parse('tel:${widget.contactPhone}');
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        }
      }
    } catch (e) {
      debugPrint("Erro ao iniciar chamada: $e");
    }
  }

  Future<void> _cancelEmergency() async {
    await _audioPlayer.stop();
    if (mounted) context.go('/dashboard');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.red, Colors.red[900]!],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone Pulsante
              ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                "EMERGÊNCIA ATIVA",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "LIGANDO PARA:\n${widget.contactName.toUpperCase()}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Spacer(),
              // Botão Cancelar Gigante
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: ElevatedButton.icon(
                  onPressed: _cancelEmergency,
                  icon: const Icon(Icons.close, size: 40),
                  label: const Text("CANCELAR AGORA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    minimumSize: const Size(double.infinity, 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
