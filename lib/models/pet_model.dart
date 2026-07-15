class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final DateTime dateOfBirth;
  final double? weight;
  final String? photoUrl;
  final DateTime createdAt;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    required this.gender,
    required this.dateOfBirth,
    this.weight,
    this.photoUrl,
    required this.createdAt,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  factory PetModel.fromMap(Map<String, dynamic> map) => PetModel(
        id: map['id'],
        ownerId: map['ownerId'],
        name: map['name'],
        species: map['species'],
        breed: map['breed'],
        gender: map['gender'],
        dateOfBirth: DateTime.parse(map['dateOfBirth']),
        weight: map['weight']?.toDouble(),
        photoUrl: map['photoUrl'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'species': species,
        'breed': breed,
        'gender': gender,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'weight': weight,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  PetModel copyWith({
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    String? photoUrl,
  }) =>
      PetModel(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        species: species ?? this.species,
        breed: breed ?? this.breed,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        weight: weight ?? this.weight,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );
}
