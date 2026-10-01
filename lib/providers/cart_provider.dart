import 'package:flutter/material.dart';
import '../models/marketplace_model.dart';
import 'auth_provider.dart';

class CartItem {
  final MarketplaceModel listing;
  int quantity;
  CartItem({required this.listing, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  AppAuthProvider? _authProvider;

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.fold(0, (sum, i) => sum + i.listing.price * i.quantity);

  bool contains(String listingId) => _items.any((i) => i.listing.id == listingId);

  /// Call this once from the widget tree to wire up auth-based cart clearing.
  void listenToAuth(AppAuthProvider auth) {
    if (_authProvider == auth) return;
    _authProvider?.removeListener(_onAuthChanged);
    _authProvider = auth;
    auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider?.status == AuthStatus.unauthenticated) {
      clear();
    }
  }

  void add(MarketplaceModel listing) {
    final index = _items.indexWhere((i) => i.listing.id == listing.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(listing: listing));
    }
    notifyListeners();
  }

  void remove(String listingId) {
    _items.removeWhere((i) => i.listing.id == listingId);
    notifyListeners();
  }

  void updateQuantity(String listingId, int qty) {
    if (qty <= 0) { remove(listingId); return; }
    final index = _items.indexWhere((i) => i.listing.id == listingId);
    if (index >= 0) { _items[index].quantity = qty; notifyListeners(); }
  }

  void clear() { _items.clear(); notifyListeners(); }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
