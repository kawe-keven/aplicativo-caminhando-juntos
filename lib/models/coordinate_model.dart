class CoordinateModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  CoordinateModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }
}
