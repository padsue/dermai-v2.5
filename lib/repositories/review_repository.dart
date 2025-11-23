import '../models/review_model.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../services/stream_service.dart';

class ReviewRepository {
  final DatabaseService _dbService;
  final CacheService _cacheService;
  final StreamService _streamService;

  ReviewRepository(this._dbService, this._cacheService, this._streamService);

  Stream<List<ReviewModel>> getReviewsStreamForDoctor(String doctorId) {
    return _streamService.getReviewsStreamForDoctor(doctorId);
  }

  Future<List<ReviewModel>> getReviewsForDoctor(String doctorId,
      {bool forceRefresh = false, int limit = 5}) async {
    if (!forceRefresh) {
      final cachedReviews = _cacheService.getCachedReviewsForDoctor(doctorId);
      if (cachedReviews.isNotEmpty) {
        return cachedReviews.take(limit).toList();
      }
    }

    try {
      final snapshot =
          await _dbService.getReviewsForDoctor(doctorId, limit: limit);
      final reviews = snapshot.docs
          .map((doc) =>
              ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      await _cacheService.cacheReviewsForDoctor(doctorId, reviews);
      return reviews;
    } catch (e) {
      return _cacheService
          .getCachedReviewsForDoctor(doctorId)
          .take(limit)
          .toList();
    }
  }

  Future<void> createReview({
    required String userId,
    required String doctorId,
    required double rating,
    required String comment,
  }) async {
    final reviewData = {
      'userId': userId,
      'doctorId': doctorId,
      'rating': rating,
      'comment': comment,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    await _dbService.addReview(reviewData);
  }
}
