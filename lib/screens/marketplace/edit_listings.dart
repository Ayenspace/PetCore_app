import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';

class EditListingScreen extends StatefulWidget {
  final String listingId;
  const EditListingScreen({required this.listingId, super.key});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  ListingCategory _category = ListingCategory.other;
  bool _isAvailable = true;
  bool _saving = false;
  bool _initialized = false;
  List<String> _existingImageUrls = [];
  final List<XFile> _pickedImages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final provider = context.watch<MarketplaceProvider>();
    final listing = provider.getById(widget.listingId);
    if (listing == null) {
      context.read<MarketplaceProvider>().listenToListings();
      return;
    }

    _titleController.text = listing.title;
    _descriptionController.text = listing.description;
    _priceController.text = listing.price.toStringAsFixed(2);
    _locationController.text = listing.location ?? '';
    _category = listing.category;
    _isAvailable = listing.isAvailable;
    _existingImageUrls = List.from(listing.imageUrls);
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);

    setState(() {
      final remaining = 4 - _existingImageUrls.length - _pickedImages.length;
      _pickedImages.addAll(images.take(remaining));
    });
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AppAuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to edit a listing.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<MarketplaceProvider>();
      final imageUrls = List<String>.from(_existingImageUrls);

      if (_pickedImages.isNotEmpty) {
        await provider.deleteListingImages(user.id, widget.listingId);
        imageUrls.clear();
        for (var i = 0; i < _pickedImages.length; i++) {
          final url = await provider.uploadImage(
            user.id,
            widget.listingId,
            File(_pickedImages[i].path),
            i,
          );
          imageUrls.add(url);
        }
      }

      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final editedListing = MarketplaceModel(
        id: widget.listingId,
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

      final success = await provider.updateListing(editedListing);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to update listing.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating listing: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final listing = provider.getById(widget.listingId);
    if (listing == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Listing',
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
                'Update listing details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _buildImagePicker(theme),
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
                          'Save Changes',
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

  Widget _buildImagePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._existingImageUrls.map((url) => _buildImageTileUrl(url, theme)),
            ..._pickedImages.map(
              (image) => _buildImageTile(File(image.path), theme),
            ),
            if (_existingImageUrls.length + _pickedImages.length < 4)
              _buildAddImageTile(theme),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 4 photos',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildImageTileUrl(String url, ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(url, width: 88, height: 88, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _existingImageUrls.remove(url)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(File file, ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file, width: 88, height: 88, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(
              () =>
                  _pickedImages.removeWhere((xFile) => xFile.path == file.path),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            size: 28,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
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
