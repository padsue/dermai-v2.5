import '../models/user_model.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../services/stream_service.dart';

class UserRepository {
  final DatabaseService _dbService;
  final CacheService _cacheService;
  final StreamService _streamService;

  UserRepository(this._dbService, this._cacheService, this._streamService);

  Stream<UserModel?> getUserStream(String userId) {
    return _streamService.getUserStream(userId);
  }

  Future<UserModel?> getUser(String userId, {bool forceRefresh = false}) async {
    // If we aren't forcing a refresh, try the cache first.
    if (!forceRefresh) {
      final cachedUser = _cacheService.getCachedUser(userId);
      if (cachedUser != null) {
        return cachedUser;
      }
    }

    // If not in cache or forcing refresh, fetch from the network.
    try {
      final doc = await _dbService.getUserData(userId);
      if (doc.exists) {
        final user =
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        // Cache the fresh data.
        await _cacheService.cacheUserData(user);
        return user;
      }
    } catch (e) {
      // If network fails, fall back to cache one last time.
      return _cacheService.getCachedUser(userId);
    }
    return null;
  }

  UserModel? getFirstCachedUser() {
    return _cacheService.getFirstCachedUser();
  }

  // Add method to refresh user data and update cache
  Future<UserModel?> refreshUser(String userId) async {
    try {
      final doc = await _dbService.getUserData(userId);
      if (doc.exists) {
        final user =
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        await _cacheService.cacheUserData(user);
        return user;
      }
    } catch (e) {
      // If refresh fails, return cached version
      return _cacheService.getCachedUser(userId);
    }
    return null;
  }

  // Add method to clear cached user data
  Future<void> clearUserCache(String userId) async {
    await _cacheService.clearUserCache(userId);
  }

  // Add method to check if cache needs refresh
  bool shouldRefreshCache(String userId,
      {Duration maxAge = const Duration(minutes: 15)}) {
    return _cacheService.shouldRefreshCache(userId, maxAge: maxAge);
  }
}
