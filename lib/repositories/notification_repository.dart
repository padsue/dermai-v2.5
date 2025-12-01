import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/stream_service.dart';
import '../services/cache_service.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _pushNotificationService;
  final StreamService _streamService;
  final CacheService _cacheService;

  NotificationRepository(
      this._pushNotificationService, this._streamService, this._cacheService);

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? relatedId,
    String? doctorId,
    String? senderType,
  }) async {
    final newDoc = _db.collection('notifications').doc();
    final notification = NotificationModel(
      id: newDoc.id,
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: type,
      relatedId: relatedId,
      doctorId: doctorId,
      senderType: senderType,
    );

    // Save to Firestore
    await newDoc.set(notification.toMap());

    // Local notification is now handled by the global listener in NotificationListenerWrapper
    // triggered by the Firestore document creation.
  }

  Stream<List<NotificationModel>> getNotificationsStreamForUser(String userId) {
    return _streamService.getNotificationsStream(userId);
  }

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('senderType', isNotEqualTo: 'patient')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> markAsRead(NotificationModel notification) async {
    // Update in Firestore
    await _db
        .collection('notifications')
        .doc(notification.id)
        .update({'isRead': true});

    // Update in cache for immediate UI feedback
    notification.isRead = true;
    await _cacheService.updateCachedNotification(notification);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _pushNotificationService.showNotification(title: title, body: body);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }
}
