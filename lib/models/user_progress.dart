class UserProgress {
  final int steps;
  final int goalSteps;
  final int coins;
  final double distanceKm;
  final int durationMinutes;
  final int calories;

  UserProgress({
    this.steps = 0,
    this.goalSteps = 5000,
    this.coins = 0,
    this.distanceKm = 0.0,
    this.durationMinutes = 0,
    this.calories = 0,
  });

  double get progressPercentage => (steps / goalSteps).clamp(0.0, 1.0);
  int get remainingSteps => goalSteps - steps > 0 ? goalSteps - steps : 0;

  UserProgress copyWith({
    int? steps,
    int? goalSteps,
    int? coins,
    double? distanceKm,
    int? durationMinutes,
    int? calories,
  }) {
    return UserProgress(
      steps: steps ?? this.steps,
      goalSteps: goalSteps ?? this.goalSteps,
      coins: coins ?? this.coins,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
    );
  }
}
