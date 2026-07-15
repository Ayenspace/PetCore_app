enum ReminderRepeat { none, daily, weekly, monthly }

class ReminderModel {
  final String id;
  final String ownerId;
  final String? petId;
  final String? petName;
  final String title;
  final String? notes;
  final DateTime dateTime;
  final ReminderRepeat repeat;
  final bool isCompleted;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.ownerId,
    this.petId,
    this.petName,
    required this.title,
    this.notes,
    required this.dateTime,
    required this.repeat,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map) => ReminderModel(
        id: map['id'],
        ownerId: map['ownerId'],
        petId: map['petId'],
        petName: map['petName'],
        title: map['title'],
        notes: map['notes'],
        dateTime: DateTime.parse(map['dateTime']),
        repeat: ReminderRepeat.values.byName(map['repeat']),
        isCompleted: map['isCompleted'] ?? false,
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'petName': petName,
        'title': title,
        'notes': notes,
        'dateTime': dateTime.toIso8601String(),
        'repeat': repeat.name,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  ReminderModel copyWith({bool? isCompleted}) => ReminderModel(
        id: id,
        ownerId: ownerId,
        petId: petId,
        petName: petName,
        title: title,
        notes: notes,
        dateTime: dateTime,
        repeat: repeat,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
      );
}
