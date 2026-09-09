import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgeSelectorWidget extends StatefulWidget {
  final int age;
  final Function(int) onAgeChanged;

  const AgeSelectorWidget({
    super.key,
    required this.age,
    required this.onAgeChanged,
  });

  @override
  State<AgeSelectorWidget> createState() => _AgeSelectorWidgetState();
}

class _AgeSelectorWidgetState extends State<AgeSelectorWidget> {
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.age.toString());
  }

  @override
  void didUpdateWidget(AgeSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.age != int.tryParse(_ageController.text)) {
      _ageController.text = widget.age.toString();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                "Sua Idade",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Digite ou ajuste nos botões grandes abaixo:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AgeButton(
                  icon: Icons.remove,
                  onPressed: () => widget.onAgeChanged(widget.age - 1),
                  label: "Diminuir idade",
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: (value) {
                            final newAge = int.tryParse(value);
                            if (newAge != null) {
                              widget.onAgeChanged(newAge);
                            }
                          },
                        ),
                      ),
                      Text(
                        "anos de vitalidade",
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                _AgeButton(
                  icon: Icons.add,
                  onPressed: () => widget.onAgeChanged(widget.age + 1),
                  label: "Aumentar idade",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const _AgeButton({
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            size: 40,
            color: AppTheme.secondaryColor,
          ),
        ),
      ),
    );
  }
}
