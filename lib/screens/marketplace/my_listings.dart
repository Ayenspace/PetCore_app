import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../models/marketplace_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().user;
      context.read<MarketplaceProvider>().listenToListings();
      if (user != null) {
        context.read<MarketplaceProvider>().listenToOrders(user.id);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MarketplaceModel listing,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      SnackBar(
        content: Text(
          success
              ? 'Listing deleted.'
              : (provider.error ?? 'Failed to delete.'),
        ),
      ),
    );
  }

  Future<void> _confirmOrderDecision(
    BuildContext context,
    MarketplaceOrderModel order,
    String status,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'accepted' ? 'Accept order' : 'Reject order'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status == 'accepted'
                    ? 'Send a quick message to ${order.buyerName}.'
                    : 'Let ${order.buyerName} know why this request was declined.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Optional message',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'accepted' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<MarketplaceProvider>();
    final success = await provider.updateOrderStatus(
      order.id,
      status: status,
      sellerReply: controller.text.trim().isEmpty
          ? null
          : controller.text.trim(),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Order ${status.toLowerCase()}' : 'Failed to update order.',
        ),
      ),
    );
  }

  Future<void> _sendReply(
    BuildContext context,
    MarketplaceOrderModel order,
  ) async {
    final controller = _replyControllers.putIfAbsent(
      order.id,
      () => TextEditingController(),
    );
    final message = controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write a message before sending a reply.'),
        ),
      );
      return;
    }

    final provider = context.read<MarketplaceProvider>();
    final success = await provider.updateOrderStatus(
      order.id,
      status: order.status,
      sellerReply: message,
    );

    if (!context.mounted) return;
    if (success) {
      controller.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Reply sent.' : 'Failed to send reply.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MarketplaceProvider>();
    final user = context.read<AppAuthProvider>().user;
    final listings = user == null
        ? <MarketplaceModel>[]
        : provider.myListings(user.id);
    final orders = user == null
        ? <MarketplaceOrderModel>[]
        : provider.orders.where((o) => o.sellerId == user.id).toList();

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'My Listings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  Icon(
                    Icons.storefront_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user == null
                        ? 'Please sign in to view your listings.'
                        : 'No listings yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
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
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          onTap: () =>
                              context.push('/marketplace/${listing.id}'),
                          title: Text(
                            listing.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'KSh ${listing.price.toStringAsFixed(0)} • ${listing.category.name}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: listing.isAvailable
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  listing.isAvailable ? 'Active' : 'Sold',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: listing.isAvailable
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDelete(context, listing, user!.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (orders.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Order requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final controller = _replyControllers.putIfAbsent(
                          order.id,
                          () => TextEditingController(),
                        );
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.listingTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(order.status.toUpperCase()),
                                      backgroundColor: order.isAccepted
                                          ? Colors.green.shade50
                                          : order.isRejected
                                          ? Colors.red.shade50
                                          : Colors.orange.shade50,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${order.buyerName} • ${order.quantity} item(s)',
                                ),
                                const SizedBox(height: 8),
                                if (order.message.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('Message: ${order.message}'),
                                  ),
                                if (order.sellerReply != null &&
                                    order.sellerReply!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('Reply: ${order.sellerReply!}'),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                if (order.isPending) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _confirmOrderDecision(
                                                context,
                                                order,
                                                'accepted',
                                              ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Accept'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _confirmOrderDecision(
                                                context,
                                                order,
                                                'rejected',
                                              ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Reject'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                TextField(
                                  controller: controller,
                                  minLines: 1,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Reply to buyer',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _sendReply(context, order),
                                    icon: const Icon(Icons.send),
                                    label: const Text('Send reply'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
