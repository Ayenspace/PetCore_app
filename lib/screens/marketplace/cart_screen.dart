import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/marketplace_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AppAuthProvider>();
    final marketplace = context.read<MarketplaceProvider>();
    final user = auth.user;
    if (user == null || cart.items.isEmpty) return;

    setState(() => _placing = true);

    // Snapshot the list before the async loop so mutations don't affect it
    final items = List.of(cart.items);
    String? firstError;
    for (final item in items) {
      if (!mounted) return;
      final order = MarketplaceOrderModel(
        id: '',
        listingId: item.listing.id,
        listingTitle: item.listing.title,
        sellerId: item.listing.sellerId,
        buyerId: user.id,
        buyerName: user.name,
        buyerPhotoUrl: user.photoUrl,
        quantity: item.quantity,
        createdAt: DateTime.now(),
      );
      final err = await marketplace.placeOrder(order);
      firstError ??= err;
    }

    if (!mounted) return;
    setState(() => _placing = false);

    if (firstError == null) {
      cart.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Orders placed! Check My Orders for status.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/marketplace/my-orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $firstError')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const BackButton() : null,
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clear(),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Your cart is empty', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/marketplace'),
                    child: const Text('Browse Marketplace'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(
                        item: item,
                        currency: currency,
                        onRemove: () => cart.remove(item.listing.id),
                        onQtyChanged: (q) => cart.updateQuantity(item.listing.id, q),
                      );
                    },
                  ),
                ),
                _CheckoutBar(
                  total: cart.total,
                  currency: currency,
                  placing: _placing,
                  onCheckout: _checkout,
                ),
              ],
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final CurrencyProvider currency;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _CartItemTile({
    required this.item,
    required this.currency,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.listing.imageUrls.isNotEmpty
                  ? Image.network(item.listing.imageUrls.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme))
                  : _placeholder(theme),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(currency.format(item.listing.price),
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Quantity stepper
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () => onQtyChanged(item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () => onQtyChanged(item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        child: Icon(Icons.storefront_outlined,
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final CurrencyProvider currency;
  final bool placing;
  final VoidCallback onCheckout;

  const _CheckoutBar({
    required this.total,
    required this.currency,
    required this.placing,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(currency.format(total),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: placing ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: placing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Place Orders', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
