import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../models/marketplace_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class _ListingImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const _ListingImage({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MarketplaceProvider>();
      provider.listenToListings();
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        provider.listenToOrders(user.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(
    BuildContext context,
    MarketplaceModel listing,
    String? buyerId,
  ) async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a quantity.')));
      return;
    }

    final user = context.read<AppAuthProvider>().user;
    if (user == null) {
      return;
    }

    final provider = context.read<MarketplaceProvider>();
    final messenger = ScaffoldMessenger.of(context);

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
        setState(() {
          _submitted = true;
          _submitting = false;
          _messageController.clear();
          _quantityController.text = '1';
        });
      } else {
        setState(() => _submitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'Could not send your order request.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send your order request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final listing = provider.getById(widget.listingId);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing Details')),
        body: Center(
          child: provider.loading
              ? const CircularProgressIndicator()
              : const Text('Listing not found.'),
        ),
      );
    }

    final currentUserId = context.read<AppAuthProvider>().user?.id;
    final isOwner = currentUserId == listing.sellerId;
    final isSignedIn = currentUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          listing.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Listing',
              onPressed: () => context.push('/marketplace/${listing.id}/edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: listing.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _ListingImage(
                      imagePath: listing.imageUrls[index],
                      width: 300,
                      height: 220,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              listing.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'GH₵ ${listing.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(listing.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 8),
                Text(listing.sellerName),
              ],
            ),
            if (listing.location != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(listing.location!),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Category: ${listing.category.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text('Availability: ${listing.isAvailable ? 'Available' : 'Sold'}'),
            const SizedBox(height: 24),
            if (!isOwner && isSignedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Place an order request',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This sends a request to the seller so they can reply with availability or delivery details.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message to seller',
                          hintText: 'Tell the seller what you need',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_submitted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Order request sent. The seller will get back to you.',
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitting
                                ? null
                                : () => _submitOrder(
                                    context,
                                    listing,
                                    currentUserId ?? '',
                                  ),
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send order request'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ] else if (!isOwner && !isSignedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sign in to place an order request.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
