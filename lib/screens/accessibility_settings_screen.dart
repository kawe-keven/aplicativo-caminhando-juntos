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
    final isHighContrast = state.highContrastEnabled;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                "CaminhaJuntos",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "Acessibilidade",
                style: TextStyle(
                  fontSize: 14, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        shape: isHighContrast ? const Border(bottom: BorderSide(color: Colors.white, width: 2)) : null,
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
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.yellow : AppTheme.secondaryContainer, 
                  borderRadius: BorderRadius.circular(20),
                  border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.accessibility_new, 
                      color: isHighContrast ? Colors.black : AppTheme.secondaryColor, 
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Conforto Adaptado", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isHighContrast ? Colors.black : AppTheme.secondaryColor,
                        ),
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
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary, 
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Personalize o aplicativo para o seu conforto visual e sonoro.",
              style: TextStyle(
                fontSize: 18, 
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
                        colors: [
                          isHighContrast 
                            ? Colors.black.withValues(alpha: 0.9) 
                            : AppTheme.primaryColor.withValues(alpha: 0.8), 
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sentiment_satisfied, 
                          color: isHighContrast ? Colors.yellow : const Color(0xFFB1F1C5), 
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
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
              isHighContrast: isHighContrast,
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
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.black : AppTheme.secondaryContainer, 
                    borderRadius: BorderRadius.circular(16),
                    border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility, 
                            color: isHighContrast ? Colors.yellow : AppTheme.secondaryColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "DEMONSTRAÇÃO AO VIVO:",
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: isHighContrast ? Colors.yellow : AppTheme.secondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Texto de teste: As letras ficarão deste tamanho na tela.",
                        style: TextStyle(
                          fontSize: 18 * state.fontScale, 
                          fontWeight: isHighContrast ? FontWeight.bold : FontWeight.w500, 
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
              iconColor: isHighContrast ? Colors.cyanAccent : AppTheme.secondaryColor,
              isHighContrast: isHighContrast,
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
              iconColor: isHighContrast ? Colors.yellow : AppTheme.tertiaryColor,
              isHighContrast: isHighContrast,
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
              decoration: BoxDecoration(
                color: isHighContrast ? Colors.black : const Color(0xFFF1F3FF), 
                borderRadius: BorderRadius.circular(16),
                border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
              ),
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
                  SnackBar(
                    content: const Text("Preferências salvas com sucesso!"),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
                context.pop();
              },
              icon: const Icon(Icons.check_circle, size: 28),
              label: const Text("Salvar Preferências ✓"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                ),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: notifier.reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Restaurar Padrão", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
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
  final bool isHighContrast;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor = AppTheme.primaryColor,
    this.isHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isHighContrast ? Colors.yellow : AppTheme.primaryContainer) 
            : (isHighContrast ? Colors.black : const Color(0xFFF1F3FF)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isHighContrast ? Colors.white : AppTheme.primaryColor) : (isHighContrast ? Colors.white38 : Colors.transparent), 
            width: 2,
          ),
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
                      color: isSelected ? (isHighContrast ? Colors.black : Colors.white) : Colors.white60,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: isSelected ? (isHighContrast ? Colors.yellow : AppTheme.primaryColor) : Colors.transparent,
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
                        color: isSelected 
                          ? (isHighContrast ? Colors.black : Colors.white) 
                          : (isHighContrast ? Colors.white : AppTheme.onSurface),
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
                color: isSelected ? (isHighContrast ? Colors.black : AppTheme.primaryColor) : (isHighContrast ? Colors.white12 : Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? (isHighContrast ? Colors.yellow : Colors.white) : AppTheme.onSurfaceVariant,
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: TextStyle(
                  fontSize: 14, 
                  color: isHighContrast ? Colors.white70 : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
          thumbColor: isHighContrast 
            ? WidgetStateProperty.resolveWith((states) => isHighContrast ? Colors.black : null)
            : null,
        ),
      ],
    );
  }
}
