import 'package:caminhandojuntos/models/user_model.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditContactModal(BuildContext context, WidgetRef ref, bool isHighContrast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditContactModal(ref: ref, isHighContrast: isHighContrast),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context, isHighContrast),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: user.name, age: user.age, isHighContrast: isHighContrast),
                const SizedBox(height: 24),
                _StatsGrid(progress: dashboardState.progress, isHighContrast: isHighContrast),
                const SizedBox(height: 24),
                _SecurityCard(contacts: user.emergencyContacts, onEdit: () => _showEditContactModal(context, ref, isHighContrast), isHighContrast: isHighContrast),
                const SizedBox(height: 24),
                _ShortcutTile(
                  icon: Icons.settings,
                  title: "Configurações",
                  onTap: () => context.push('/accessibility'),
                  isHighContrast: isHighContrast,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHighContrast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(
          color: isHighContrast ? Colors.white : Colors.grey.withValues(alpha: 0.2),
          width: isHighContrast ? 2 : 1,
        )),
      ),
      child: Row(
        children: [
          Text("Perfil", style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
          )),
        ],
      ),
    );
  }
}

class _EditContactModal extends StatefulWidget {
  final WidgetRef ref;
  final bool isHighContrast;
  const _EditContactModal({required this.ref, required this.isHighContrast});

  @override
  State<_EditContactModal> createState() => _EditContactModalState();
}

class _EditContactModalState extends State<_EditContactModal> {
  late List<Map<String, TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(userProvider);
    _controllers = user.emergencyContacts.map((c) => {
      'name': TextEditingController(text: c.name),
      'phone': TextEditingController(text: c.phone),
    }).toList();

    if (_controllers.isEmpty) {
      _controllers.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c['name']!.dispose();
      c['phone']!.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    if (_controllers.length < 3) {
      setState(() {
        _controllers.add({
          'name': TextEditingController(),
          'phone': TextEditingController(),
        });
      });
    }
  }

  void _removeContact(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index]['name']!.dispose();
        _controllers[index]['phone']!.dispose();
        _controllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHC = widget.isHighContrast;
    return Container(
      decoration: BoxDecoration(
        color: isHC ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isHC ? const Border(top: BorderSide(color: Colors.white, width: 2), left: BorderSide(color: Colors.white, width: 2), right: BorderSide(color: Colors.white, width: 2)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Contatos de Segurança (${_controllers.length}/3)", style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: isHC ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  )),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: isHC ? Colors.white : null)),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_controllers.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHC ? Colors.grey[900] : const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Contato ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isHC ? Colors.white : Colors.black)),
                          if (_controllers.length > 1)
                            IconButton(onPressed: () => _removeContact(index), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controllers[index]['name'],
                        style: TextStyle(color: isHC ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Nome",
                          filled: true,
                          fillColor: isHC ? Colors.black : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controllers[index]['phone'],
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isHC ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Telefone",
                          filled: true,
                          fillColor: isHC ? Colors.black : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_controllers.length < 3)
                Center(
                  child: TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text("Adicionar outro contato"),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHC ? Colors.white : Theme.of(context).colorScheme.primary,
                  foregroundColor: isHC ? Colors.black : Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isHC ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                  ),
                ),
                onPressed: () {
                  final contacts = _controllers.map((c) {
                    return EmergencyContact(
                      name: c['name']!.text.trim(),
                      phone: c['phone']!.text.trim(),
                    );
                  }).where((c) => c.name.isNotEmpty && c.phone.isNotEmpty).toList();

                  widget.ref.read(userProvider.notifier).updateEmergencyContacts(contacts);
                  widget.ref.read(userProvider.notifier).updateUser();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contatos salvos com sucesso!")));
                },
                child: const Text("Salvar Contatos"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final int age;
  final bool isHighContrast;
  const _Header({required this.name, required this.age, required this.isHighContrast});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isHighContrast ? Colors.white : AppTheme.primaryColor,
            child: Icon(Icons.person, size: 50, color: isHighContrast ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 16),
          Text(name.isEmpty ? "Seu Antônio" : name, style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
          )),
          Text("$age anos", style: TextStyle(
            fontSize: 18,
            color: isHighContrast ? Colors.white70 : Colors.grey,
          )),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final UserProgress progress;
  final bool isHighContrast;
  const _StatsGrid({required this.progress, required this.isHighContrast});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Passos",
            value: progress.steps.toString(),
            icon: Icons.directions_walk,
            isHighContrast: isHighContrast,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: "Moedas",
            value: progress.coins.toString(),
            icon: Icons.monetization_on,
            isHighContrast: isHighContrast,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighContrast;
  const _StatCard({required this.label, required this.value, required this.icon, required this.isHighContrast});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isHighContrast ? Colors.white : AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
          )),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: isHighContrast ? Colors.white70 : Colors.grey,
          )),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final VoidCallback onEdit;
  final bool isHighContrast;
  const _SecurityCard({required this.contacts, required this.onEdit, required this.isHighContrast});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Contatos de Segurança",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(onPressed: onEdit, icon: Icon(Icons.edit, size: 20, color: isHighContrast ? Colors.white : null)),
            ],
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
            Text("Nenhum contato cadastrado", style: TextStyle(color: isHighContrast ? Colors.white70 : Colors.grey, fontSize: 16))
          else
            ...contacts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "• ${c.name}: ${c.phone}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: isHighContrast ? Colors.white : AppTheme.secondaryColor,
                  fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isHighContrast;
  const _ShortcutTile({required this.icon, required this.title, required this.onTap, required this.isHighContrast});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isHighContrast ? Colors.white : AppTheme.primaryColor),
      title: Text(title, style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
      )),
      trailing: Icon(Icons.chevron_right, color: isHighContrast ? Colors.white : null),
      onTap: onTap,
      tileColor: isHighContrast ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
      ),
    );
  }
}
