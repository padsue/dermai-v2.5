import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/detection_result.dart';

class RecordService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addRecord(DetectionResultModel record) async {
    await _db.collection('records').doc(record.id).set(record.toMap());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserRecords(
      String userId) async {
    return _db.collection('records').where('userId', isEqualTo: userId).get();
  }

  String getNewRecordId() {
    return _db.collection('records').doc().id;
  }

  Future<String> uploadRecordImage(
      String userId, String recordId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('records')
          .child(recordId)
          .child('image_$timestamp.jpg');

      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}
