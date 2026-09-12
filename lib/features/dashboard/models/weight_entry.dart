class WeightEntry {
  final int? id;
  final String date;
  final double weightKg;
  final double? heightCm;
  final DateTime createdAt;

  const WeightEntry({
    this.id,
    required this.date,
    required this.weightKg,
    this.heightCm,
    required this.createdAt,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      heightCm: map['height_cm'] != null ? (map['height_cm'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
