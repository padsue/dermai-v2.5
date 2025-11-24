import 'package:dermai/models/doctor_model.dart';
import 'package:dermai/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_colors.dart';
import '../widgets/date_picker_field.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/notification_repository.dart';
import '../utils/location_helper.dart';
import '../utils/user_utils.dart';

class PatientDetailsScreen extends StatefulWidget {
  final DoctorModel doctor;
  final DateTime selectedDay;
  final String selectedTime;

  const PatientDetailsScreen({
    super.key,
    required this.doctor,
    required this.selectedDay,
    required this.selectedTime,
  });

  @override
  State<PatientDetailsScreen> createState() => PatientDetailsScreenState();
}

class PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _notesController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  String? _selectedCondition;
  String? _doctorType;

  // Location dropdowns
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;

  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _municipalities = [];
  List<String> _barangays = [];

  final List<String> _conditions = [
    'Acne',
    'Actinic Keratosis',
    'Benign Tumors',
    'Eczema',
    'Lupus',
    'Melanoma',
    'Moles',
    'Psoriasis',
    'Rosacea',
    'Seborrheic Keratoses',
    'Skin Cancer',
    'Sunlight Damage',
    'Tinea',
    'Normal Skin',
    'Vascular Tumors',
    'Vitiligo',
    'Warts',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _doctorType = _mapSpecialtyToCategory(widget.doctor.specialty);
  }

  Future<void> _initializeData() async {
    await _loadLocations();
    await _loadUserData();
  }

  String _mapSpecialtyToCategory(String specialty) {
    if (specialty.contains('Cosmetic') ||
        specialty.contains('Laser') ||
        specialty.contains('Aesthetic')) {
      return 'Cosmetic';
    } else if (specialty.contains('Pediatric')) {
      return 'Pediatric';
    } else if (specialty.contains('Dermapathology')) {
      return 'Dermapathology';
    } else {
      return 'Medical';
    }
  }

  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    final userRepository = context.read<UserRepository>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      final userData = await userRepository.getUser(currentUser.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _firstNameController.text = userData?.firstName ?? '';
          _middleNameController.text = userData?.middleName ?? '';
          _lastNameController.text = userData?.lastName ?? '';
          _emailController.text = userData?.email ?? '';
          _phoneController.text = userData?.contactNumber ?? '';
          _usernameController.text = userData?.username ?? '';
          _selectedSex = userData?.sex;
          _selectedDateOfBirth = userData?.dateOfBirth;

          // Load address data
          _selectedRegion = userData?.region;
          if (_selectedRegion != null) {
            _provinces = LocationHelper.getProvinces(_selectedRegion!);
          }
          _selectedProvince = userData?.province;
          if (_selectedRegion != null && _selectedProvince != null) {
            _municipalities = LocationHelper.getMunicipalities(
                _selectedRegion!, _selectedProvince!);
          }
          _selectedMunicipality = userData?.municipality;
          if (_selectedRegion != null &&
              _selectedProvince != null &&
              _selectedMunicipality != null) {
            _barangays = LocationHelper.getBarangays(
                _selectedRegion!, _selectedProvince!, _selectedMunicipality!);
          }
          _selectedBarangay = userData?.barangay;

          _isLoading = false;
        });
      }
    }

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    await LocationHelper.loadLocations();
    if (mounted) {
      setState(() {
        _regions = LocationHelper.getRegions();
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onRegionChanged(String? value) {
    setState(() {
      _selectedRegion = value;
      _selectedProvince = null;
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _provinces = value != null ? LocationHelper.getProvinces(value) : [];
      _municipalities = [];
      _barangays = [];
    });
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _selectedProvince = value;
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _municipalities = value != null && _selectedRegion != null
          ? LocationHelper.getMunicipalities(_selectedRegion!, value)
          : [];
      _barangays = [];
    });
  }

  void _onMunicipalityChanged(String? value) {
    setState(() {
      _selectedMunicipality = value;
      _selectedBarangay = null;
      _barangays =
          value != null && _selectedRegion != null && _selectedProvince != null
              ? LocationHelper.getBarangays(
                  _selectedRegion!, _selectedProvince!, value)
              : [];
    });
  }

  void _onBarangayChanged(String? value) {
    setState(() {
      _selectedBarangay = value;
    });
  }

  Future<void> saveAndProceed() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() {
        _isSaving = true;
      });
      try {
        final authService = context.read<AuthService>();
        final bookingRepository = context.read<BookingRepository>();

        final updatedUserData = {
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'contactNumber': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'username': _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
          'sex': _selectedSex,
          'dateOfBirth': _selectedDateOfBirth,
          'region': _selectedRegion,
          'province': _selectedProvince,
          'municipality': _selectedMunicipality,
          'barangay': _selectedBarangay,
        };

        await authService.db.updateUserData(
          _currentUser!.uid,
          updatedUserData,
        );

        // Create the booking with condition and type
        final booking = BookingModel(
          id: '', // Will be set by the repository
          userId: _currentUser!.uid,
          doctorId: widget.doctor.id,
          appointmentDate: widget.selectedDay,
          appointmentTime: widget.selectedTime,
          status: 'Pending',
          createdAt: DateTime.now(),
          condition: _selectedCondition,
          type: _doctorType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await bookingRepository.createBooking(booking);

        if (mounted) {
          // Play sound and show notification
          final player = AudioPlayer();
          player.play(AssetSource('sounds/chime.mp3'));

          final notificationRepository = context.read<NotificationRepository>();
          await notificationRepository.createNotification(
            userId: widget.doctor.id,
            title: 'New Booking Request',
            body:
                'You have a new appointment request from ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} for ${widget.selectedTime} on ${widget.selectedDay.toString().split(' ')[0]}.',
            type: 'booking_pending',
            relatedId: booking.id,
            doctorId: widget.doctor.id,
            senderType: 'patient',
          );

          // Pop back to the consultation screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonExt = theme.extension<ButtonStyleExtension>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your personal details are important for us",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              "Your personal details will be verified by our doctor during consultation.",
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'First Name',
              controller: _firstNameController,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your first name'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildFormField(
                label: 'Middle Name', controller: _middleNameController),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Last Name',
              controller: _lastNameController,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your last name'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildFormField(label: 'Username', controller: _usernameController),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length != 11) {
                    return 'Phone number must be 11 digits.';
                  }
                  return null;
                }),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sex', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  hint: const Text('Select Sex'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (String? value) =>
                      setState(() => _selectedSex = value),
                  decoration: const InputDecoration(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DatePickerField(
              label: 'Date of Birth',
              selectedDate: _selectedDateOfBirth,
              onDateSelected: (date) =>
                  setState(() => _selectedDateOfBirth = date),
              hintText: 'Select Date of Birth',
            ),
            const SizedBox(height: 16),
            // Address Fields
            const Text(
              'Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _regions.map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(
                    region,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _onRegionChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              decoration: const InputDecoration(
                labelText: 'Province',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _provinces.map((province) {
                return DropdownMenuItem(
                  value: province,
                  child: Text(
                    province,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _provinces.isEmpty ? null : _onProvinceChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMunicipality,
              decoration: const InputDecoration(
                labelText: 'Municipality/City',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _municipalities.map((municipality) {
                return DropdownMenuItem(
                  value: municipality,
                  child: Text(
                    municipality,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged:
                  _municipalities.isEmpty ? null : _onMunicipalityChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBarangay,
              decoration: const InputDecoration(
                labelText: 'Barangay',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _barangays.map((barangay) {
                return DropdownMenuItem(
                  value: barangay,
                  child: Text(
                    barangay,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _barangays.isEmpty ? null : _onBarangayChanged,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Condition', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  hint: const Text('Select Condition'),
                  items: _conditions.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
                  onChanged: (String? value) =>
                      setState(() => _selectedCondition = value),
                  decoration: const InputDecoration(),
                  validator: (value) =>
                      value == null ? 'Please select a condition' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Additional notes (Symptoms)',
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}
