class MarketplaceOrderModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String? buyerPhotoUrl;
  final String message;
  final String? sellerReply;
  final int quantity;
  final String status;
  final DateTime createdAt;

  const MarketplaceOrderModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhotoUrl,
    this.message = '',
    this.sellerReply,
    this.quantity = 1,
    this.status = 'pending',
    required this.createdAt,
  });

  String get normalizedStatus => status.trim().toLowerCase();
  bool get isPending => normalizedStatus == 'pending';
  bool get isAccepted => normalizedStatus == 'accepted';
  bool get isRejected => normalizedStatus == 'rejected';

  factory MarketplaceOrderModel.fromMap(Map<String, dynamic> map) =>
      MarketplaceOrderModel(
        id: map['id'] ?? '',
        listingId: map['listingId'] ?? '',
        listingTitle: map['listingTitle'] ?? '',
        sellerId: map['sellerId'] ?? '',
        buyerId: map['buyerId'] ?? '',
        buyerName: map['buyerName'] ?? '',
        buyerPhotoUrl: map['buyerPhotoUrl'],
        message: map['message'] ?? '',
        sellerReply: map['sellerReply'],
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        status: (map['status'] ?? 'pending').toString(),
        createdAt:
            DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'listingId': listingId,
    'listingTitle': listingTitle,
    'sellerId': sellerId,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'buyerPhotoUrl': buyerPhotoUrl,
    'message': message,
    'sellerReply': sellerReply,
    'quantity': quantity,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  MarketplaceOrderModel copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? sellerId,
    String? buyerId,
    String? buyerName,
    String? buyerPhotoUrl,
    String? message,
    String? sellerReply,
    int? quantity,
    String? status,
    DateTime? createdAt,
  }) => MarketplaceOrderModel(
    id: id ?? this.id,
    listingId: listingId ?? this.listingId,
    listingTitle: listingTitle ?? this.listingTitle,
    sellerId: sellerId ?? this.sellerId,
    buyerId: buyerId ?? this.buyerId,
    buyerName: buyerName ?? this.buyerName,
    buyerPhotoUrl: buyerPhotoUrl ?? this.buyerPhotoUrl,
    message: message ?? this.message,
    sellerReply: sellerReply ?? this.sellerReply,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
}
