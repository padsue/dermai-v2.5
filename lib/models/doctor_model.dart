import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'doctor_model.g.dart';

@HiveType(typeId: 3)
class DoctorModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String specialty;

  @HiveField(2)
  final String clinic;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final double consultFee;

  @HiveField(5)
  double rating;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final int experienceYears;

  @HiveField(8)
  String totalClients;

  @HiveField(9)
  String totalReviews;

  @HiveField(10)
  final List<String> languages;

  @HiveField(11)
  final String professionalProfile;

  @HiveField(12)
  final List<String> education;

  @HiveField(13)
  final List<String> boardCertifications;

  @HiveField(14)
  final String firstName;

  @HiveField(15)
  final String lastName;

  @HiveField(16)
  final String middleName;

  @HiveField(17)
  final String email;

  @HiveField(18)
  final String phone;

  @HiveField(19)
  final String position;

  @HiveField(20)
  final String clinicAddress;

  @HiveField(21)
  final String clinicEmail;

  @HiveField(22)
  final String clinicPhone;

  @HiveField(23)
  final String licenseNumber;

  @HiveField(24)
  final Map<String, Map<String, dynamic>> workingHours;

  @HiveField(25)
  final DateTime createdAt;

  @HiveField(26)
  final DateTime updatedAt;

  @HiveField(27)
  final String doctorUsername;

  DoctorModel({
    required this.id,
    required this.specialty,
    required this.clinic,
    required this.imageUrl,
    required this.consultFee,
    required this.rating,
    required this.status,
    required this.experienceYears,
    required this.totalClients,
    required this.totalReviews,
    required this.languages,
    required this.professionalProfile,
    required this.education,
    required this.boardCertifications,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.position,
    required this.clinicAddress,
    required this.clinicEmail,
    required this.clinicPhone,
    required this.licenseNumber,
    required this.workingHours,
    required this.createdAt,
    required this.updatedAt,
    required this.doctorUsername,
  });

  String get displayName => '$firstName $lastName';

  factory DoctorModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DoctorModel(
      id: documentId,
      specialty: data['specialty'] ?? '',
      clinic: data['clinic'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      consultFee: (data['consultFee'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Offline',
      experienceYears: data['experienceYears'] ?? 0,
      totalClients: (data['totalClients'] is int)
          ? data['totalClients'].toString()
          : (data['totalClients'] ?? '0'),
      totalReviews: (data['totalReviews'] is int)
          ? data['totalReviews'].toString()
          : (data['totalReviews'] ?? '0'),
      languages: List<String>.from(data['languages'] ?? []),
      professionalProfile: data['professionalProfile'] ?? '',
      education: List<String>.from(data['education'] ?? []),
      boardCertifications: List<String>.from(data['boardCertifications'] ?? []),
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      position: data['position'] ?? '',
      clinicAddress: data['clinicAddress'] ?? '',
      clinicEmail: data['clinicEmail'] ?? '',
      clinicPhone: data['clinicPhone'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      workingHours:
          Map<String, Map<String, dynamic>>.from(data['workingHours'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      doctorUsername: data['doctorUsername'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'specialty': specialty,
      'clinic': clinic,
      'imageUrl': imageUrl,
      'consultFee': consultFee,
      'rating': rating,
      'status': status,
      'experienceYears': experienceYears,
      'totalClients': totalClients,
      'totalReviews': totalReviews,
      'languages': languages,
      'professionalProfile': professionalProfile,
      'education': education,
      'boardCertifications': boardCertifications,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'phone': phone,
      'position': position,
      'clinicAddress': clinicAddress,
      'clinicEmail': clinicEmail,
      'clinicPhone': clinicPhone,
      'licenseNumber': licenseNumber,
      'workingHours': workingHours,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'doctorUsername': doctorUsername,
    };
  }
}
