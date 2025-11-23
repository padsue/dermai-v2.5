import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';

class AppointmentUtils {
  static DateTime parseTime(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour <= 5) hour += 12;
    return DateTime(2023, 1, 1, hour, minute);
  }

  static List<String> generateSlots(DateTime start, DateTime end) {
    List<String> slots = [];
    DateTime current = start;
    while (current.isBefore(end)) {
      if (current.hour == 12) {
        current = current.add(const Duration(minutes: 30));
        continue;
      }
      int displayHour = current.hour;
      if (displayHour > 12) displayHour -= 12;
      if (displayHour == 0) displayHour = 12;
      String time =
          "${displayHour}:${current.minute.toString().padLeft(2, '0')}";
      slots.add(time);
      current = current.add(const Duration(minutes: 30));
    }
    return slots;
  }

  static Future<List<String>> getBookedSlots(
      DateTime day, String doctorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate', isEqualTo: Timestamp.fromDate(day))
          .where('status', whereIn: ['Pending', 'Upcoming']).get();
      return snapshot.docs
          .map((doc) => doc['appointmentTime'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> getAvailableSlots(
      DateTime day, DoctorModel doctor) async {
    final dayName = DateFormat('EEEE').format(day).toLowerCase();
    final hours = doctor.workingHours[dayName];
    if (hours == null || hours['start'] == null || hours['end'] == null)
      return [];
    final start = parseTime(hours['start']);
    final end = parseTime(hours['end']);
    return generateSlots(start, end);
  }
}
