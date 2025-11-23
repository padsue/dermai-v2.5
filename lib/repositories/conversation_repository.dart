import '../models/conversation_model.dart';
import '../services/cache_service.dart';
import '../services/stream_service.dart';

class ConversationRepository {
  final CacheService _cacheService;
  final StreamService _streamService;

  ConversationRepository(this._cacheService, this._streamService);

  Stream<List<ConversationModel>> getConversationsStreamForUser(String userId) {
    return _streamService.getConversationsStream(userId);
  }

  Future<List<ConversationModel>> getConversationsForUser(String userId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedConversations =
          _cacheService.getCachedConversationsForUser(userId);
      if (cachedConversations.isNotEmpty) {
        return cachedConversations;
      }
    }
    
    return [];
  }
}
