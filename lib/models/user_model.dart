enum UserRole { petOwner, vet }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? bio;
  final String? photoUrl;
  final UserRole role;
  final bool isSeller;
  final String? clinicName;
  final String? specialization;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.bio,
    this.photoUrl,
    required this.role,
    this.isSeller = false,
    this.clinicName,
    this.specialization,
    required this.createdAt,
  });

  bool get isVet => role == UserRole.vet;
  bool get isPetOwner => role == UserRole.petOwner;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        address: map['address'],
        bio: map['bio'],
        photoUrl: map['photoUrl'],
        role: UserRole.values.byName(map['role'] ?? 'petOwner'),
        isSeller: map['isSeller'] ?? false,
        clinicName: map['clinicName'],
        specialization: map['specialization'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'bio': bio,
        'photoUrl': photoUrl,
        'role': role.name,
        'isSeller': isSeller,
        'clinicName': clinicName,
        'specialization': specialization,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? bio,
    String? photoUrl,
    bool? isSeller,
    String? clinicName,
    String? specialization,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role,
        isSeller: isSeller ?? this.isSeller,
        clinicName: clinicName ?? this.clinicName,
        specialization: specialization ?? this.specialization,
        createdAt: createdAt,
      );
}
