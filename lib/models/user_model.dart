import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String firstName;

  @HiveField(3)
  final String lastName;

  @HiveField(4)
  final String middleName;

  @HiveField(5)
  final String username;

  @HiveField(6)
  final String? photoUrl;

  @HiveField(7)
  final String? sex;

  @HiveField(8)
  final DateTime? dateOfBirth;

  @HiveField(9)
  final String? contactNumber;

  @HiveField(10)
  final String? region;

  @HiveField(11)
  final String? province;

  @HiveField(12)
  final String? municipality;

  @HiveField(13)
  final String? barangay;

  @HiveField(14)
  final bool isEmailVerified;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime updatedAt;

  @HiveField(17)
  final String? phoneNumber;

  @HiveField(18)
  final bool isPhoneNumberVerified;

  String get displayName => '$firstName $lastName';

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.username,
    this.photoUrl,
    this.sex,
    this.dateOfBirth,
    this.contactNumber,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.isPhoneNumberVerified = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      sex: data['sex'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      contactNumber: data['contactNumber'],
      region: data['region'],
      province: data['province'],
      municipality: data['municipality'],
      barangay: data['barangay'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phoneNumber: data['phoneNumber'],
      isPhoneNumberVerified: data['isPhoneNumberVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'username': username,
      'photoUrl': photoUrl,
      'sex': sex,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'contactNumber': contactNumber,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'phoneNumber': phoneNumber,
      'isPhoneNumberVerified': isPhoneNumberVerified,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? middleName,
    String? username,
    String? photoUrl,
    String? sex,
    DateTime? dateOfBirth,
    String? contactNumber,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    bool? isPhoneNumberVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      contactNumber: contactNumber ?? this.contactNumber,
      region: region ?? this.region,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneNumberVerified:
          isPhoneNumberVerified ?? this.isPhoneNumberVerified,
    );
  }
}
