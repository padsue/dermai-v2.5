import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection_result.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class CacheService {
  static const String sessionBoxName = 'session';
  static const String userBoxName = 'user';
  static const String recordBoxName = 'records';
  static const String doctorBoxName = 'doctors';
  static const String bookingBoxName = 'bookings';
  static const String notificationBoxName = 'notifications';
  static const String reviewBoxName = 'reviews';
  static const String cacheTimestampBoxName = 'cache_timestamps';
  static const String conversationBoxName = 'conversations';
  static const String messageBoxName = 'messages';

  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(DetectionResultModelAdapter().typeId)) {
      Hive.registerAdapter(DetectionResultModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ImageResultModelAdapter().typeId)) {
      Hive.registerAdapter(ImageResultModelAdapter());
    }
    if (!Hive.isAdapterRegistered(DoctorModelAdapter().typeId)) {
      Hive.registerAdapter(DoctorModelAdapter());
    }
    if (!Hive.isAdapterRegistered(BookingModelAdapter().typeId)) {
      Hive.registerAdapter(BookingModelAdapter());
    }
    if (!Hive.isAdapterRegistered(NotificationModelAdapter().typeId)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ReviewModelAdapter().typeId)) {
      Hive.registerAdapter(ReviewModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ConversationModelAdapter().typeId)) {
      Hive.registerAdapter(ConversationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageAttachmentAdapter().typeId)) {
      Hive.registerAdapter(MessageAttachmentAdapter());
    }

    await Hive.openBox(sessionBoxName);
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<DetectionResultModel>(recordBoxName);
    await Hive.openBox<DoctorModel>(doctorBoxName);
    await Hive.openBox<BookingModel>(bookingBoxName);
    await Hive.openBox<NotificationModel>(notificationBoxName);
    await Hive.openBox<ReviewModel>(reviewBoxName);
    await Hive.openBox<DateTime>(cacheTimestampBoxName);
    await Hive.openBox<ConversationModel>(conversationBoxName);
    await Hive.openBox<MessageModel>(messageBoxName);
  }

  // Session Management
  Box get _sessionBox => Hive.box(sessionBoxName);

  Future<void> cacheLoginState(bool isLoggedIn) async {
    await _sessionBox.put('isLoggedIn', isLoggedIn);
  }

  bool isLoggedIn() {
    return _sessionBox.get('isLoggedIn', defaultValue: false);
  }

  // User Data Management
  Box<UserModel> get _userBox => Hive.box<UserModel>(userBoxName);

  // Cache timestamp management
  Box<DateTime> get _timestampBox => Hive.box<DateTime>(cacheTimestampBoxName);

  Future<void> cacheUserData(UserModel user) async {
    if (user.isInBox) {
      await user.save();
    } else {
      await _userBox.put(user.uid, user);
    }

    // Update timestamp for this user
    await _timestampBox.put(user.uid, DateTime.now());
  }

  UserModel? getCachedUser(String uid) {
    return _userBox.get(uid);
  }

  UserModel? getFirstCachedUser() {
    if (_userBox.isNotEmpty) {
      return _userBox.values.first;
    }
    return null;
  }

  // Check if cache should be refreshed based on timestamp
  bool shouldRefreshCache(String uid,
      {Duration maxAge = const Duration(minutes: 15)}) {
    final timestamp = _timestampBox.get(uid);
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > maxAge;
  }

  // Clear specific user cache
  Future<void> clearUserCache(String uid) async {
    await _userBox.delete(uid);
    await _timestampBox.delete(uid);
  }

  // Doctor Data Management
  Box<DoctorModel> get _doctorBox => Hive.box<DoctorModel>(doctorBoxName);

  Future<void> cacheAllDoctors(List<DoctorModel> doctors) async {
    await _doctorBox.clear();
    final Map<String, DoctorModel> doctorMap = {
      for (var doc in doctors) doc.id: doc
    };
    await _doctorBox.putAll(doctorMap);
  }

  List<DoctorModel> getAllCachedDoctors() {
    return _doctorBox.values.toList();
  }

  // Review Data Management
  Box<ReviewModel> get _reviewBox => Hive.box<ReviewModel>(reviewBoxName);

  Future<void> cacheReviewsForDoctor(
      String doctorId, List<ReviewModel> reviews) async {
    final oldKeys =
        _reviewBox.values.where((r) => r.doctorId == doctorId).map((r) => r.id);
    await _reviewBox.deleteAll(oldKeys);

    final Map<String, ReviewModel> reviewMap = {
      for (var review in reviews) review.id: review
    };
    await _reviewBox.putAll(reviewMap);
  }

  List<ReviewModel> getCachedReviewsForDoctor(String doctorId) {
    return _reviewBox.values
        .where((review) => review.doctorId == doctorId)
        .toList();
  }

  // Booking Data Management
  Box<BookingModel> get _bookingBox => Hive.box<BookingModel>(bookingBoxName);

  Future<void> cacheBooking(BookingModel booking) async {
    await _bookingBox.put(booking.id, booking);
  }

  Future<void> cacheAllBookingsForUser(
      String userId, List<BookingModel> bookings) async {
    // Remove old bookings for this user to handle deletions
    final oldKeys =
        _bookingBox.values.where((b) => b.userId == userId).map((b) => b.id);
    await _bookingBox.deleteAll(oldKeys);

    // Add the new/updated list
    final Map<String, BookingModel> bookingMap = {
      for (var booking in bookings) booking.id: booking
    };
    await _bookingBox.putAll(bookingMap);
  }

  List<BookingModel> getCachedBookingsForUser(String userId) {
    return _bookingBox.values
        .where((booking) => booking.userId == userId)
        .toList();
  }

  // Notification Data Management
  Box<NotificationModel> get _notificationBox =>
      Hive.box<NotificationModel>(notificationBoxName);

  Future<void> cacheAllNotificationsForUser(
      String userId, List<NotificationModel> notifications) async {
    // Remove old notifications for this user to handle deletions
    final oldKeys = _notificationBox.values
        .where((n) => n.userId == userId)
        .map((n) => n.id);
    await _notificationBox.deleteAll(oldKeys);

    // Add the new/updated list
    final Map<String, NotificationModel> notificationMap = {
      for (var notif in notifications) notif.id: notif
    };
    await _notificationBox.putAll(notificationMap);
  }

  Future<void> updateCachedNotification(NotificationModel notification) async {
    await _notificationBox.put(notification.id, notification);
  }

  // Record Data Management
  Box<DetectionResultModel> get _recordBox =>
      Hive.box<DetectionResultModel>(recordBoxName);

  Future<void> cacheRecord(DetectionResultModel record) async {
    await _recordBox.put(record.id, record);
  }

  Future<void> cacheAllRecordsForUser(
      String userId, List<DetectionResultModel> records) async {
    // Remove old records for this user to handle deletions
    final oldKeys =
        _recordBox.values.where((r) => r.userId == userId).map((r) => r.id);
    await _recordBox.deleteAll(oldKeys);

    // Add the new/updated list
    final Map<String, DetectionResultModel> recordMap = {
      for (var record in records) record.id: record
    };
    await _recordBox.putAll(recordMap);
  }

  List<DetectionResultModel> getCachedRecordsForUser(String userId) {
    return _recordBox.values
        .where((record) => record.userId == userId)
        .toList();
  }

  // Conversation Data Management
  Box<ConversationModel> get _conversationBox =>
      Hive.box<ConversationModel>(conversationBoxName);

  Future<void> cacheAllConversationsForUser(
      String userId, List<ConversationModel> conversations) async {
    final oldKeys = _conversationBox.values
        .where((c) => c.patientId == userId)
        .map((c) => c.id);
    await _conversationBox.deleteAll(oldKeys);

    final Map<String, ConversationModel> conversationMap = {
      for (var conv in conversations) conv.id: conv
    };
    await _conversationBox.putAll(conversationMap);
  }

  List<ConversationModel> getCachedConversationsForUser(String userId) {
    return _conversationBox.values
        .where((conversation) => conversation.patientId == userId)
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  // Message Data Management
  Box<MessageModel> get _messageBox => Hive.box<MessageModel>(messageBoxName);

  Future<void> cacheAllMessagesForConversation(
      String conversationId, List<MessageModel> messages) async {
    final oldKeys = _messageBox.values
        .where((m) => m.conversationId == conversationId)
        .map((m) => m.id);
    await _messageBox.deleteAll(oldKeys);

    final Map<String, MessageModel> messageMap = {
      for (var msg in messages) msg.id: msg
    };
    await _messageBox.putAll(messageMap);
  }

  List<MessageModel> getCachedMessagesForConversation(String conversationId) {
    return _messageBox.values
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Update existing user in cache
  Future<void> updateCachedUser(
      String uid, Map<String, dynamic> updates) async {
    final cachedUser = getCachedUser(uid);
    if (cachedUser != null) {
      // Create updated user model
      UserModel updatedUser = cachedUser.copyWith(
        email: updates['email'] ?? cachedUser.email,
        firstName: updates['firstName'] ?? cachedUser.firstName,
        lastName: updates['lastName'] ?? cachedUser.lastName,
        middleName: updates['middleName'] ?? cachedUser.middleName,
        username: updates['username'] ?? cachedUser.username,
        photoUrl: updates['photoUrl'] ?? cachedUser.photoUrl,
        sex: updates['sex'] ?? cachedUser.sex,
        dateOfBirth: updates['dateOfBirth'] ?? cachedUser.dateOfBirth,
        contactNumber: updates['contactNumber'] ?? cachedUser.contactNumber,
        region: updates['region'] ?? cachedUser.region,
        province: updates['province'] ?? cachedUser.province,
        municipality: updates['municipality'] ?? cachedUser.municipality,
        barangay: updates['barangay'] ?? cachedUser.barangay,
        updatedAt: DateTime.now(),
      );

      await cacheUserData(updatedUser);
    }
  }

  Future<void> clearAll() async {
    await _sessionBox.clear();
    await _userBox.clear();
    await _recordBox.clear();
    await _doctorBox.clear();
    await _bookingBox.clear();
    await _notificationBox.clear();
    await _reviewBox.clear();
    await _timestampBox.clear();
    await _conversationBox.clear();
    await _messageBox.clear();
  }
}
