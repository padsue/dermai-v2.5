import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'booking_model.g.dart';

@HiveType(typeId: 4)
class BookingModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String doctorId;

  @HiveField(3)
  final DateTime appointmentDate;

  @HiveField(4)
  final String appointmentTime;

  @HiveField(5)
  final String status; // e.g., 'Pending', 'Upcoming', 'Completed', 'Cancelled'

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? condition;

  @HiveField(8)
  final String? type;

  @HiveField(9)
  final String? notes;

  BookingModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.createdAt,
    this.condition,
    this.type,
    this.notes,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BookingModel(
      id: documentId,
      userId: data['userId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      appointmentTime: data['appointmentTime'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      condition: data['condition'],
      type: data['type'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'condition': condition,
      'type': type,
      'notes': notes,
    };
  }
}
