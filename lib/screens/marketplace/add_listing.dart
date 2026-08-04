import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  static const List<String> _assetImageOptions = [
    'assets/images/marketplace/cheetah cat.jfif',
    'assets/images/marketplace/german shephard.jfif',
    'assets/images/marketplace/maccoon cat.avif',
    'assets/images/marketplace/pink collar.jfif',
    'assets/images/marketplace/rabbit.jfif',
  ];

  ListingCategory _category = ListingCategory.other;
  bool _isAvailable = true;
  bool _saving = false;
  String _selectedAssetImage = _assetImageOptions.first;

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceProvider>().listenToListings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AppAuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to add a listing.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final marketplaceProvider = context.read<MarketplaceProvider>();
      final listingId = marketplaceProvider.generateListingId();
      final imageUrls = <String>[_selectedAssetImage];

      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final listing = MarketplaceModel(
        id: listingId,
        sellerId: user.id,
        sellerName: user.name,
        sellerPhotoUrl: user.photoUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _category,
        imageUrls: imageUrls,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
      );

      final success = await marketplaceProvider.addListing(listing);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<MarketplaceProvider>().error ??
                  'Failed to save listing.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving listing: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Listing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new listing',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _buildAssetPicker(theme),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a price';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ListingCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ListingCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_categoryLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                title: const Text('Available for sale'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveListing,
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publish Listing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a photo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: _assetImageOptions.map((assetPath) {
            final isSelected = assetPath == _selectedAssetImage;
            return GestureDetector(
              onTap: () => setState(() => _selectedAssetImage = assetPath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick one image from your app assets',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _categoryLabel(ListingCategory category) {
    switch (category) {
      case ListingCategory.food:
        return 'Food';
      case ListingCategory.accessories:
        return 'Accessories';
      case ListingCategory.grooming:
        return 'Grooming';
      case ListingCategory.medication:
        return 'Medication';
      case ListingCategory.adoption:
        return 'Adoption';
      case ListingCategory.other:
        return 'Other';
    }
  }
}
