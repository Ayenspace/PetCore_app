enum ListingCategory { food, accessories, grooming, medication, adoption, other }

class MarketplaceModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String title;
  final String description;
  final double price;
  final ListingCategory category;
  final List<String> imageUrls;
  final String? location;
  final bool isAvailable;
  final DateTime createdAt;

  MarketplaceModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrls = const [],
    this.location,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory MarketplaceModel.fromMap(Map<String, dynamic> map) => MarketplaceModel(
        id: map['id']?.toString() ?? '',
        sellerId: map['sellerId']?.toString() ?? '',
        sellerName: map['sellerName']?.toString() ?? 'Unknown',
        sellerPhotoUrl: map['sellerPhotoUrl']?.toString(),
        title: map['title']?.toString() ?? 'Untitled',
        description: map['description']?.toString() ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        category: ListingCategory.values.asNameMap()[map['category']?.toString() ?? ''] ?? ListingCategory.other,
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        location: map['location']?.toString(),
        isAvailable: map['isAvailable'] ?? true,
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhotoUrl': sellerPhotoUrl,
        'title': title,
        'description': description,
        'price': price,
        'category': category.name,
        'imageUrls': imageUrls,
        'location': location,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
      };

  MarketplaceModel copyWith({
    String? title,
    String? description,
    double? price,
    ListingCategory? category,
    List<String>? imageUrls,
    String? location,
    bool? isAvailable,
  }) =>
      MarketplaceModel(
        id: id,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhotoUrl: sellerPhotoUrl,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrls: imageUrls ?? this.imageUrls,
        location: location ?? this.location,
        isAvailable: isAvailable ?? this.isAvailable,
        createdAt: createdAt,
      );
}
