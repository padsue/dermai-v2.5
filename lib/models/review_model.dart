import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'review_model.g.dart';

@HiveType(typeId: 6)
class ReviewModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String doctorId;

  @HiveField(3)
  final double rating;

  @HiveField(4)
  final String comment;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final String? response;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.response,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ReviewModel(
      id: documentId,
      userId: data['userId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      response: data['response'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'response': response,
    };
  }
}
