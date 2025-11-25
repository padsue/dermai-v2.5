import 'package:dermai/models/detection_result.dart';
import 'package:dermai/repositories/record_repository.dart';
import 'package:dermai/screens/scan_history_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../widgets/brand_name.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../utils/user_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/doctor_repository.dart';
import '../models/doctor_model.dart';
import '../widgets/profile_avatar.dart';
import '../providers/app_provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<UserModel?>? _userStream;
  Stream<List<DetectionResultModel>>? _recordsStream;
  Stream<List<BookingModel>>? _bookingsStream;
  Stream<List<DoctorModel>>? _doctorsStream;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final cacheService = context.read<CacheService>();
    final userRepository = context.read<UserRepository>();
    final recordRepository = context.read<RecordRepository>();
    final bookingRepository = context.read<BookingRepository>();
    final doctorRepository = context.read<DoctorRepository>();
    
    // Try to get current user from Firebase Auth first
    var currentUser = authService.currentUser;
    String? userId;
    
    if (currentUser != null) {
      userId = currentUser.uid;
    } else {
      // Fallback to cached user if offline or auth not yet resolved
      final cachedUser = cacheService.getFirstCachedUser();
      userId = cachedUser?.uid;
    }
    
    // Initialize streams if we have a user ID (either from auth or cache)
    if (userId != null) {
      _userStream = userRepository.getUserStream(userId);
      _recordsStream = recordRepository.getRecordsStreamForUser(userId);
      _bookingsStream = bookingRepository.getUpcomingBookingsStream(userId);
    }
    
    // Fetch all doctors once to use for matching with bookings
    _doctorsStream = doctorRepository.getDoctorsStream();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  // Helper to build section headers
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
            style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.smokeWhite,
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildSkeletonLoader();
          }

          final userModel = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/abstractbg.jpg",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: AppColors.champagne),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Access Online Consultations\nfrom Licensed Dermatologists",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AppProvider>().changeTab(1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              child: const Text("Schedule Appointment"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Greeting
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            userModel?.displayName ?? 'User',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary Section
                _buildSectionHeader(
                  icon: Icons.pie_chart_rounded,
                  title: "Health Summary",
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildSummarySection(),
                const SizedBox(height: 24),

                // Consultations Section
                _buildSectionHeader(
                  icon: Icons.people_alt_rounded,
                  title: "Upcoming Consultations",
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildConsultationsSection(),
                const SizedBox(height: 24),

                // History Section
                _buildSectionHeader(
                  icon: Icons.history_rounded,
                  title: "Recent Scans",
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildHistorySection(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner skeleton
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Greeting skeleton
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Section title
            Container(
              width: 150,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // Subscription card skeleton
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Summary title
            Container(
              width: 150,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // Summary skeleton
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final summaryColors = [
      AppColors.tickleMePink,
      AppColors.sunset,
      AppColors.raspberryRose,
    ];

    return StreamBuilder<List<DetectionResultModel>>(
      stream: _recordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.pie_chart_outline,
            iconColor: AppColors.primary,
            title: 'No summary yet',
            subtitle: 'Start scanning skin lesions to see a health summary.',
            onAction: () => context.read<AppProvider>().changeTab(2),
            actionLabel: 'Start Scan',
          );
        }

        // Process data to get top 3 conditions
        final records = snapshot.data!;
        final conditionCounts = <String, int>{};

        for (var record in records) {
          for (var imageResult in record.imageResults) {
            if (imageResult.diseasePredictions.isNotEmpty) {
              final topCondition =
                  imageResult.diseasePredictions.first['label'] as String;
              conditionCounts[topCondition] =
                  (conditionCounts[topCondition] ?? 0) + 1;
            }
          }
        }

        final sortedConditions = conditionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topConditions = sortedConditions.take(3).toList();

        if (topConditions.isEmpty) {
          return _EmptyState(
            icon: Icons.pie_chart_outline,
            iconColor: AppColors.primary,
            title: 'No conditions detected',
            subtitle: 'Your health summary will appear here.',
            onAction: () => context.read<AppProvider>().changeTab(2),
            actionLabel: 'Start Scan',
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.champagne.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 100,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 25,
                            sections: List.generate(topConditions.length, (i) {
                              final condition = topConditions[i];
                              return PieChartSectionData(
                                color: summaryColors[i % summaryColors.length],
                                value: condition.value.toDouble(),
                                showTitle: false,
                                radius: 30 - (i * 3),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(topConditions.length, (i) {
                        final condition = topConditions[i];
                        return _SummaryItem(
                          color: summaryColors[i % summaryColors.length],
                          text: condition.key,
                          value: condition.value,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsultationsSection() {
    return StreamBuilder<List<DoctorModel>>(
      stream: _doctorsStream,
      builder: (context, doctorsSnapshot) {
        if (doctorsSnapshot.connectionState == ConnectionState.waiting &&
            !doctorsSnapshot.hasData) {
          return SizedBox(
            height: 180,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
          );
        }
        if (doctorsSnapshot.hasError) {
          return _EmptyState(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'Could not load doctors',
            subtitle: 'Please try again later.',
            actionLabel: null,
          );
        }
        if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            iconColor: AppColors.secondary,
            title: 'No consultations',
            subtitle: 'Book an appointment with a dermatologist.',
            onAction: () => context.read<AppProvider>().changeTab(1),
            actionLabel: 'Book Now',
          );
        }

        final allDoctors = doctorsSnapshot.data!;

        return StreamBuilder<List<BookingModel>>(
          stream: _bookingsStream,
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 180,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            if (bookingsSnapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline,
                iconColor: AppColors.error,
                title: 'Could not load bookings',
                subtitle: 'Please try again later.',
                actionLabel: null,
              );
            }
            
            if (!bookingsSnapshot.hasData || bookingsSnapshot.data!.isEmpty) {
              return _EmptyState(
                icon: Icons.event_available,
                iconColor: AppColors.info,
                title: 'No upcoming consultations',
                subtitle: 'Schedule an appointment to get started.',
                onAction: () => context.read<AppProvider>().changeTab(1),
                actionLabel: 'Schedule Now',
              );
            }

            final upcomingBookings = bookingsSnapshot.data!.take(5).toList();

            return SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingBookings.length,
                itemBuilder: (context, index) {
                  final booking = upcomingBookings[index];
                  final doctor = allDoctors.firstWhere(
                    (doc) => doc.id == booking.doctorId,
                    orElse: () => DoctorModel(
                        id: '',
                        specialty: '',
                        clinic: '',
                        imageUrl: '',
                        consultFee: 0,
                        rating: 0,
                        status: '',
                        experienceYears: 0,
                        totalClients: '',
                        totalReviews: '',
                        languages: [],
                        professionalProfile: '',
                        education: [],
                        boardCertifications: [],
                        firstName: 'Unknown',
                        lastName: '',
                        middleName: '',
                        email: '',
                        phone: '',
                        position: '',
                        clinicAddress: '',
                        clinicEmail: '',
                        clinicPhone: '',
                        licenseNumber: '',
                        workingHours: {},
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        doctorUsername: ''),
                  );

                  return _ConsultationCard(
                    doctor: doctor,
                    booking: booking,
                    onTap: () => _showConsultationDetails(context, doctor, booking),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              ),
            );
          },
        );
      },
    );
  }

  void _showConsultationDetails(
      BuildContext context, DoctorModel doctor, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doctor Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: doctor.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doctor.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 40),
                        )
                      : const Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              
              // Doctor Name & Specialty
              Text(
                'Dr. ${doctor.displayName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                doctor.specialty,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Appointment Details
              _buildDetailRow(Icons.calendar_today, 'Date',
                  DateFormat('MMMM d, yyyy').format(booking.appointmentDate)),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.access_time, 'Time', booking.appointmentTime),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.videocam, 'Type', booking.type ?? 'Online Consultation'),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.info_outline, 
                'Status', 
                booking.status,
                valueColor: _getStatusColor(booking.status),
              ),
              

               if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildDetailRow(Icons.note, 'Notes', booking.notes!),
              ],

              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCancellationDialog(context, booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancellationDialog(BuildContext context, BookingModel booking) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to cancel this appointment? Please provide a reason.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  await context.read<BookingRepository>().cancelBooking(
                        booking,
                        reasonController.text.trim(),
                      );

                  if (context.mounted) {
                    // Close loading
                    Navigator.pop(context);
                    // Close dialog
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Close loading
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return StreamBuilder<List<DetectionResultModel>>(
      stream: _recordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'Could not load history',
            subtitle: 'Please try again later.',
            actionLabel: null,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.history,
            iconColor: AppColors.accent,
            title: 'No scan history',
            subtitle: 'Your previous scans will appear here.',
            onAction: () => context.read<AppProvider>().changeTab(2),
            actionLabel: 'Start Scan',
          );
        }

        final latestRecords = snapshot.data!.take(5).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestRecords.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final record = latestRecords[index];
            final firstImage = record.imageResults.isNotEmpty
                ? record.imageResults.first.imageUrl
                : null;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScanHistoryDetailScreen(record: record),
                    ),
                  );
                },
                leading: firstImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: firstImage,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.champagne,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.0)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.champagne,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.champagne,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_not_supported,
                            color: AppColors.textSecondary),
                      ),
                title: Text(
                  record.summary['skinConditions'] ?? 'N/A',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                   Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMMd().format(record.scanDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.primary),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final Color color;
  final String text;
  final int value;

  const _SummaryItem(
      {required this.color, required this.text, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final DoctorModel doctor;
  final BookingModel booking;
  final VoidCallback onTap;

  const _ConsultationCard(
      {required this.doctor, required this.booking, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: doctor.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: doctor.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.champagne,
                              child: Icon(Icons.person,
                                  color: AppColors.textSecondary, size: 40),
                            ),
                          )
                        : Container(
                            color: AppColors.champagne,
                            child: Center(
                              child: Icon(Icons.person,
                                  color: AppColors.textSecondary, size: 40),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${doctor.displayName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d').format(booking.appointmentDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(booking.status),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// Reusable empty-state widget used throughout HomeScreen when a stream has no data
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: iconColor,
                side: BorderSide(color: iconColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return Colors.green;
    case 'pending':
      return Colors.amber;
    case 'rescheduled':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    case 'done':
      return Colors.green[800]!;
    case 'archived':
      return Colors.grey;
    case 'reopened':
      return Colors.orange;
    default:
      return AppColors.primary;
  }
}
