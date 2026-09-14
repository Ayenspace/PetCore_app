import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MarketplaceProvider>().listenToListings();
  }

  Future<void> _confirmDelete(BuildContext context, MarketplaceModel listing, String userId) async {
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

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<MarketplaceProvider>();
    final success = await provider.deleteListing(userId, listing.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Listing deleted.' : (provider.error ?? 'Failed to delete.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MarketplaceProvider>();
    final user = context.read<AppAuthProvider>().user;
    final listings = user == null ? <MarketplaceModel>[] : provider.myListings(user.id);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())
            : null,
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/marketplace/add'),
          ),
        ],
      ),
      body: listings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    user == null ? 'Please sign in to view your listings.' : 'No listings yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/marketplace/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Listing'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return Card(
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () => context.push('/marketplace/${listing.id}'),
                    title: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('KSh ${listing.price.toStringAsFixed(0)} • ${listing.category.name}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: listing.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            listing.isAvailable ? 'Active' : 'Sold',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: listing.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, listing, user!.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
