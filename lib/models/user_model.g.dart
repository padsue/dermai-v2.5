// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      email: fields[1] as String,
      firstName: fields[2] as String,
      lastName: fields[3] as String,
      middleName: fields[4] as String,
      username: fields[5] as String,
      photoUrl: fields[6] as String?,
      sex: fields[7] as String?,
      dateOfBirth: fields[8] as DateTime?,
      contactNumber: fields[9] as String?,
      region: fields[10] as String?,
      province: fields[11] as String?,
      municipality: fields[12] as String?,
      barangay: fields[13] as String?,
      isEmailVerified: fields[14] as bool,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      phoneNumber: fields[17] as String?,
      isPhoneNumberVerified: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.middleName)
      ..writeByte(5)
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.photoUrl)
      ..writeByte(7)
      ..write(obj.sex)
      ..writeByte(8)
      ..write(obj.dateOfBirth)
      ..writeByte(9)
      ..write(obj.contactNumber)
      ..writeByte(10)
      ..write(obj.region)
      ..writeByte(11)
      ..write(obj.province)
      ..writeByte(12)
      ..write(obj.municipality)
      ..writeByte(13)
      ..write(obj.barangay)
      ..writeByte(14)
      ..write(obj.isEmailVerified)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.phoneNumber)
      ..writeByte(18)
      ..write(obj.isPhoneNumberVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
