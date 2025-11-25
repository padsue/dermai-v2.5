import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/cache_service.dart';
import '../services/stream_service.dart';

class BookingRepository {
  final BookingService _bookingService;
  final CacheService _cacheService;
  final StreamService _streamService;

  BookingRepository(
      this._bookingService, this._cacheService, this._streamService);

  Future<void> createBooking(BookingModel booking) async {
    // 1. Get a new ID from Firestore
    final newId = _bookingService.getNewBookingId();
    booking.id = newId;

    // 2. Save booking to Firestore
    await _bookingService.addBooking(booking);

    // 3. Cache the booking
    await _cacheService.cacheBooking(booking);
  }

  Stream<List<BookingModel>> getUpcomingBookingsStream(String userId) {
    return _streamService.getUpcomingBookingsStream(userId);
  }

  Future<void> cancelBooking(BookingModel booking, String reason) async {
    // 1. Update booking object
    final updatedBooking = BookingModel(
      id: booking.id,
      userId: booking.userId,
      doctorId: booking.doctorId,
      appointmentDate: booking.appointmentDate,
      appointmentTime: booking.appointmentTime,
      status: 'Cancelled',
      createdAt: booking.createdAt,
      condition: booking.condition,
      type: booking.type,
      notes: booking.notes,
      cancellationReason: reason,
    );

    // 2. Update in Firestore
    await _bookingService.updateBooking(updatedBooking);

    // 3. Update in Cache
    await _cacheService.cacheBooking(updatedBooking);
  }
}
