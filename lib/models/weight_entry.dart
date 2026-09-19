class WeightEntry {
  final String id;
  final String petId;
  final double weight;
  final DateTime recordedAt;

  const WeightEntry({
    required this.id,
    required this.petId,
    required this.weight,
    required this.recordedAt,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
    id: map['id']?.toString() ?? '',
    petId: map['petId']?.toString() ?? '',
    weight: (map['weight'] as num).toDouble(),
    recordedAt: DateTime.parse(map['recordedAt'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'petId': petId,
    'weight': weight,
    'recordedAt': recordedAt.toIso8601String(),
  };
}
