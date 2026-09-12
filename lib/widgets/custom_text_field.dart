import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.description,
    required this.icon,
    this.iconColor = AppTheme.primaryColor,
    this.validator,
    this.onChanged,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isHighContrast ? Colors.yellow : iconColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: isHighContrast ? const TextStyle(color: Colors.white60) : null,
              filled: true,
              fillColor: isHighContrast ? Colors.black : const Color(0xFFF1F3FF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isHighContrast ? const BorderSide(color: Colors.white38) : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isHighContrast ? Colors.yellow : AppTheme.primaryColor, 
                  width: 2,
                ),
              ),
              errorStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
