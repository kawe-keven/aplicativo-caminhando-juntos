import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class RouteUtils {
  /// Simplifica uma lista de pontos usando o algoritmo de Douglas-Peucker.
  /// [epsilon] é a tolerância em metros.
  static List<LatLng> simplify(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;

    int index = -1;
    double dmax = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double d = _perpendicularDistance(points[i], points.first, points.last);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      List<LatLng> res1 = simplify(points.sublist(0, index + 1), epsilon);
      List<LatLng> res2 = simplify(points.sublist(index), epsilon);
      return [...res1.sublist(0, res1.length - 1), ...res2];
    } else {
      return [points.first, points.last];
    }
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
