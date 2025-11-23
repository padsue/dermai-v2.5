import 'package:cloud_firestore/cloud_firestore.dart';

/// Calculates dynamic stats for a doctor: totalReviews, totalClients (unique users from bookings with specific statuses), and average rating.
/// Returns a map with keys: 'totalReviews' (int), 'totalClients' (int), 'rating' (double).
Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
  try {
    final db = FirebaseFirestore.instance;

    // Fetch reviews to compute totalReviews and average rating
    final reviewsSnapshot = await db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final reviews = reviewsSnapshot.docs;
    final totalReviews = reviews.length;

    double averageRating = 0.0;
    if (totalReviews > 0) {
      final totalRating = reviews.fold<double>(
        0.0,
        (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final val = data['rating'];
          if (val is num) return sum + val.toDouble();
          if (val is String) return sum + (double.tryParse(val) ?? 0.0);
          return sum;
        },
      );
      averageRating = totalRating / totalReviews;
    }

    // Fetch bookings with statuses that count toward unique patients
    const allowedStatuses = ['Done', 'Confirmed', 'Rescheduled'];
    Query bookingsQuery =
        db.collection('bookings').where('doctorId', isEqualTo: doctorId);

    // Firestore supports whereIn for arrays of values (<=10)
    bookingsQuery = bookingsQuery.where('status', whereIn: allowedStatuses);

    final bookingsSnapshot = await bookingsQuery.get();
    final bookings = bookingsSnapshot.docs;

    // Safely extract userId from each booking document
    final uniqueUserIds = bookings
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userId'] as String?;
        })
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();

    final totalClients = uniqueUserIds.length;

    return {
      'totalReviews': totalReviews,
      'totalClients': totalClients,
      'rating': averageRating,
    };
  } catch (e) {
    // Return defaults on error
    return {
      'totalReviews': 0,
      'totalClients': 0,
      'rating': 0.0,
    };
  }
}

/// Generates a display name for the doctor (e.g., "Dr. First Last").
String getDoctorDisplayName(String firstName, String lastName) {
  return 'Dr. $firstName $lastName';
}
