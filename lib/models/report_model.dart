class ReportModel {
  final String id;
  final String ownerId;
  final String petId;
  final String petName;
  final DateTime generatedAt;
  final String? pdfUrl;

  ReportModel({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.petName,
    required this.generatedAt,
    this.pdfUrl,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) => ReportModel(
        id: map['id'],
        ownerId: map['ownerId'],
        petId: map['petId'],
        petName: map['petName'],
        generatedAt: DateTime.parse(map['generatedAt']),
        pdfUrl: map['pdfUrl'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'petName': petName,
        'generatedAt': generatedAt.toIso8601String(),
        'pdfUrl': pdfUrl,
      };
}
