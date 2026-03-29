class DifficultyScaler {
  static int calculateReps(
      int baseReps, Map<String, dynamic> profile) {

    int level = profile["fitnessLevel"] ?? 1;
    int scaled = baseReps + (level * 2);

    int age = profile["age"] ?? 25;

    if (age > 50) {
      scaled = (scaled * 0.8).round();
    }

    List health = profile["healthConditions"] ?? [];

    if (health.contains("Heart Condition")) {
      scaled = (scaled * 0.6).round();
    }

    return scaled;
  }
}