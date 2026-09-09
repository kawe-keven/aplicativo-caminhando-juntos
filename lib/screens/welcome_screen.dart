import 'package:cached_network_image/cached_network_image.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/benefit_card_widget.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);
    final accessibilityNotifier = ref.read(accessibilityProvider.notifier);

    const String welcomeText =
        "Bem-vindo ao CaminhaJuntos! Caminhe no seu ritmo, ganhe pontos diários e troque por recompensas incríveis nos seus jogos favoritos. Primeiro benefício: Cuide da sua saúde com caminhadas leves. Segundo: Ganhe moedas com cada passo. Terceiro: Aplicativo cem por cento seguro. Toque no grande botão verde para começar agora!";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Header & Logo
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_walk,
                          size: 54,
                          color: AppTheme.onPrimary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppTheme.tertiaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 22,
                            color: AppTheme.onTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "CAMINHAJUNTOS",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bem-vindo ao CaminhaJuntos!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Caminhe no seu ritmo, ganhe pontos diários e troque por recompensas incríveis nos seus jogos favoritos!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuDMMQ5Xn67waHPsCmcPjwiBWhxFO8OK0kIEcnhC6a7WR_mQkz3S5z0OLaq32NGcjY7mJ4XRpgCa_U-uaxSNuxg2J49u8VhED--ProMmi-ihloXLDp_CDPz6hsZM0QcALMxbNZ94aYqdUgZQqux7D7pHxKVRWDWPQ_ujx3cnqbUydw5r9SYlKenl4gAHwvbWgiXU8W3PDdOyX80_tApOIiKiEubc9cdwUNiIVFHijRqEbYxXkXbpAiRk",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 200, color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 50),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Benefits
              const BenefitCardWidget(
                icon: Icons.directions_walk,
                title: "Cuide da sua saúde",
                description: "Caminhadas leves no seu próprio tempo e sem pressa.",
                iconBackgroundColor: Color(0xFFB1F1C5),
                iconColor: AppTheme.primaryColor,
              ),
              const BenefitCardWidget(
                icon: Icons.monetization_on,
                title: "Ganhe Moedas",
                description: "Cada passo vira pontos para você trocar por vantagens.",
                iconBackgroundColor: Color(0xFFFFDCC3),
                iconColor: AppTheme.tertiaryColor,
              ),
              const BenefitCardWidget(
                icon: Icons.verified_user,
                title: "100% Seguro",
                description: "Seus dados e contatos de emergência sempre protegidos.",
                iconBackgroundColor: Color(0xFFCAE6FF),
                iconColor: AppTheme.secondaryColor,
              ),

              const SizedBox(height: 32),

              // CTAs
              BotaoGrandeWidget(
                text: "Começar Agora",
                icon: Icons.arrow_forward,
                onPressed: () {
                  context.push('/registration');
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => accessibilityNotifier.speak(welcomeText),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        accessibility.isSpeaking ? Icons.pause_circle : Icons.volume_up,
                        color: AppTheme.secondaryColor,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          accessibility.isSpeaking
                              ? "Ouvindo agora... Toque para pausar a voz"
                              : "Precisa de ajuda? Toque aqui para ouvir as instruções em áudio",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
