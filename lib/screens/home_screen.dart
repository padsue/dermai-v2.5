import 'package:dermai/models/detection_result.dart';
import 'package:dermai/repositories/record_repository.dart';
import 'package:dermai/screens/scan_history_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../widgets/brand_name.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
    final userRepository = context.read<UserRepository>();
    final recordRepository = context.read<RecordRepository>();
    final bookingRepository = context.read<BookingRepository>();
    final doctorRepository = context.read<DoctorRepository>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      _userStream = userRepository.getUserStream(currentUser.uid);
      _recordsStream =
          recordRepository.getRecordsStreamForUser(currentUser.uid);
      _bookingsStream =
          bookingRepository.getUpcomingBookingsStream(currentUser.uid);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/abstractbg.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Access Online Consultations\nfrom Licensed Dermatologists",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<AppProvider>().changeTab(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("Schedule Appointment"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${_getGreeting()}, ${userModel?.displayName ?? 'User'}!",
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Subscription", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.backgroundGradient,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/subscription_card.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BrandName(
                                size: BrandNameSize.headlineMedium,
                                useSecondaryColor: true,
                                alignment: MainAxisAlignment.start,
                              ),
                              const Spacer(),
                              Text(
                                userModel?.email ?? "no-email@dermai.com",
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Freemium",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text("Summary", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildSummarySection(),
                const SizedBox(height: 20),
                Text("Consultations", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildConsultationsSection(),
                const SizedBox(height: 20),
                Text("History", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildHistorySection(),
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
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            // Greeting skeleton
            Container(
              width: 200,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Section title
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Subscription card skeleton
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            // Summary title
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Summary skeleton
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
              height: 132,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            title: 'No summary yet',
            subtitle: 'Start scanning skin lesions to see a health summary.',
            asset: 'assets/images/empty_summary.png',
            onAction: () => context.read<AppProvider>().changeTab(1),
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
          return Container(
            height: 132,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.champagne,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text('No conditions detected yet.',
                    style: theme.textTheme.bodyMedium)),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.champagne,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 100,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 20,
                          sections: List.generate(topConditions.length, (i) {
                            final condition = topConditions[i];
                            return PieChartSectionData(
                              color: summaryColors[i % summaryColors.length],
                              value: condition.value.toDouble(),
                              showTitle: false,
                              radius: 35 - (i * 5),
                            );
                          }),
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
            height: 160,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
          );
        }
        if (doctorsSnapshot.hasError) {
          return const SizedBox(
              height: 160,
              child: Center(child: Text('Could not load doctors.')));
        }
        if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.isEmpty) {
          return _EmptyState(
            title: 'No consultations',
            subtitle: 'Book an appointment with a dermatologist.',
            asset: 'assets/images/empty_consult.png',
            onAction: () => Navigator.pushNamed(context, '/book'),
            actionLabel: 'Book Now',
          );
        }

        final allDoctors = doctorsSnapshot.data!;

        return StreamBuilder<List<BookingModel>>(
          stream: _bookingsStream,
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 160,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            if (bookingsSnapshot.hasError) {
              return const SizedBox(
                  height: 160,
                  child: Center(child: Text('Could not load bookings.')));
            }
            if (!bookingsSnapshot.hasData || bookingsSnapshot.data!.isEmpty) {
              return const SizedBox(
                  height: 160,
                  child: Center(child: Text('No upcoming consultations.')));
            }

            final upcomingBookings = bookingsSnapshot.data!.take(5).toList();

            return SizedBox(
              height: 160,
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
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load history.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            title: 'No history',
            subtitle: 'Your previous scans will appear here.',
            asset: 'assets/images/empty_history.png',
            onAction: () => context.read<AppProvider>().changeTab(1),
            actionLabel: 'Scan Now',
          );
        }

        final latestRecords = snapshot.data!.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestRecords.length,
          itemBuilder: (context, index) {
            final record = latestRecords[index];
            final firstImage = record.imageResults.isNotEmpty
                ? record.imageResults.first.imageUrl
                : null;

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                        placeholder: (context, url) => const SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.0))),
                        errorWidget: (context, url, error) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
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
              subtitle: Text(
                DateFormat.yMMMMd().format(record.scanDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7)),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          Text(value.toString()),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final DoctorModel doctor;
  final BookingModel booking;

  const _ConsultationCard(
      {required this.doctor, required this.booking, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFFEFEFE)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: doctor.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: doctor.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : Image.asset(
                      'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. ${doctor.displayName}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  DateFormat('EEE, MMM d').format(booking.appointmentDate),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable empty‑state widget used throughout HomeScreen when a stream has no data.
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset; // path to PNG/SVG asset
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.asset,
    this.onAction,
    this.actionLabel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
  
          const SizedBox(height: 12),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
