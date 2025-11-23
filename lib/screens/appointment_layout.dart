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
                    child: const Tooltip(
                      message: 'Confirm',
                      child: Icon(Icons.check),
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
            Expanded(
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
          ],
        ),
      ),
    );
  }
}