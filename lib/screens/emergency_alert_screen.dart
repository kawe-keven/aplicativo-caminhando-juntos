import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final List<Map<String, String>> contacts;

  const EmergencyAlertScreen({
    super.key,
    required this.contacts,
  });

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  int _activeContactIndex = 0;

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
    // 1. Iniciar Alarme Sonoro
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

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/emergency_alarm.mp3'));
    } catch (e) {
      debugPrint("Erro ao configurar áudio: $e");
    }

    // 2. Iniciar Chamada e Envio de SMS com Localização
    if (widget.contacts.isNotEmpty) {
      _callContact(widget.contacts[_activeContactIndex]['phone']!);
      _sendLocationSms();
    }
  }

  Future<void> _callContact(String phone) async {
    try {
      final bool? res = await FlutterPhoneDirectCaller.callNumber(phone);
      if (res == null || !res) {
        final Uri telUri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        }
      }
    } catch (e) {
      debugPrint("Erro ao iniciar chamada: $e");
    }
  }

  Future<void> _sendLocationSms() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint("Erro ao obter GPS para SMS: $e");
      }

      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;
      final mapsLink = "https://maps.google.com/?q=$lat,$lng";
      final message = Uri.encodeComponent("SOS! Preciso de ajuda urgente. Minha localização atual: $mapsLink");

      for (var contact in widget.contacts) {
        final phone = contact['phone'];
        if (phone != null && phone.isNotEmpty) {
          final smsUri = Uri.parse('sms:$phone?body=$message');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao enviar SMS de localização: $e");
    }
  }

  Future<void> _cancelEmergency() async {
    await _audioPlayer.stop();
    if (mounted) context.go('/dashboard');
  }

  void _switchContact(int index) {
    setState(() {
      _activeContactIndex = index;
    });
    if (widget.contacts.length > index) {
      _callContact(widget.contacts[index]['phone']!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeContact = widget.contacts.isNotEmpty ? widget.contacts[_activeContactIndex] : {'name': 'Contato', 'phone': ''};

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "EMERGÊNCIA ATIVA",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "LIGANDO PARA:\n${(activeContact['name'] ?? '').toUpperCase()}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Lista de múltiplos contatos para alternar rapidamente
                if (widget.contacts.length > 1) ...[
                  const Text(
                    "Outros contatos de emergência:",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(widget.contacts.length, (index) {
                      final contact = widget.contacts[index];
                      final isSelected = index == _activeContactIndex;
                      return ElevatedButton.icon(
                        onPressed: () => _switchContact(index),
                        icon: Icon(Icons.phone, color: isSelected ? Colors.red[900] : Colors.white),
                        label: Text(contact['name'] ?? 'Contato ${index + 1}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.white : Colors.white24,
                          foregroundColor: isSelected ? Colors.red[900] : Colors.white,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],

                // Botão Cancelar Gigante
                ElevatedButton.icon(
                  onPressed: _cancelEmergency,
                  icon: const Icon(Icons.close, size: 36),
                  label: const Text("CANCELAR AGORA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    minimumSize: const Size(double.infinity, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
