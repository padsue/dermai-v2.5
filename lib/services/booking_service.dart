import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addBooking(BookingModel booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  String getNewBookingId() {
    return _db.collection('bookings').doc().id;
  }

  Future<void> updateBooking(BookingModel booking) async {
    await _db.collection('bookings').doc(booking.id).update(booking.toMap());
  }
}
