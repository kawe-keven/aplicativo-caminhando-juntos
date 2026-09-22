import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class RouteUtils {
  /// Simplifica uma lista de pontos usando uma versão iterativa (não-recursiva) 
  /// do algoritmo de Douglas-Peucker para evitar Stack Overflow.
  /// [epsilon] é a tolerância em metros.
  static List<LatLng> simplify(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;

    final int len = points.length;
    final List<bool> keep = List<bool>.filled(len, false);
    
    // Marca o primeiro e o último ponto para manter sempre
    keep[0] = true;
    keep[len - 1] = true;

    // Pilha contendo os intervalos de índices a processar [inicio, fim]
    final List<List<int>> stack = [];
    stack.add([0, len - 1]);

    while (stack.isNotEmpty) {
      final List<int> range = stack.removeLast();
      final int start = range[0];
      final int end = range[1];

      if (end - start < 2) continue;

      double dmax = 0;
      int maxIndex = start;

      for (int i = start + 1; i < end; i++) {
        final double d = _perpendicularDistance(points[i], points[start], points[end]);
        if (d > dmax) {
          dmax = d;
          maxIndex = i;
        }
      }

      if (dmax > epsilon) {
        keep[maxIndex] = true;
        // Adiciona os sub-intervalos na pilha para processamento subsequente
        stack.add([start, maxIndex]);
        stack.add([maxIndex, end]);
      }
    }

    // Filtra mantendo apenas os pontos selecionados preservando a ordem original
    final List<LatLng> result = [];
    for (int i = 0; i < len; i++) {
      if (keep[i]) {
        result.add(points[i]);
      }
    }
    return result;
  }

  /// Calcula a distância perpendicular de um ponto a uma linha segmentada (P1-P2).
  /// Retorna o valor aproximado em metros.
  static double _perpendicularDistance(LatLng p, LatLng p1, LatLng p2) {
    // Conversão simples para metros em escala local
    // Nota: Para precisão absoluta em distâncias globais seria necessário Haversine/Vincenty,
    // mas para suavização de jitter em caminhadas urbanas, geometria Euclidiana é suficiente.
    double x = p.longitude;
    double y = p.latitude;
    double x1 = p1.longitude;
    double y1 = p1.latitude;
    double x2 = p2.longitude;
    double y2 = p2.latitude;

    double numerator = ((y1 - y2) * x + (x2 - x1) * y + (x1 * y2 - x2 * y1)).abs();
    double denominator = math.sqrt(math.pow(y1 - y2, 2) + math.pow(x2 - x1, 2));

    if (denominator == 0) return 0;
    
    // Converte de graus decimais para metros (aproximação: 1 grau ~= 111.32 km)
    return (numerator / denominator) * 111320.0;
  }
}
