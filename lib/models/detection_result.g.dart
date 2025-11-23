// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectionResultModelAdapter extends TypeAdapter<DetectionResultModel> {
  @override
  final int typeId = 1;

  @override
  DetectionResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectionResultModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      scanDate: fields[2] as DateTime,
      imageResults: (fields[3] as List).cast<ImageResultModel>(),
      summary: (fields[4] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, DetectionResultModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.scanDate)
      ..writeByte(3)
      ..write(obj.imageResults)
      ..writeByte(4)
      ..write(obj.summary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageResultModelAdapter extends TypeAdapter<ImageResultModel> {
  @override
  final int typeId = 2;

  @override
  ImageResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageResultModel(
      imageUrl: fields[0] as String,
      part: fields[1] as String,
      view: fields[2] as String,
      diseasePredictions: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      skinTypePredictions: (fields[4] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      severity: fields[5] as String?,
      severityLevel: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageResultModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.imageUrl)
      ..writeByte(1)
      ..write(obj.part)
      ..writeByte(2)
      ..write(obj.view)
      ..writeByte(3)
      ..write(obj.diseasePredictions)
      ..writeByte(4)
      ..write(obj.skinTypePredictions)
      ..writeByte(5)
      ..write(obj.severity)
      ..writeByte(6)
      ..write(obj.severityLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
