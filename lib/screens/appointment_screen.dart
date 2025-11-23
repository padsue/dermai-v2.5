import 'package:dermai/models/doctor_model.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/utils/app_theme.dart';
import 'package:dermai/utils/appointment_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;

  const AppointmentScreen({super.key, required this.doctor});

  @override
  State<AppointmentScreen> createState() => AppointmentScreenState();
}

class AppointmentScreenState extends State<AppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  String? _timeSelectionError;
  late Future<List<String>> _availableSlotsFuture;
  late Future<List<String>> _bookedSlotsFuture;
  late Future<List<String>> _combinedFuture;

  bool isTimeSelected() {
    return _selectedDay != null && _selectedTime != null;
  }

  bool validateSelection() {
    if (isTimeSelected()) {
      if (_timeSelectionError != null) {
        setState(() {
          _timeSelectionError = null;
        });
      }
      return true;
    } else {
      setState(() {
        _timeSelectionError = 'Please select a date and time slot to proceed.';
      });
      return false;
    }
  }

  Map<String, dynamic> getSelection() {
    return {'day': _selectedDay, 'time': _selectedTime};
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _availableSlotsFuture =
        AppointmentUtils.getAvailableSlots(_selectedDay!, widget.doctor);
    _bookedSlotsFuture =
        AppointmentUtils.getBookedSlots(_selectedDay!, widget.doctor.id);
    _combinedFuture = Future.wait([_availableSlotsFuture, _bookedSlotsFuture])
        .then((results) => results[0]);
  }

  bool _isDayEnabled(DateTime day, DoctorModel doctor) {
    final dayName = DateFormat('EEEE').format(day).toLowerCase();
    final hours = doctor.workingHours[dayName];
    return hours != null && hours['enabled'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonExt = theme.extension<ButtonStyleExtension>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select date & time slot",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "The timing you see is in your local time zone (Asia/Manila | GMT +8:00)",
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),

          // Calendar Widget
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.w600),
              weekendStyle: theme.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              selectedTextStyle:
                  theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
              defaultTextStyle: theme.textTheme.bodyMedium!,
              weekendTextStyle: theme.textTheme.bodyMedium!,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _availableSlotsFuture = AppointmentUtils.getAvailableSlots(
                    _selectedDay!, widget.doctor);
                _bookedSlotsFuture = AppointmentUtils.getBookedSlots(
                    _selectedDay!, widget.doctor.id);
                _combinedFuture =
                    Future.wait([_availableSlotsFuture, _bookedSlotsFuture])
                        .then((results) => results[0]);
              });
            },
          ),
          const SizedBox(height: 24),

          // Time Slots
          if (_selectedDay != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text("Morning",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text("Afternoon",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _combinedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonLoader();
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading time slots.'));
                }
                final allSlots = snapshot.data ?? [];
                return FutureBuilder<List<String>>(
                  future: _bookedSlotsFuture,
                  builder: (context, bookedSnapshot) {
                    final bookedSlots = bookedSnapshot.data ?? [];
                    final isEnabled =
                        _isDayEnabled(_selectedDay!, widget.doctor);
                    final morningSlotsFiltered = allSlots
                        .where((slot) =>
                            AppointmentUtils.parseTime(slot).hour < 12)
                        .toList();
                    final afternoonSlotsFiltered = allSlots
                        .where((slot) =>
                            AppointmentUtils.parseTime(slot).hour >= 12)
                        .toList();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning Columns
                        _buildTimeColumn(
                            morningSlotsFiltered.sublist(
                                0, (morningSlotsFiltered.length / 2).ceil()),
                            bookedSlots,
                            isEnabled),
                        const SizedBox(width: 10),
                        _buildTimeColumn(
                            morningSlotsFiltered.sublist(
                                (morningSlotsFiltered.length / 2).ceil()),
                            bookedSlots,
                            isEnabled),
                        const SizedBox(width: 16),
                        // Afternoon Columns
                        _buildTimeColumn(
                            afternoonSlotsFiltered.sublist(
                                0, (afternoonSlotsFiltered.length / 2).ceil()),
                            bookedSlots,
                            isEnabled),
                        const SizedBox(width: 10),
                        _buildTimeColumn(
                            afternoonSlotsFiltered.sublist(
                                (afternoonSlotsFiltered.length / 2).ceil()),
                            bookedSlots,
                            isEnabled),
                      ],
                    );
                  },
                );
              },
            ),
          ] else ...[
            const Center(
                child:
                    Text('Please select a date to view available time slots.')),
          ],
          if (_timeSelectionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(
                child: Text(
                  _timeSelectionError!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkeletonTimeColumn(4),
        const SizedBox(width: 10),
        _buildSkeletonTimeColumn(4),
        const SizedBox(width: 16),
        _buildSkeletonTimeColumn(3),
        const SizedBox(width: 10),
        _buildSkeletonTimeColumn(3),
      ],
    );
  }

  Widget _buildSkeletonTimeColumn(int count) {
    return Expanded(
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildSkeletonTimeSlot(),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonTimeSlot() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Container(
          height: 16,
          width: 40,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildTimeColumn(
      List<String> slots, List<String> bookedSlots, bool isDayEnabled) {
    return Expanded(
      child: Column(
        children: slots.map((time) {
          final isBooked = bookedSlots.contains(time) || !isDayEnabled;
          final isPast = _isSlotInPast(time, _selectedDay!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildTimeSlot(time, isBooked: isBooked || isPast),
          );
        }).toList(),
      ),
    );
  }

  bool _isSlotInPast(String time, DateTime selectedDay) {
    final parsedTime = AppointmentUtils.parseTime(time);
    final slotDateTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      parsedTime.hour,
      parsedTime.minute,
    );
    return slotDateTime.isBefore(DateTime.now());
  }

  Widget _buildTimeSlot(String time, {bool isBooked = false}) {
    final isSelected = _selectedTime == time;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                _selectedTime = time;
                if (_timeSelectionError != null) {
                  _timeSelectionError = null;
                }
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isBooked ? Colors.grey.shade400 : Colors.grey.shade400),
            width: 1.5,
          ),
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isBooked
                  ? Colors.grey.shade200
                  : theme.scaffoldBackgroundColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primary
                  : (isBooked ? Colors.grey : theme.textTheme.bodyLarge?.color),
            ),
          ),
        ),
      ),
    );
  }
}
