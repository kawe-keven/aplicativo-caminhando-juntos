import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Bússola rotativa que acompanha o heading do dispositivo.
/// Suaviza a rotação com AnimatedRotation e evita "pulos" de 360°.
class CompassArrow extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;

  const CompassArrow({
    super.key,
    this.size = 28,
    this.color = Colors.blueAccent,
    this.icon = Icons.navigation,
  });

  @override
  State<CompassArrow> createState() => _CompassArrowState();
}

class _CompassArrowState extends State<CompassArrow> {
  double _turns = 0;
  double? _lastHeading;

  /// Converte heading (0-360°) em turns, sempre pelo menor caminho.
  /// Evita que a seta gire ~360° ao cruzar o ponto 0/360.
  void _updateHeading(double heading) {
    // Converte para -180..180 (menor caminho)
    double delta = heading - (_lastHeading ?? heading);
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    // Filtro anti-tremor: ignora variações menores que 2°
    if (delta.abs() < 2 && _lastHeading != null) return;

    setState(() {
      _turns += delta / -360; // negativo = gira no sentido da bússola
      _lastHeading = heading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        // Fallback: sem sensor ou erro
        if (snapshot.hasError || !snapshot.hasData) {
          return Icon(widget.icon, color: widget.color, size: widget.size);
        }

        final double? heading = snapshot.data?.heading;
        if (heading != null) {
          // Agenda atualização fora do build (evita setState durante build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateHeading(heading);
          });
        }

        return AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );
      },
    );
  }
}
