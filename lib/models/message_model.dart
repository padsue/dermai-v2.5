import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 8)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String senderType;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final bool read;

  @HiveField(7)
  final List<MessageAttachment> attachments;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.timestamp,
    required this.read,
    required this.attachments,
  });

  bool get isMe => senderType == 'patient';

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderType: data['senderType'] ?? 'patient',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((att) =>
                  MessageAttachment.fromMap(att as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'attachments': attachments.map((att) => att.toMap()).toList(),
    };
  }
}

@HiveType(typeId: 9)
class MessageAttachment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String url;

  @HiveField(4)
  final int size;

  MessageAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.size,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> data) {
    return MessageAttachment(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      url: data['url'] ?? '',
      size: data['size'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'size': size,
    };
  }
}
