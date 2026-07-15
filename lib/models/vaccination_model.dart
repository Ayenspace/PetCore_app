class VaccinationModel {
  final String id;
  final String ownerId;
  final String petId;
  final String petName;
  final String vaccineName;
  final String vetName;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final String? notes;
  final DateTime createdAt;

  VaccinationModel({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.petName,
    required this.vaccineName,
    required this.vetName,
    required this.dateGiven,
    this.nextDueDate,
    this.notes,
    required this.createdAt,
  });

  bool get isDue =>
      nextDueDate != null && nextDueDate!.isBefore(DateTime.now());

  factory VaccinationModel.fromMap(Map<String, dynamic> map) => VaccinationModel(
        id: map['id'],
        ownerId: map['ownerId'],
        petId: map['petId'],
        petName: map['petName'],
        vaccineName: map['vaccineName'],
        vetName: map['vetName'],
        dateGiven: DateTime.parse(map['dateGiven']),
        nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'petName': petName,
        'vaccineName': vaccineName,
        'vetName': vetName,
        'dateGiven': dateGiven.toIso8601String(),
        'nextDueDate': nextDueDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
