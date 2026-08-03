enum AppointmentStatus { upcoming, completed, cancelled }

class AppointmentModel {
  final String id;
  final String ownerId;
  final String petId;
  final String petName;
  final String service;
  final String vetName;
  final String? location;
  final DateTime dateTime;
  final String? notes;
  final AppointmentStatus status;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.petName,
    required this.service,
    required this.vetName,
    this.location,
    required this.dateTime,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) => AppointmentModel(
        id: map['id'],
        ownerId: map['ownerId'],
        petId: map['petId'],
        petName: map['petName'],
        service: map['service'] ?? '',
        vetName: map['vetName'],
        location: map['location'],
        dateTime: DateTime.parse(map['dateTime']),
        notes: map['notes'],
        status: AppointmentStatus.values.byName(map['status']),
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'petName': petName,
        'service': service,
        'vetName': vetName,
        'location': location,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  AppointmentModel copyWith({
    String? service,
    String? vetName,
    String? location,
    DateTime? dateTime,
    String? notes,
    AppointmentStatus? status,
  }) =>
      AppointmentModel(
        id: id,
        ownerId: ownerId,
        petId: petId,
        petName: petName,
        service: service ?? this.service,
        vetName: vetName ?? this.vetName,
        location: location ?? this.location,
        dateTime: dateTime ?? this.dateTime,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
