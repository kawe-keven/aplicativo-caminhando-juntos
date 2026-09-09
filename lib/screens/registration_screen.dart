import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/age_selector_widget.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:caminhandojuntos/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSuccess = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de Progresso
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_walk, color: AppTheme.primaryContainer, size: 20),
                          SizedBox(width: 8),
                          Text("Passo 1 de 2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(width: 40, height: 12, decoration: BoxDecoration(color: AppTheme.primaryContainer, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(width: 4),
                        Container(width: 40, height: 12, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card de Boas-vindas
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: AppTheme.secondaryContainer, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_note, color: AppTheme.secondaryColor, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text("Vamos nos conhecer!", style: Theme.of(context).textTheme.headlineMedium)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.timer, color: AppTheme.primaryContainer, size: 20),
                          SizedBox(width: 4),
                          Text("Leva apenas 1 minuto para começar.", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Seu Nome
                CustomTextField(
                  label: "Seu Nome ou Apelido",
                  hint: "Ex: Seu Antônio ou Dona Maria",
                  description: "Como você gosta de ser chamado?",
                  icon: Icons.person,
                  onChanged: notifier.updateName,
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Por favor, digite seu nome." : null,
                ),
                const SizedBox(height: 16),

                // 2. Sua Idade
                AgeSelectorWidget(
                  age: user.age,
                  onAgeChanged: notifier.updateAge,
                ),
                const SizedBox(height: 16),

                // 3. Nome do Contato
                CustomTextField(
                  label: "Nome do Contato",
                  hint: "Ex: Filha Ana",
                  description: "Qual o nome da pessoa de confiança?",
                  icon: Icons.person_outline,
                  onChanged: notifier.updateEmergencyContactName,
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Por favor, digite o nome do contato." : null,
                ),
                const SizedBox(height: 16),

                // 4. Número de Emergência
                CustomTextField(
                  label: "Número de emergência",
                  hint: "(11) 98765-4321",
                  description: "Número para ligar em qualquer imprevisto.",
                  icon: Icons.phone,
                  iconColor: AppTheme.errorColor,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _phoneFormatter,
                  ],
                  onChanged: (value) => notifier.updateEmergencyContactPhone(_phoneFormatter.getUnmaskedText()),
                  validator: (value) {
                    final unmasked = _phoneFormatter.getUnmaskedText();
                    if (unmasked.isEmpty) return "Por favor, digite o número.";
                    if (unmasked.length < 10) return "Número incompleto (mínimo 10 dígitos).";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Actions
                BotaoGrandeWidget(
                  text: _isSuccess ? "Tudo Certo!" : "Continuar",
                  icon: _isSuccess ? Icons.check_circle : Icons.arrow_forward,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSuccess = true);
                      
                      // Requisito 4: Salvar o usuário localmente antes de navegar
                      await notifier.completeRegistration();
                      if (!mounted) return;
                      
                      final router = GoRouter.of(context);
                      Future.delayed(const Duration(seconds: 1), () {
                        if (!mounted) return;
                        router.go('/dashboard');
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Voltar ao início", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.onSurface),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
