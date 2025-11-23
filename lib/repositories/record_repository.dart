import '../models/detection_result.dart';
import '../services/cache_service.dart';
import '../services/record_service.dart';
import '../services/stream_service.dart';

class RecordRepository {
  final RecordService _recordService;
  final CacheService _cacheService;
  final StreamService _streamService;

  RecordRepository(
      this._recordService, this._cacheService, this._streamService);

  Future<void> saveRecord(DetectionResultModel record) async {
    // 1. Get a new ID from Firestore
    final newId = _recordService.getNewRecordId();
    record.id = newId;

    // 2. Upload images and get URLs
    for (var imageResult in record.imageResults) {
      if (imageResult.localFile != null) {
        final imageUrl = await _recordService.uploadRecordImage(
          record.userId,
          record.id,
          imageResult.localFile!,
        );
        imageResult.imageUrl = imageUrl;
      }
    }

    // 3. Save record to Firestore
    await _recordService.addRecord(record);

    // 4. Cache the record
    await _cacheService.cacheRecord(record);
  }

  Stream<List<DetectionResultModel>> getRecordsStreamForUser(String userId) {
    return _streamService.getRecordsStream(userId);
  }

  Future<List<DetectionResultModel>> getUserRecords(String userId) async {
    // Try cache first
    final cachedRecords = _cacheService.getCachedRecordsForUser(userId);
    if (cachedRecords.isNotEmpty) {
      // Sort by date descending
      cachedRecords.sort((a, b) => b.scanDate.compareTo(a.scanDate));
      return cachedRecords;
    }

    // Fetch from Firestore
    final querySnapshot = await _recordService.getUserRecords(userId);
    final records = querySnapshot.docs
        .map((doc) => DetectionResultModel.fromMap(doc.data(), doc.id))
        .toList();

    // Sort by date descending
    records.sort((a, b) => b.scanDate.compareTo(a.scanDate));

    // Cache them
    for (var record in records) {
      await _cacheService.cacheRecord(record);
    }

    return records;
  }
}
