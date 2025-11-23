import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'conversation_model.g.dart';

@HiveType(typeId: 7)
class ConversationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String doctorId;

  @HiveField(2)
  final String patientId;

  @HiveField(3)
  final String lastMessage;

  @HiveField(4)
  final DateTime lastMessageTime;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool unreadByDoctor;

  @HiveField(8)
  final bool unreadByPatient;

  @HiveField(9)
  String? participantName;

  @HiveField(10)
  String? participantAvatar;

  @HiveField(11)
  int unreadCount;

  ConversationModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadByDoctor,
    required this.unreadByPatient,
    this.participantName,
    this.participantAvatar,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromMap(
      Map<String, dynamic> data, String documentId) {
    final conversation = ConversationModel(
      id: documentId,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadByDoctor: data['unreadByDoctor'] ?? false,
      unreadByPatient: data['unreadByPatient'] ?? false,
    );
    // unreadCount will be set separately
    return conversation;
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadByDoctor': unreadByDoctor,
      'unreadByPatient': unreadByPatient,
    };
  }
}
