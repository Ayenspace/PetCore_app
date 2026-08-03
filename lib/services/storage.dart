import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String uid, XFile xFile) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    if (kIsWeb) {
      final bytes = await xFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(xFile.path), SettableMetadata(contentType: 'image/jpeg'));
    }
    return await ref.getDownloadURL();
  }

  Future<String> uploadPetPhoto(String uid, String petId, XFile xFile) async {
    final ref = _storage.ref('pet_photos/$uid/$petId.jpg');
    if (kIsWeb) {
      final bytes = await xFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(xFile.path), SettableMetadata(contentType: 'image/jpeg'));
    }
    return await ref.getDownloadURL();
  }
}
