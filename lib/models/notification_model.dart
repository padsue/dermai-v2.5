import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 5)
class NotificationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isRead;

  @HiveField(6)
  final String? type; // e.g., 'booking', 'profile'

  @HiveField(7)
  final String? relatedId; // e.g., bookingId

  @HiveField(8)
  final String? doctorId;

  @HiveField(9)
  final String? senderType; // e.g., 'patient', 'doctor', 'system'

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.relatedId,
    this.doctorId,
    this.senderType,
  });

  factory NotificationModel.fromMap(
      Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'],
      relatedId: data['relatedId'],
      doctorId: data['doctorId'],
      senderType: data['senderType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
      'relatedId': relatedId,
      'doctorId': doctorId,
      'senderType': senderType,
    };
  }
}
