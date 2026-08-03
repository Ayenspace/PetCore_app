import 'dart:async';
import 'package:flutter/material.dart';
import '../models/marketplace_model.dart';
import '../services/marketplace.dart';

class MarketplaceProvider extends ChangeNotifier {
  final _service = MarketplaceService();

  List<MarketplaceModel> _listings = [];
  StreamSubscription? _sub;

  bool _loading = false;
  String? _error;
  String _search = '';
  ListingCategory? _categoryFilter;

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  ListingCategory? get categoryFilter => _categoryFilter;

  List<MarketplaceModel> get listings => _listings;

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

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategory(ListingCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  Future<bool> addListing(MarketplaceModel listing) async {
    _setLoading(true);
    final success = await _service.addListing(listing);
    if (!success) _error = 'Failed to add listing.';
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
    _setLoading(true);
    await _service.deleteListingImages(sellerId, listingId);
    final success = await _service.deleteListing(listingId);
    if (!success) _error = 'Failed to delete listing.';
    _setLoading(false);
    return success;
  }

  Future<void> deleteListingImages(String sellerId, String listingId) async {
    await _service.deleteListingImages(sellerId, listingId);
  }

  Future<String> uploadImage(
    String sellerId,
    String listingId,
    dynamic file,
    int index,
  ) => _service.uploadListingImage(sellerId, listingId, file, index);

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
