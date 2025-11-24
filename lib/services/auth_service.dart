import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cache_service.dart';
import '../models/user_model.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth;
  final DatabaseService _db;
  final CacheService _cache;

  AuthService(this._auth, this._db, this._cache);

  DatabaseService get db => _db;
  CacheService get cache => _cache;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Cache will be updated automatically by DatabaseService when we fetch user data
        final doc = await _db.getUserData(userCredential.user!.uid);
        if (doc.exists) {
          final userModel =
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          await _cache.cacheUserData(userModel);
        }
        await _cache.cacheLoginState(true);
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email,
      String password,
      String firstName,
      String lastName,
      String username, {
    String? phoneNumber,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
    DateTime? dateOfBirth,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Removed Firebase email verification - now using custom OTP
        final userData = {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'region': region,
          'province': province,
          'municipality': municipality,
          'barangay': barangay,
          'dateOfBirth': dateOfBirth,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
          'isPhoneNumberVerified': false,
          'userType': 'user',
        };
        // Cache will be updated automatically by DatabaseService
        await _db.addUserData(userCredential.user!.uid, userData);
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _db.updateUserData(userCredential.user!.uid, {
          'isPhoneNumberVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> updateUserProfile(
      {String? firstName, String? lastName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> dataToUpdate = {};

    if (firstName != null || lastName != null) {
      String currentDisplayName = user.displayName ?? '';
      String newDisplayName =
          '${firstName ?? currentDisplayName.split(' ').first} ${lastName ?? (currentDisplayName.split(' ').length > 1 ? currentDisplayName.split(' ').last : '')}'
              .trim();
      if (newDisplayName.isNotEmpty) {
        await user.updateDisplayName(newDisplayName);
        if (firstName != null) dataToUpdate['firstName'] = firstName;
        if (lastName != null) dataToUpdate['lastName'] = lastName;
      }
    }

    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
      dataToUpdate['photoUrl'] = photoUrl;
    }

    if (dataToUpdate.isNotEmpty) {
      // Cache will be updated automatically by DatabaseService
      await _db.updateUserData(user.uid, dataToUpdate);
    }
  }

  Future<String> uploadAndUpdateProfilePhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Upload image to Firebase Storage
      final String photoUrl = await _db.uploadProfileImage(user.uid, imageFile);

      // Update Firebase Auth profile
      await user.updatePhotoURL(photoUrl);

      // Cache will be updated automatically by DatabaseService
      await _db.updateUserPhoto(user.uid, photoUrl);

      return photoUrl;
    } catch (e) {
      throw Exception('Failed to update profile photo: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _cache.clearAll();
  }

  Future<void> updateUserVerificationStatus(String uid) async {
    // Cache will be updated automatically by DatabaseService
    return _db.updateUserData(uid, {
      'isEmailVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
