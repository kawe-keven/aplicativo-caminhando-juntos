import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessibilityProvider);
    final notifier = ref.read(accessibilityProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 30),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                "CaminhaJuntos",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "Acessibilidade",
                style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Header
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.accessibility_new, color: AppTheme.secondaryColor, size: 24),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Conforto Adaptado",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Configurações de Acessibilidade ⚙️",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Personalize o aplicativo para o seu conforto visual e sonoro.",
              style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant),
            ),

            const SizedBox(height: 24),

            // Hero Banner Otimizado
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset(
                    "assets/images/logo_launcher.png",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppTheme.primaryColor.withValues(alpha: 0.8), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.sentiment_satisfied, color: Color(0xFFB1F1C5), size: 28),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Caminhadas mais confortáveis e seguras para os seus olhos",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Font Size
            _SettingsSection(
              icon: Icons.format_size,
              title: "Tamanho das Letras (Fontes)",
              children: [
                const Text("Escolha o tamanho que fica mais nítido para ler:", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                _FontSizeOption(
                  label: "Normal (18px)",
                  tag: "Padrão",
                  isSelected: state.fontScale == 1.0,
                  onTap: () => notifier.updateFontScale(1.0),
                ),
                const SizedBox(height: 12),
                _FontSizeOption(
                  label: "Grande (22px)",
                  tag: "Recomendado",
                  isSelected: state.fontScale == 1.2,
                  onTap: () => notifier.updateFontScale(1.2),
                ),
                const SizedBox(height: 12),
                _FontSizeOption(
                  label: "Extra Grande (26px)",
                  tag: "Máximo",
                  isSelected: state.fontScale == 1.4,
                  onTap: () => notifier.updateFontScale(1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility, color: AppTheme.secondaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "DEMONSTRAÇÃO AO VIVO:",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Texto de teste: As letras ficarão deste tamanho na tela.",
                        style: TextStyle(fontSize: 18 * state.fontScale, fontWeight: FontWeight.w500, color: AppTheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 2: Voice & Sound
            _SettingsSection(
              icon: Icons.hearing,
              title: "Ajuda por Voz e Sons",
              iconColor: AppTheme.secondaryColor,
              children: [
                _ToggleItem(
                  label: "Ativar Leitura de Telas por Voz 🔊",
                  subtitle: "Lê em voz alta as instruções ao tocar em qualquer texto.",
                  value: state.voiceReadingEnabled,
                  onChanged: notifier.toggleVoiceReading,
                ),
                const Divider(height: 32),
                _ToggleItem(
                  label: "Avisos Sonoros a cada 1 km 🔔",
                  subtitle: "Toque musical alegre que incentiva o seu progresso.",
                  value: state.soundAlertsEnabled,
                  onChanged: notifier.toggleSoundAlerts,
                ),
                const Divider(height: 32),
                _ToggleItem(
                  label: "Vibração da Meta 📳",
                  subtitle: "O celular vibra suavemente quando você alcança o objetivo.",
                  value: state.metaVibrationEnabled,
                  onChanged: notifier.toggleMetaVibration,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 3: Contrast
            _SettingsSection(
              icon: Icons.contrast,
              title: "Modo de Alto Contraste",
              iconColor: AppTheme.tertiaryColor,
              children: [
                _ToggleItem(
                  label: "Cores com Contraste Máximo 👁️",
                  subtitle: "Fortalece a separação das cores para enxergar melhor no sol.",
                  value: state.highContrastEnabled,
                  onChanged: notifier.toggleHighContrast,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Volunteer help Otimizado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      "assets/images/logo_launcher.png",
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Precisa de Ajuda?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Nossos voluntários podem configurar tudo para você por telefone.", style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer Actions
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Preferências salvas com sucesso!"),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
                context.pop();
              },
              icon: const Icon(Icons.check_circle, size: 28),
              label: const Text("Salvar Preferências ✓"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 72),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: notifier.reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Restaurar Padrão", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color iconColor;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  final String label;
  final String tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSizeOption({
    required this.label,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : const Color(0xFFF1F3FF),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white60,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      size: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
