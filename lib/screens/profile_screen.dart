import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditContactModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final nameController = TextEditingController(text: user.emergencyContactName);
    final phoneController = TextEditingController(text: user.emergencyContactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Editar Contato Seguro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Nome do Familiar de Confiança:", style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Número com DDD:", style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).updateEmergencyContactName(nameController.text);
                ref.read(userProvider.notifier).updateEmergencyContactPhone(phoneController.text);
                ref.read(userProvider.notifier).updateUser();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contato salvo com sucesso!")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 64),
              ),
              child: const Text("Salvar Contato"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return Material(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Cabeçalho Customizado
          _buildHeader(context),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: user.name, age: user.age),
                const SizedBox(height: 24),
                _StatsGrid(progress: dashboardState.progress),
                const SizedBox(height: 24),
                _SecurityCard(contactName: user.emergencyContactName, contactPhone: user.emergencyContactPhone, onEdit: () => _showEditContactModal(context, ref)),
                const SizedBox(height: 24),
                _ShortcutTile(
                  icon: Icons.settings,
                  title: "Configurações",
                  onTap: () => context.push('/accessibility'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      color: Colors.white,
      child: const Row(
        children: [
          Text("Perfil", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final int age;
  const _Header({required this.name, required this.age});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 16),
          Text(name.isEmpty ? "Seu Antônio" : name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("$age anos", style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final UserProgress progress;
  const _StatsGrid({required this.progress});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(label: "Passos", value: progress.steps.toString(), icon: Icons.directions_walk),
        _StatCard(label: "Moedas", value: progress.coins.toString(), icon: Icons.monetization_on),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final String contactName;
  final String contactPhone;
  final VoidCallback onEdit;
  const _SecurityCard({required this.contactName, required this.contactPhone, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Contato de Segurança", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(contactName.isEmpty ? "Não cadastrado" : "$contactName: $contactPhone", style: const TextStyle(fontSize: 18, color: AppTheme.secondaryColor)),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ShortcutTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
