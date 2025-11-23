import '../models/message_model.dart';
import '../services/cache_service.dart';
import '../services/stream_service.dart';

class MessageRepository {
  final CacheService _cacheService;
  final StreamService _streamService;

  MessageRepository(this._cacheService, this._streamService);

  Stream<List<MessageModel>> getMessagesStreamForConversation(
      String conversationId) {
    return _streamService.getMessagesStream(conversationId);
  }

  Future<List<MessageModel>> getMessagesForConversation(String conversationId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedMessages =
          _cacheService.getCachedMessagesForConversation(conversationId);
      if (cachedMessages.isNotEmpty) {
        return cachedMessages;
      }
    }

    return [];
  }
}
