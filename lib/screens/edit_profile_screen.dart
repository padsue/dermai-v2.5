import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../repositories/notification_repository.dart';
import '../utils/app_colors.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/date_picker_field.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../utils/location_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Location dropdowns
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;

  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _municipalities = [];
  List<String> _barangays = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadLocations();
    await _loadUserData();
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.gallery);
                  },
                ),
                if (_currentUser?.photoUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() {
        _isSaving = true;
      });
      try {
        final authService = context.read<AuthService>();

        // Upload image if selected
        String? newPhotoUrl;
        if (_selectedImage != null) {
          newPhotoUrl =
              await authService.uploadAndUpdateProfilePhoto(_selectedImage!);
        }

        // Update user data - cache will be updated automatically by DatabaseService
        await authService.db.updateUserData(
          _currentUser!.uid,
          {
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
            if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
            'region': _selectedRegion,
            'province': _selectedProvince,
            'municipality': _selectedMunicipality,
            'barangay': _selectedBarangay,
          },
        );

        // No need to manually refresh cache - DatabaseService handles it automatically

        if (mounted) {
          // Play sound and show notification
          final player = AudioPlayer();
          player.play(AssetSource('sounds/chime.mp3'));

          final notificationRepository = context.read<NotificationRepository>();
          await notificationRepository.showLocalNotification(
            title: 'Profile Updated',
            body: 'Your profile information has been successfully saved.',
          );

          Navigator.of(context).pop();
        }
      } catch (e) {
        // Error is caught, but no snackbar is shown.
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true,
        title: Text(
          'Edit Profile',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                )
              : GestureDetector(
                  onTap: _saveProfile,
                  child: const Tooltip(
                    message: 'Save Profile',
                    child: Icon(Icons.check),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    _selectedImage != null
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_selectedImage!),
                            ),
                          )
                        : ProfileAvatar(
                            radius: 60,
                            showBorder: true,
                            imageUrl: _currentUser?.photoUrl,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildFormField(
                label: 'First Name',
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Middle Name',
                controller: _middleNameController,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Last Name',
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Username',
                controller: _usernameController,
              ),
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
                },
              ),
              const SizedBox(height: 16),

              // Gender Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sex',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    hint: const Text('Select Sex'),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSex = value;
                      });
                    },
                    decoration: const InputDecoration(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date of Birth Selection
              DatePickerField(
                label: 'Date of Birth',
                selectedDate: _selectedDateOfBirth,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDateOfBirth = date;
                  });
                },
                hintText: 'Select Date of Birth',
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
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
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
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
