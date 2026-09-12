import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um widget que envolve qualquer conteúdo e o torna "falante".
/// Se a acessibilidade de voz estiver ligada, ele lerá o [text] ao ser tocado
/// ou automaticamente ao carregar, se [announceOnLoad] for true.
class Speakable extends ConsumerStatefulWidget {
  final Widget child;
  final String text;
  final bool announceOnLoad;
  final bool useLongPress;

  const Speakable({
    super.key,
    required this.child,
    required this.text,
    this.announceOnLoad = false,
    this.useLongPress = false,
  });

  @override
  ConsumerState<Speakable> createState() => _SpeakableState();
}

class _SpeakableState extends ConsumerState<Speakable> {
  @override
  void initState() {
    super.initState();
    if (widget.announceOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerSpeech();
      });
    }
  }

  void _triggerSpeech() {
    ref.read(accessibilityProvider.notifier).speak(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    final isVoiceEnabled = ref.watch(accessibilityProvider).voiceReadingEnabled;

    if (!isVoiceEnabled) return widget.child;

    return GestureDetector(
      onTap: widget.useLongPress ? null : _triggerSpeech,
      onLongPress: widget.useLongPress ? _triggerSpeech : null,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: widget.text,
        child: widget.child,
      ),
    );
  }
}
