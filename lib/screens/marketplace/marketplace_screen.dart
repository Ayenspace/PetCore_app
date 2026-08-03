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
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'My Listings',
            onPressed: () => context.push('/marketplace/my-listings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/marketplace/add'),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 3),
      body: Column(
        children: [
          _SearchBar(controller: _searchController, provider: provider),
          _CategoryFilter(provider: provider),
          Expanded(
            child: listings.isEmpty
                ? _EmptyState(provider: provider)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
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

// ── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final MarketplaceProvider provider;

  const _SearchBar({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: provider.setSearch,
        decoration: InputDecoration(
          hintText: 'Search listings...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    provider.setSearch('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

// ── Category Filter ────────────────────────────────────────────────────────

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

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => provider.setCategory(null),
          ),
          ...ListingCategory.values.map((cat) {
            final info = _labels[cat]!;
            return _Chip(
              label: '${info.$1} ${info.$2}',
              selected: selected == cat,
              onTap: () => provider.setCategory(selected == cat ? null : cat),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Listing Card ───────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final MarketplaceModel listing;
  final String? currentUid;
  const _ListingCard({required this.listing, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = listing.sellerId == currentUid;

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: listing.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, _, _) =>
                            _PlaceholderImage(theme: theme),
                      )
                    : _PlaceholderImage(theme: theme),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.sellerName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GH₵ ${listing.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Yours',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
}

class _PlaceholderImage extends StatelessWidget {
  final ThemeData theme;
  const _PlaceholderImage({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final MarketplaceProvider provider;
  const _EmptyState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isFiltered =
        provider.categoryFilter != null || provider.search.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No listings match your search' : 'No listings yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (!isFiltered) ...[
            Text(
              'Be the first to post something!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
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

// ── Bottom Nav ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/pets');
            break;
          case 2:
            context.go('/appointments');
            break;
          case 3:
            context.go('/marketplace');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      indicatorColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: 'Pets',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Market',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
