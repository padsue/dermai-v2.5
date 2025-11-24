import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/notification_model.dart';
import '../models/detection_result.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'cache_service.dart';
import '../utils/doctor_utils.dart';

class StreamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CacheService _cacheService;

  StreamService(this._cacheService);

  /// Returns a stream of notifications for a given user, ordered by creation date.
  /// This stream also automatically updates the local cache.
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList())
        .doOnData((notifications) {
      _cacheService.cacheAllNotificationsForUser(userId, notifications);
    });
  }

  /// Returns a stream of a single user model.
  /// This stream also automatically updates the local cache.
  Stream<UserModel?> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    }).doOnData((user) {
      if (user != null) {
        _cacheService.cacheUserData(user);
      }
    });
  }

  /// Returns a stream of all doctors with calculated stats.
  /// This stream also automatically updates the local cache.
  Stream<List<DoctorModel>> getDoctorsStream() {
    final cachedDoctors = _cacheService.getAllCachedDoctors();

    return _db.collection('doctors').snapshots().asyncMap((snapshot) async {
      final doctors = snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate dynamic stats for each doctor
      for (final doctor in doctors) {
        final stats = await getDoctorStats(doctor.id);
        doctor.rating = stats['rating'] as double;
        doctor.totalClients = (stats['totalClients'] as int).toString();
        doctor.totalReviews = (stats['totalReviews'] as int).toString();
      }

      await _cacheService.cacheAllDoctors(doctors);
      return doctors;
    }).startWith(cachedDoctors);
  }

  /// Returns a stream of reviews for a given doctor.
  /// This stream also automatically updates the local cache.
  Stream<List<ReviewModel>> getReviewsStreamForDoctor(String doctorId) {
    return _db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList())
        .doOnData((reviews) {
      _cacheService.cacheReviewsForDoctor(doctorId, reviews);
    });
  }

  /// Returns a stream of upcoming bookings for a given user.
  /// This stream also automatically updates the local cache.
  Stream<List<BookingModel>> getUpcomingBookingsStream(String userId) {
    // Get start of today (midnight) to include all appointments for today
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    final cachedBookings = _cacheService
        .getCachedBookingsForUser(userId)
        .where((b) => 
          (b.appointmentDate.isAfter(startOfToday) || 
           b.appointmentDate.isAtSameMomentAs(startOfToday)) &&
          (b.status.toLowerCase() == 'pending' || 
           b.status.toLowerCase() == 'confirmed'))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) {
          // Filter out cancelled and completed bookings
          final bookings = snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .where((b) => 
              b.status.toLowerCase() == 'pending' || 
              b.status.toLowerCase() == 'confirmed')
            .toList();
          return bookings;
        })
        .doOnData((bookings) {
      _cacheService.cacheAllBookingsForUser(userId, bookings);
    }).startWith(cachedBookings);
  }

  /// Returns a stream of scan records for a given user, ordered by scan date.
  /// This stream also automatically updates the local cache.
  Stream<List<DetectionResultModel>> getRecordsStream(String userId) {
    return _db
        .collection('records')
        .where('userId', isEqualTo: userId)
        .orderBy('scanDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DetectionResultModel.fromMap(doc.data(), doc.id))
            .toList())
        .doOnData((records) {
      _cacheService.cacheAllRecordsForUser(userId, records);
    });
  }

  /// Returns a stream of conversations for a given user.
  /// This stream also automatically updates the local cache.
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _db
        .collection('conversations')
        .where('patientId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ConversationModel> conversations = [];

      for (var doc in snapshot.docs) {
        final conversation = ConversationModel.fromMap(doc.data(), doc.id);

        // Fetch doctor details
        final doctorDoc =
            await _db.collection('doctors').doc(conversation.doctorId).get();
        if (doctorDoc.exists) {
          final doctor = DoctorModel.fromMap(doctorDoc.data()!, doctorDoc.id);
          conversation.participantName = doctor.displayName;
          conversation.participantAvatar = doctor.imageUrl;
        }

        // Fetch unread message count
        final unreadQuery = await _db
            .collection('messages')
            .where('conversationId', isEqualTo: conversation.id)
            .where('senderType', isEqualTo: 'doctor')
            .where('read', isEqualTo: false)
            .get();
        conversation.unreadCount = unreadQuery.docs.length;

        conversations.add(conversation);
      }

      await _cacheService.cacheAllConversationsForUser(userId, conversations);
      return conversations;
    });
  }

  /// Returns a stream of messages for a given conversation.
  /// This stream also automatically updates the local cache.
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList())
        .doOnData((messages) {
      _cacheService.cacheAllMessagesForConversation(conversationId, messages);
    });
  }
}
