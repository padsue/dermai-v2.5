import 'package:dermai/models/doctor_model.dart';
import 'package:dermai/screens/appointment_screen.dart';
import 'package:dermai/screens/doctors_profile_screen.dart';
import 'package:dermai/screens/patient_details_screen.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/widgets/custom_app_bar.dart';
import 'package:dermai/widgets/step_progress_bar.dart';
import 'package:flutter/material.dart';

class AppointmentLayout extends StatefulWidget {
  final DoctorModel doctor;
  const AppointmentLayout({super.key, required this.doctor});

  @override
  State<AppointmentLayout> createState() => _AppointmentLayoutState();
}

class _AppointmentLayoutState extends State<AppointmentLayout> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isBooking = false;

  // Keys to access child state
  final GlobalKey<AppointmentScreenState> _appointmentScreenKey =
      GlobalKey<AppointmentScreenState>();
  final GlobalKey<PatientDetailsScreenState> _patientDetailsScreenKey =
      GlobalKey<PatientDetailsScreenState>();

  DateTime? _selectedDay;
  String? _selectedTime;

  final List<String> _stepTitles = [
    'Doctor Profile',
    'Book a Date',
    'Patient Details'
  ];

  final List<String> _stepDescriptions = [
    'Review doctor\'s credentials and experience',
    'Select your preferred appointment time',
    'Provide your contact and medical information'
  ];

  String _getActionButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Book Appointment';
      case 1:
        return 'Confirm Date';
      case 2:
        return 'Complete Booking';
      default:
        return 'Next';
    }
  }

  Future<void> _showBookingConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Confirm Booking',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm your appointment details:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _confirmationRow(Icons.person, 'Doctor', 'Dr. ${widget.doctor.displayName}'),
              const SizedBox(height: 8),
              _confirmationRow(
                Icons.calendar_today,
                'Date',
                _selectedDay != null
                    ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                    : 'N/A',
              ),
              const SizedBox(height: 8),
              _confirmationRow(Icons.access_time, 'Time', _selectedTime ?? 'N/A'),
              const SizedBox(height: 8),
              _confirmationRow(
                Icons.attach_money,
                'Consultation Fee',
                'P${widget.doctor.consultFee.toStringAsFixed(0)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isBooking = true;
      });
      try {
        await _patientDetailsScreenKey.currentState?.saveAndProceed();
      } finally {
        if (mounted) {
          setState(() {
            _isBooking = false;
          });
        }
      }
    }
  }

  Widget _confirmationRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleAppBarAction() async {
    switch (_currentStep) {
      case 0:
        _nextPage();
        break;
      case 1:
        final appointmentState = _appointmentScreenKey.currentState;
        if (appointmentState != null && appointmentState.validateSelection()) {
          final selection = appointmentState.getSelection();
          setState(() {
            _selectedDay = selection['day'];
            _selectedTime = selection['time'];
          });
          _nextPage();
        }
        break;
      case 2:
        await _showBookingConfirmation();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          showBackButton: true,
          title: Text(
            _stepTitles[_currentStep],
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          actions: [
            _isBooking
                ? const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : GestureDetector(
                    onTap: _handleAppBarAction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Text(
                          _getActionButtonText(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
        body: Column(
          children: [
            StepProgressBar(
              currentStep: _currentStep,
              totalSteps: 3,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cherryBlossom.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepDescriptions[_currentStep],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Consultation Fee: P${widget.doctor.consultFee.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    DoctorsProfileScreen(
                      doctor: widget.doctor,
                    ),
                    AppointmentScreen(
                      key: _appointmentScreenKey,
                      doctor: widget.doctor,
                    ),
                    if (_selectedDay != null && _selectedTime != null)
                      PatientDetailsScreen(
                        key: _patientDetailsScreenKey,
                        doctor: widget.doctor,
                        selectedDay: _selectedDay!,
                        selectedTime: _selectedTime!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isBooking ? null : _handleAppBarAction,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: _isBooking
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(
            _isBooking ? 'Booking...' : _getActionButtonText(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}