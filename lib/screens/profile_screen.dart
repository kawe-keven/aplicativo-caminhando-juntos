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
                _SecurityCard(contactName: user.emergencyContactName, contactPhone: user.emergencyContactPhone, onEdit: () => _showEditContactModal(context, ref, isHighContrast), isHighContrast: isHighContrast),
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(userProvider);
    _nameController = TextEditingController(text: user.emergencyContactName);
    _phoneController = TextEditingController(text: user.emergencyContactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Editar Contato Seguro", style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: isHC ? Colors.white : Theme.of(context).colorScheme.onSurface,
                )),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: isHC ? Colors.white : null)),
              ],
            ),
            const SizedBox(height: 16),
            Text("Nome do Familiar de Confiança:", style: TextStyle(fontSize: 16, color: isHC ? Colors.white70 : AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: isHC ? Colors.white : Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: isHC ? Colors.black : const Color(0xFFF1F3FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isHC ? const BorderSide(color: Colors.white38) : BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isHC ? const BorderSide(color: Colors.white38) : BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isHC ? Colors.yellow : AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            Text("Número com DDD:", style: TextStyle(fontSize: 16, color: isHC ? Colors.white70 : AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: isHC ? Colors.white : Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: isHC ? Colors.black : const Color(0xFFF1F3FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isHC ? const BorderSide(color: Colors.white38) : BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isHC ? const BorderSide(color: Colors.white38) : BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isHC ? Colors.yellow : AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHC ? Colors.white : Theme.of(context).colorScheme.primary,
                foregroundColor: isHC ? Colors.black : Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isHC ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                ),
              ),
              onPressed: () {
                widget.ref.read(userProvider.notifier).updateEmergencyContactName(_nameController.text);
                widget.ref.read(userProvider.notifier).updateEmergencyContactPhone(_phoneController.text);
                widget.ref.read(userProvider.notifier).updateUser();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contato salvo com sucesso!")));
              },
              child: const Text("Salvar Contato"),
            ),
          ],
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
  final String contactName;
  final String contactPhone;
  final VoidCallback onEdit;
  final bool isHighContrast;
  const _SecurityCard({required this.contactName, required this.contactPhone, required this.onEdit, required this.isHighContrast});
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
                  "Contato de Segurança",
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
          const SizedBox(height: 8),
          Text(
            contactName.isEmpty ? "Não cadastrado" : "$contactName: $contactPhone",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              color: isHighContrast ? Colors.white : AppTheme.secondaryColor,
              fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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

