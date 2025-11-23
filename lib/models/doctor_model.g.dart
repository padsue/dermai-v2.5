// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoctorModelAdapter extends TypeAdapter<DoctorModel> {
  @override
  final int typeId = 3;

  @override
  DoctorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctorModel(
      id: fields[0] as String,
      specialty: fields[1] as String,
      clinic: fields[2] as String,
      imageUrl: fields[3] as String,
      consultFee: fields[4] as double,
      rating: fields[5] as double,
      status: fields[6] as String,
      experienceYears: fields[7] as int,
      totalClients: fields[8] as String,
      totalReviews: fields[9] as String,
      languages: (fields[10] as List).cast<String>(),
      professionalProfile: fields[11] as String,
      education: (fields[12] as List).cast<String>(),
      boardCertifications: (fields[13] as List).cast<String>(),
      firstName: fields[14] as String,
      lastName: fields[15] as String,
      middleName: fields[16] as String,
      email: fields[17] as String,
      phone: fields[18] as String,
      position: fields[19] as String,
      clinicAddress: fields[20] as String,
      clinicEmail: fields[21] as String,
      clinicPhone: fields[22] as String,
      licenseNumber: fields[23] as String,
      workingHours: (fields[24] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, dynamic>())),
      createdAt: fields[25] as DateTime,
      updatedAt: fields[26] as DateTime,
      doctorUsername: fields[27] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoctorModel obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.specialty)
      ..writeByte(2)
      ..write(obj.clinic)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.consultFee)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.experienceYears)
      ..writeByte(8)
      ..write(obj.totalClients)
      ..writeByte(9)
      ..write(obj.totalReviews)
      ..writeByte(10)
      ..write(obj.languages)
      ..writeByte(11)
      ..write(obj.professionalProfile)
      ..writeByte(12)
      ..write(obj.education)
      ..writeByte(13)
      ..write(obj.boardCertifications)
      ..writeByte(14)
      ..write(obj.firstName)
      ..writeByte(15)
      ..write(obj.lastName)
      ..writeByte(16)
      ..write(obj.middleName)
      ..writeByte(17)
      ..write(obj.email)
      ..writeByte(18)
      ..write(obj.phone)
      ..writeByte(19)
      ..write(obj.position)
      ..writeByte(20)
      ..write(obj.clinicAddress)
      ..writeByte(21)
      ..write(obj.clinicEmail)
      ..writeByte(22)
      ..write(obj.clinicPhone)
      ..writeByte(23)
      ..write(obj.licenseNumber)
      ..writeByte(24)
      ..write(obj.workingHours)
      ..writeByte(25)
      ..write(obj.createdAt)
      ..writeByte(26)
      ..write(obj.updatedAt)
      ..writeByte(27)
      ..write(obj.doctorUsername);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
