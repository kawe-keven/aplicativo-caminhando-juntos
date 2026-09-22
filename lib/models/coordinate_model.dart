class CoordinateModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final bool isSuspect;

  CoordinateModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.isSuspect = false,
  });

  factory CoordinateModel.fromJson(Map<String, dynamic> json) {
    return CoordinateModel(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: (json['accuracy'] as num).toDouble(),
      isSuspect: json['suspect'] == 1,
    );
  }

  factory CoordinateModel.fromMap(Map<String, dynamic> map) {
    return CoordinateModel(
      latitude: map['lat'] as double,
      longitude: map['lng'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp_ms'] as int),
      accuracy: map['precisao'] as double,
      isSuspect: (map['suspeito'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'suspect': isSuspect ? 1 : 0,
    };
  }
}
