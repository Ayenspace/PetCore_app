import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class ListingDetailsScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailsScreen({required this.listingId, super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final listing = provider.getById(listingId);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing Details')),
        body: const Center(child: Text('Listing not found.')),
      );
    }

    final currentUserId = context.read<AppAuthProvider>().user?.id;
    final isOwner = currentUserId == listing.sellerId;

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
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: listing.imageUrls[index],
                      width: 300,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 300,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 300,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
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
          ],
        ),
      ),
    );
  }
}
