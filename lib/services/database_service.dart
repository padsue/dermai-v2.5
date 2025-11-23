import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import 'cache_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CacheService _cacheService;

  DatabaseService(this._cacheService);

  Future<void> addUserData(String userId, Map<String, dynamic> userData) async {
    await _db.collection('users').doc(userId).set(userData);

    // Automatically update cache after adding user data
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      final userModel =
          UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      await _cacheService.cacheUserData(userModel);
    }
  }

  Future<void> addDoctorData(Map<String, dynamic> doctorData) async {
    await _db.collection('doctors').add(doctorData);
  }

  Future<QuerySnapshot> getAllDoctors() {
    return _db.collection('doctors').get();
  }

  Future<QuerySnapshot> getReviewsForDoctor(String doctorId, {int limit = 5}) {
    return _db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }

  Future<DocumentSnapshot> getUserData(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).update(data);

    // Automatically update cache after updating user data
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      final userModel =
          UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      await _cacheService.cacheUserData(userModel);
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file to firebase storage
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> updateUserPhoto(String userId, String photoUrl) async {
    await _db.collection('users').doc(userId).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Automatically update cache after updating photo
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      final userModel =
          UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      await _cacheService.cacheUserData(userModel);
    }
  }

  Future<void> addReview(Map<String, dynamic> reviewData) async {
    await _db.collection('reviews').add(reviewData);
  }
}
