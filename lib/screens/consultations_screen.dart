import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/doctor_model.dart';
import '../repositories/doctor_repository.dart';
import '../utils/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'appointment_layout.dart';
import 'package:shimmer/shimmer.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({Key? key}) : super(key: key);

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  Stream<List<DoctorModel>>? _doctorsStream;
  final List<String> _categories = [
    "All",
    "Cosmetic",
    "Pediatric",
    "Medical",
    "Dermapathology"
  ];
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _doctorsStream = context.read<DoctorRepository>().getDoctorsStream();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildCategoryFilters(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<DoctorModel>>(
                  stream: _doctorsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return _buildSkeletonLoader();
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No doctors found.'));
                    }

                    final allDoctors = snapshot.data!;
                    final filteredDoctors = _selectedCategory == "All"
                        ? allDoctors
                        : allDoctors
                            .where((doc) =>
                                _mapSpecialtyToCategory(doc.specialty) ==
                                _selectedCategory)
                            .toList();

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filteredDoctors.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AppointmentLayout(doctor: doctor),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: DoctorCard(doctor: doctor),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          final theme = Theme.of(context);
          final chipTheme = theme.chipTheme;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              }
            },
            backgroundColor: theme.scaffoldBackgroundColor,
            selectedColor: AppColors.primary,
            labelStyle: chipTheme.labelStyle?.copyWith(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            shape: const StadiumBorder(
              side: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  const DoctorCard({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.champagne,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                radius: 20,
                imageUrl: doctor.imageUrl.isNotEmpty ? doctor.imageUrl : null,
                autoLoadUserPhoto: false,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  doctor.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Dr. ${doctor.displayName}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            doctor.specialty,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'P ${doctor.consultFee.toStringAsFixed(0)} / Consultation',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                doctor.rating.toStringAsFixed(1),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: List.generate(5, (index) {
                    if (doctor.rating >= index + 1) {
                      return Icon(Icons.star,
                          color: AppColors.accent, size: 14);
                    } else if (doctor.rating > index) {
                      return Icon(Icons.star_half,
                          color: AppColors.accent, size: 14);
                    } else {
                      return Icon(Icons.star_border,
                          color: AppColors.accent, size: 14);
                    }
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
