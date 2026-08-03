import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<String> uploadPetPhoto(String uid, String petId, File file) async {
    final ref = _storage.ref('pet_photos/$uid/$petId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
}
