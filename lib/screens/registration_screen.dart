import 'package:caminhandojuntos/models/user_model.dart';
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

  final List<Map<String, TextEditingController>> _contacts = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
    }
  ];

  final List<MaskTextInputFormatter> _phoneFormatters = [
    MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    )
  ];

  @override
  void dispose() {
    for (var c in _contacts) {
      c['name']!.dispose();
      c['phone']!.dispose();
    }
    super.dispose();
  }

  void _addContactField() {
    if (_contacts.length < 3) {
      setState(() {
        _contacts.add({
          'name': TextEditingController(),
          'phone': TextEditingController(),
        });
        _phoneFormatters.add(
          MaskTextInputFormatter(
            mask: '(##) #####-####',
            filter: {"#": RegExp(r'[0-9]')},
            type: MaskAutoCompletionType.lazy,
          ),
        );
      });
    }
  }

  void _removeContactField(int index) {
    if (_contacts.length > 1) {
      setState(() {
        _contacts[index]['name']!.dispose();
        _contacts[index]['phone']!.dispose();
        _contacts.removeAt(index);
        _phoneFormatters.removeAt(index);
      });
    }
  }

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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_walk, color: AppTheme.primaryContainer, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Passo 1 de 2",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                          Expanded(
                            child: Text(
                              "Leva apenas 1 minuto para começar.",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
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
                const SizedBox(height: 24),

                // 3. Contatos de Emergência (Até 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Contatos de Emergência (${_contacts.length}/3)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (_contacts.length < 3)
                      TextButton.icon(
                        onPressed: _addContactField,
                        icon: const Icon(Icons.add),
                        label: const Text("Adicionar outro"),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                ...List.generate(_contacts.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Contato ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (_contacts.length > 1)
                              IconButton(
                                onPressed: () => _removeContactField(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contacts[index]['name'],
                          decoration: InputDecoration(
                            labelText: "Nome do Contato",
                            hintText: "Ex: Filha Ana",
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: index == 0 ? (value) => (value == null || value.trim().isEmpty) ? "Digite o nome do contato principal." : null : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contacts[index]['phone'],
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _phoneFormatters[index],
                          ],
                          decoration: InputDecoration(
                            labelText: "Número de Telefone",
                            hintText: "(11) 98765-4321",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: index == 0 ? (value) {
                            final unmasked = _phoneFormatters[index].getUnmaskedText();
                            if (unmasked.isEmpty) return "Digite o telefone principal.";
                            if (unmasked.length < 10) return "Número incompleto.";
                            return null;
                          } : null,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Actions
                BotaoGrandeWidget(
                  text: _isSuccess ? "Tudo Certo!" : "Continuar",
                  icon: _isSuccess ? Icons.check_circle : Icons.arrow_forward,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSuccess = true);

                      final emergencyContacts = _contacts.map((c) {
                        return EmergencyContact(
                          name: c['name']!.text.trim(),
                          phone: c['phone']!.text.replaceAll(RegExp(r'\D'), ''),
                        );
                      }).where((c) => c.name.isNotEmpty && c.phone.isNotEmpty).toList();

                      notifier.updateEmergencyContacts(emergencyContacts);
                      
                      final router = GoRouter.of(context);
                      await notifier.completeRegistration();
                      if (!mounted) return;
                      
                      router.go('/dashboard');
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
