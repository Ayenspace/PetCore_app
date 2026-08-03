import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MarketplaceProvider>();
    final user = context.read<AppAuthProvider>().user;
    final listings = user == null ? [] : provider.myListings(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Listings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: listings.isEmpty
          ? Center(
              child: Text(
                user == null
                    ? 'Please sign in to view your listings.'
                    : 'No listings found. Tap + in Marketplace to add one.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListTile(
                  title: Text(listing.title),
                  subtitle: Text('GH₵ ${listing.price.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/marketplace/${listing.id}'),
                );
              },
            ),
    );
  }
}
