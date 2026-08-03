import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/marketplace_model.dart';
import 'firestore.dart';

class MarketplaceService {
  final _db = DatabaseService();
  final _storage = FirebaseStorage.instance;

  static const _path = 'marketplace';

  String generateId() => _db.generateId(_path);

  Stream<List<MarketplaceModel>> streamListings() {
    return _db.stream(_path).map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map(
            (v) =>
                MarketplaceModel.fromMap(Map<String, dynamic>.from(v as Map)),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<bool> addListing(MarketplaceModel listing) async {
    try {
      final id = listing.id.isNotEmpty ? listing.id : _db.generateId(_path);
      final data = listing.copyWith().toMap();
      data['id'] = id;
      await _db.set('$_path/$id', data);
      return true;
    } catch (e, st) {
      debugPrint('MarketplaceService.addListing error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<bool> updateListing(MarketplaceModel listing) async {
    try {
      await _db.update('$_path/${listing.id}', listing.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      await _db.delete('$_path/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> uploadListingImage(
    String sellerId,
    String listingId,
    XFile xFile,
    int index,
  ) async {
    final ref = _storage.ref('listing_images/$sellerId/$listingId/$index.jpg');
    try {
      debugPrint(
        'MarketplaceService: uploading image $index for listing $listingId',
      );
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(
          File(xFile.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }
      final url = await ref.getDownloadURL();
      debugPrint('MarketplaceService: uploaded image $index, url=$url');
      return url;
    } catch (e, st) {
      debugPrint('MarketplaceService.uploadListingImage error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> deleteListingImages(String sellerId, String listingId) async {
    try {
      final ref = _storage.ref('listing_images/$sellerId/$listingId');
      final list = await ref.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (_) {}
  }
}
