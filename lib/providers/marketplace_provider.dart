import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/marketplace_model.dart';
import '../models/marketplace_order_model.dart';
import '../services/marketplace.dart';

class MarketplaceProvider extends ChangeNotifier {
  final _service = MarketplaceService();

  List<MarketplaceModel> _listings = [];
  List<MarketplaceOrderModel> _orders = [];
  StreamSubscription? _sub;
  StreamSubscription? _ordersSub;

  bool _loading = false;
  String? _error;
  String _search = '';
  ListingCategory? _categoryFilter;

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  ListingCategory? get categoryFilter => _categoryFilter;

  List<MarketplaceModel> get listings => _listings;
  List<MarketplaceOrderModel> get orders => _orders;

  List<MarketplaceModel> get filtered {
    var list = _listings.where((l) => l.isAvailable).toList();
    if (_categoryFilter != null) {
      list = list.where((l) => l.category == _categoryFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (l) =>
                l.title.toLowerCase().contains(q) ||
                l.description.toLowerCase().contains(q) ||
                l.sellerName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<MarketplaceModel> myListings(String sellerId) =>
      _listings.where((l) => l.sellerId == sellerId).toList();

  MarketplaceModel? getById(String id) {
    try {
      return _listings.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void listenToListings() {
    _sub?.cancel();
    _sub = _service.streamListings().listen((data) {
      _listings = data;
      notifyListeners();
    });
  }

  void listenToOrders(String userId) {
    _ordersSub?.cancel();
    _ordersSub = _service.streamOrders(userId).listen((data) {
      _orders = data;
      notifyListeners();
    });
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategory(ListingCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  Future<bool> addListing(MarketplaceModel listing) async {
    _error = null;
    _setLoading(true);
    bool success;
    try {
      success = await _service.addListing(listing);
    } catch (e, st) {
      success = false;
      _error = 'Failed to add listing: $e';
      debugPrint('MarketplaceProvider.addListing error: $e');
      debugPrint('$st');
    }
    if (!success && _error == null) {
      _error = 'Failed to add listing.';
    }
    _setLoading(false);
    return success;
  }

  String generateListingId() => _service.generateId();

  Future<bool> updateListing(MarketplaceModel listing) async {
    _setLoading(true);
    final success = await _service.updateListing(listing);
    if (!success) _error = 'Failed to update listing.';
    _setLoading(false);
    return success;
  }

  Future<bool> deleteListing(String sellerId, String listingId) async {
    // Remove from DB immediately for instant UI response
    final success = await _service.deleteListing(listingId);
    if (!success) {
      _error = 'Failed to delete listing.';
      return false;
    }
    // Delete images in background — don't await
    _service.deleteListingImages(sellerId, listingId);
    return true;
  }

  Future<void> deleteListingImages(String sellerId, String listingId) async {
    await _service.deleteListingImages(sellerId, listingId);
  }

  Future<String> uploadImage(
    String sellerId,
    String listingId,
    XFile file,
    int index,
  ) => _service.uploadListingImage(sellerId, listingId, file, index);

  Future<bool> placeOrder(MarketplaceOrderModel order) async {
    _error = null;
    _setLoading(true);
    try {
      final success = await _service.addOrder(order);
      if (success) {
        final saved = _orders.contains(order)
            ? _orders.firstWhere(
                (item) => item.id == order.id,
                orElse: () => order,
              )
            : order;
        if (!_orders.any(
          (item) => item.id == saved.id && item.listingId == saved.listingId,
        )) {
          _orders.insert(0, saved);
        }
        notifyListeners();
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _error = 'Failed to place order: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateOrderStatus(
    String orderId, {
    required String status,
    String? sellerReply,
  }) async {
    _error = null;
    _setLoading(true);
    try {
      final success = await _service.updateOrderStatus(
        orderId,
        status: status,
        sellerReply: sellerReply,
      );
      if (success) {
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          final updated = _orders[index].copyWith(
            status: status,
            sellerReply: sellerReply ?? _orders[index].sellerReply,
          );
          _orders[index] = updated;
        }
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _error = 'Failed to update order: $e';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}
