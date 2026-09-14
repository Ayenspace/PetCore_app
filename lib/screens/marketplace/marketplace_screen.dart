import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceProvider>().listenToListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final uid = context.read<AppAuthProvider>().user?.id;
    final listings = provider.filtered;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'My Listings',
            onPressed: () => context.push('/marketplace/my-listings'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Listing',
            onPressed: () => context.push('/marketplace/add'),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearch,
              decoration: InputDecoration(
                hintText: 'Search listings...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category chips
          _CategoryFilter(provider: provider),

          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${listings.length} listing${listings.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ),

          // Grid
          Expanded(
            child: listings.isEmpty
                ? _EmptyState(provider: provider)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) =>
                        _ListingCard(listing: listings[index], currentUid: uid),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Category Filter ─────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final MarketplaceProvider provider;
  const _CategoryFilter({required this.provider});

  static const _labels = {
    ListingCategory.food: ('🍖', 'Food'),
    ListingCategory.accessories: ('🎀', 'Accessories'),
    ListingCategory.grooming: ('✂️', 'Grooming'),
    ListingCategory.medication: ('💊', 'Medication'),
    ListingCategory.adoption: ('🐾', 'Adoption'),
    ListingCategory.other: ('📦', 'Other'),
  };

  @override
  Widget build(BuildContext context) {
    final selected = provider.categoryFilter;
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('All', selected == null, color, () => provider.setCategory(null)),
          ...ListingCategory.values.map((cat) {
            final info = _labels[cat]!;
            return _chip('${info.$1} ${info.$2}', selected == cat, color,
                () => provider.setCategory(selected == cat ? null : cat));
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Listing Card ────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final MarketplaceModel listing;
  final String? currentUid;
  const _ListingCard({required this.listing, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/marketplace/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: listing.imageUrls.isNotEmpty
                    ? _buildImage(listing.imageUrls.first, theme)
                    : _placeholder(theme),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KSh ${listing.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path, ThemeData theme) {
    final resolved = path.replaceAll(' ', '_');
    final isNetwork = resolved.startsWith('http://') || resolved.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        placeholder: (_, _) => Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
        ),
        errorWidget: (_, _, _) => _placeholder(theme),
      );
    }
    return Image.asset(resolved, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(theme));
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        child: Center(
          child: Icon(Icons.storefront_outlined, size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
      );
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final MarketplaceProvider provider;
  const _EmptyState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isFiltered = provider.categoryFilter != null || provider.search.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No listings match your search' : 'No listings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 8),
            Text('Be the first to post something!', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/marketplace/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom Nav ──────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/home'); break;
          case 1: context.go('/pets'); break;
          case 2: context.go('/appointments'); break;
          case 3: context.go('/marketplace'); break;
          case 4: context.go('/profile'); break;
        }
      },
      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Appointments'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Market'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
