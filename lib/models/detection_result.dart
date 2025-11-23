import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'detection_result.g.dart';

@HiveType(typeId: 1)
class DetectionResultModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime scanDate;

  @HiveField(3)
  final List<ImageResultModel> imageResults;

  @HiveField(4)
  final Map<String, String> summary;

  DetectionResultModel({
    required this.id,
    required this.userId,
    required this.scanDate,
    required this.imageResults,
    required this.summary,
  });

  factory DetectionResultModel.fromMap(
      Map<String, dynamic> data, String documentId) {
    return DetectionResultModel(
      id: documentId,
      userId: data['userId'],
      scanDate: (data['scanDate'] as Timestamp).toDate(),
      summary: Map<String, String>.from(data['summary']),
      imageResults: (data['imageResults'] as List)
          .map((e) => ImageResultModel.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'scanDate': Timestamp.fromDate(scanDate),
      'summary': summary,
      'imageResults': imageResults.map((e) => e.toMap()).toList(),
    };
  }
}

@HiveType(typeId: 2)
class ImageResultModel extends HiveObject {
  @HiveField(0)
  String imageUrl;

  @HiveField(1)
  final String part;

  @HiveField(2)
  final String view;

  @HiveField(3)
  final List<Map<String, dynamic>> diseasePredictions;

  @HiveField(4)
  final List<Map<String, dynamic>> skinTypePredictions;

  @HiveField(5)
  final String? severity;

  @HiveField(6)
  final String? severityLevel;

  File? localFile;

  ImageResultModel({
    required this.imageUrl,
    required this.part,
    required this.view,
    required this.diseasePredictions,
    required this.skinTypePredictions,
    this.severity,
    this.severityLevel,
    this.localFile,
  });

  factory ImageResultModel.fromMap(Map<String, dynamic> data) {
    return ImageResultModel(
      imageUrl: data['imageUrl'],
      part: data['part'],
      view: data['view'],
      diseasePredictions:
          List<Map<String, dynamic>>.from(data['diseasePredictions']),
      skinTypePredictions:
          List<Map<String, dynamic>>.from(data['skinTypePredictions']),
      severity: data['severity'],
      severityLevel: data['severityLevel'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'part': part,
      'view': view,
      'diseasePredictions': diseasePredictions,
      'skinTypePredictions': skinTypePredictions,
      'severity': severity,
      'severityLevel': severityLevel,
    };
  }
}
