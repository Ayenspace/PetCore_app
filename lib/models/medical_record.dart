class MedicalRecord {
  final String id;
  final String ownerId;
  final String petId;
  final String petName;
  final String diagnosis;
  final String treatment;
  final String vetName;
  final DateTime date;
  final String? notes;
  final List<String> attachmentUrls;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.petName,
    required this.diagnosis,
    required this.treatment,
    required this.vetName,
    required this.date,
    this.notes,
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> map) => MedicalRecord(
        id: map['id'],
        ownerId: map['ownerId'],
        petId: map['petId'],
        petName: map['petName'],
        diagnosis: map['diagnosis'],
        treatment: map['treatment'],
        vetName: map['vetName'],
        date: DateTime.parse(map['date']),
        notes: map['notes'],
        attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'petName': petName,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'vetName': vetName,
        'date': date.toIso8601String(),
        'notes': notes,
        'attachmentUrls': attachmentUrls,
        'createdAt': createdAt.toIso8601String(),
      };
}
