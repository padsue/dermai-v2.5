import '../models/doctor_model.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../services/stream_service.dart';
import '../utils/doctor_utils.dart';

class DoctorRepository {
  final DatabaseService _dbService;
  final CacheService _cacheService;
  final StreamService _streamService;

  DoctorRepository(this._dbService, this._cacheService, this._streamService);

  Stream<List<DoctorModel>> getDoctorsStream() {
    return _streamService.getDoctorsStream();
  }

  Future<List<DoctorModel>> getAllDoctors({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedDoctors = _cacheService.getAllCachedDoctors();
      if (cachedDoctors.isNotEmpty) {
        return cachedDoctors;
      }
    }

    try {
      final snapshot = await _dbService.getAllDoctors();
      final doctors = snapshot.docs
          .map((doc) =>
              DoctorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Calculate dynamic stats for each doctor
      for (final doctor in doctors) {
        final stats = await getDoctorStats(doctor.id);
        doctor.rating = stats['rating'] as double;
        doctor.totalClients = stats['totalClients'].toString();
        doctor.totalReviews = stats['totalReviews'].toString();
      }

      await _cacheService.cacheAllDoctors(doctors);
      return doctors;
    } catch (e) {
      return _cacheService.getAllCachedDoctors();
    }
  }
}
