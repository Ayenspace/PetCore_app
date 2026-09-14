import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../models/marketplace_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailsScreen({required this.listingId, super.key});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _messageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _submitting = false;
  bool _submitted = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MarketplaceProvider>();
      provider.listenToListings();
      final user = context.read<AppAuthProvider>().user;
      if (user != null) provider.listenToOrders(user.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(MarketplaceModel listing, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    // Navigate away FIRST before the stream removes the listing
    // to avoid the "Listing not found" flash
    context.go('/marketplace');

    final provider = context.read<MarketplaceProvider>();
    final success = await provider.deleteListing(userId, listing.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✓ Listing deleted.' : (provider.error ?? 'Failed to delete.')),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _submitOrder(MarketplaceModel listing, String? buyerId) async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a quantity.')));
      return;
    }
    final user = context.read<AppAuthProvider>().user;
    if (user == null) return;

    final provider = context.read<MarketplaceProvider>();
    setState(() => _submitting = true);

    try {
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final order = MarketplaceOrderModel(
        id: '',
        listingId: listing.id,
        listingTitle: listing.title,
        sellerId: listing.sellerId,
        buyerId: buyerId ?? '',
        buyerName: user.name,
        buyerPhotoUrl: user.photoUrl,
        message: _messageController.text.trim(),
        quantity: quantity,
        createdAt: DateTime.now(),
      );

      final success = await provider.placeOrder(order);
      if (!mounted) return;

      if (success) {
        setState(() { _submitted = true; _submitting = false; });
        _messageController.clear();
        _quantityController.text = '1';
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Could not send your order request.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send your order request.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final listing = provider.getById(widget.listingId);
    final theme = Theme.of(context);

    // If listing was just deleted and we haven't navigated yet, show loading
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: provider.loading ? const CircularProgressIndicator() : const Text('Listing not found.')),
      );
    }

    final currentUserId = context.read<AppAuthProvider>().user?.id;
    final isOwner = currentUserId == listing.sellerId;
    final isSignedIn = currentUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.push('/marketplace/${listing.id}/edit'),
            ),
            _deleting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(listing, currentUserId!),
                  ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _ImageSection(imageUrls: listing.imageUrls, theme: theme),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: listing.isAvailable ? 'Available' : 'Sold',
                        color: listing.isAvailable ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'KSh ${listing.price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),

                  // Meta info
                  _InfoRow(icon: Icons.category_outlined, label: listing.category.name.toUpperCase()),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.person_outline, label: listing.sellerName),
                  if (listing.location != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(icon: Icons.location_on_outlined, label: listing.location!),
                  ],
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 12),

                  // Description
                  const Text('About this listing',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(listing.description,
                      style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade700)),
                  const SizedBox(height: 24),

                  // Order / sign-in section
                  if (!isOwner && isSignedIn)
                    _OrderSection(
                      listing: listing,
                      currentUserId: currentUserId,
                      submitted: _submitted,
                      submitting: _submitting,
                      messageController: _messageController,
                      quantityController: _quantityController,
                      onSubmit: () => _submitOrder(listing, currentUserId),
                    )
                  else if (!isOwner && !isSignedIn)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Sign in to place an order request.'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Section ───────────────────────────────────────────────────────────

class _ImageSection extends StatefulWidget {
  final List<String> imageUrls;
  final ThemeData theme;
  const _ImageSection({required this.imageUrls, required this.theme});

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 220,
        color: widget.theme.colorScheme.primary.withValues(alpha: 0.07),
        child: Center(
          child: Icon(Icons.storefront_outlined, size: 64,
              color: widget.theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final path = widget.imageUrls[index].replaceAll(' ', '_');
              final isNetwork = path.startsWith('http://') || path.startsWith('https://');
              if (isNetwork) {
                return CachedNetworkImage(
                  imageUrl: path,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
                );
              }
              return Image.asset(path, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)));
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}

// ── Small helpers ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      );
}

// ── Order Section ───────────────────────────────────────────────────────────

class _OrderSection extends StatelessWidget {
  final MarketplaceModel listing;
  final String currentUserId;
  final bool submitted;
  final bool submitting;
  final TextEditingController messageController;
  final TextEditingController quantityController;
  final VoidCallback onSubmit;

  const _OrderSection({
    required this.listing,
    required this.currentUserId,
    required this.submitted,
    required this.submitting,
    required this.messageController,
    required this.quantityController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Place an order request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Send a request to the seller for availability or delivery details.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity',
              prefixIcon: const Icon(Icons.numbers, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message to seller',
              hintText: 'Tell the seller what you need...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          if (submitted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Order request sent! The seller will get back to you.')),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: const Text('Send order request'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
