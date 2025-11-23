import 'package:dermai/repositories/user_repository.dart';
import 'package:dermai/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/widgets/profile_avatar.dart';
import '../models/doctor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import '../models/user_model.dart';
import '../repositories/doctor_repository.dart';

class DoctorsProfileScreen extends StatefulWidget {
  final DoctorModel? doctor;

  const DoctorsProfileScreen({super.key, this.doctor});

  @override
  State<DoctorsProfileScreen> createState() => _DoctorsProfileScreenState();
}

class _DoctorsProfileScreenState extends State<DoctorsProfileScreen> {
  Stream<List<ReviewModel>>? _reviewsStream;
  Stream<DoctorModel?>? _doctorStream;

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null) {
      _reviewsStream = context
          .read<ReviewRepository>()
          .getReviewsStreamForDoctor(widget.doctor!.id);
      // Subscribe to the doctors stream and pick the matching doctor by id.
      // This ensures the doctor's data (rating, stats, etc.) is refreshed automatically.
      _doctorStream = context
          .read<DoctorRepository>()
          .getDoctorsStream()
          .map((doctors) => doctors.firstWhere(
                (d) => d.id == widget.doctor!.id,
                orElse: () => widget.doctor!,
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonExt = Theme.of(context).extension<ButtonStyleExtension>();

    if (widget.doctor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use a StreamBuilder to render the latest doctor data when available.
    return StreamBuilder<DoctorModel?>(
      stream: _doctorStream,
      builder: (context, snapshot) {
        final doctor = snapshot.data ?? widget.doctor!;
        return _buildContent(context, buttonExt, doctor);
      },
    );
  }

  // Accept the active doctor instance so content reflects the latest data.
  Widget _buildContent(BuildContext context, ButtonStyleExtension? buttonExt,
      DoctorModel doctor) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "P${doctor.consultFee.toStringAsFixed(0)} per consultation",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 6),
                    Text('Dr. ${doctor.displayName}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    Text(doctor.position,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        )),
                    Text(doctor.clinic,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        )),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) {
                            if (doctor.rating >= index + 1) {
                              return Icon(Icons.star,
                                  color: AppColors.accent, size: 20);
                            } else if (doctor.rating > index) {
                              return Icon(Icons.star_half,
                                  color: AppColors.accent, size: 20);
                            } else {
                              return Icon(Icons.star_border,
                                  color: AppColors.accent, size: 20);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ProfileAvatar(
                radius: 70,
                imageUrl: doctor.imageUrl.isNotEmpty ? doctor.imageUrl : null,
                showBorder: true,
                autoLoadUserPhoto: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.champagne,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoTile(context, Icons.access_time,
                    "${doctor.experienceYears} Years", "Experience"),
                _infoTile(
                    context, Icons.people, doctor.totalClients, "Patients"),
                _infoTile(
                    context, Icons.reviews, doctor.totalReviews, "Reviews"),
                _infoTile(
                    context,
                    Icons.language,
                    doctor.languages.length == 2
                        ? '${doctor.languages[0].substring(0, 3)} & ${doctor.languages[1].substring(0, 3)}'
                        : doctor.languages.join(' & '),
                    "Languages"),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _sectionTitle(context, "Professional Profile"),
          Text(
            doctor.professionalProfile,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "Specialty"),
          Text(
            doctor.specialty,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "Clinic Information"),
          Text(
            "Address: ${doctor.clinicAddress}\nEmail: ${doctor.clinicEmail}\nPhone: ${doctor.clinicPhone}",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "Education"),
          Text(
            (doctor.education).join('\n'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "Board Certifications"),
          Text(
            (doctor.boardCertifications).join('\n'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 40),
          // Reviews Section
          _sectionTitle(context, "Reviews"),
          StreamBuilder<List<ReviewModel>>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error loading reviews: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No reviews available.');
              }

              final reviews = snapshot.data!.take(5).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return FutureBuilder<UserModel?>(
                    future:
                        context.read<UserRepository>().getUser(review.userId),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      final userName = user?.displayName ?? 'Anonymous';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ProfileAvatar(
                                      radius: 20,
                                      imageUrl: user?.photoUrl,
                                      autoLoadUserPhoto: false,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      review.createdAt.toString().split(' ')[0],
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    if (review.rating >= starIndex + 1) {
                                      return Icon(Icons.star,
                                          color: AppColors.accent, size: 16);
                                    } else if (review.rating > starIndex) {
                                      return Icon(Icons.star_half,
                                          color: AppColors.accent, size: 16);
                                    } else {
                                      return Icon(Icons.star_border,
                                          color: AppColors.accent, size: 16);
                                    }
                                  }),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                review.comment,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                          if (review.response != null &&
                              review.response!.isNotEmpty)
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.cherryBlossom.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.reply,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${doctor.displayName}',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          review.updatedAt
                                              .toString()
                                              .split(' ')[0],
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review.response!,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
      BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(subtitle,
            style:
                theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ),
    );
  }
}
