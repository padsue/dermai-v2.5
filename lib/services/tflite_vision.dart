import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  final Interpreter interpreter;
  final List<String> labels;
  final int inputSize;
  final int numClasses;

  Classifier._(this.interpreter, this.labels, this.inputSize, this.numClasses);

  static Future<Classifier> create({
    required String modelPath,
    required String labelPath,
    int inputSize = 384,
  }) async {
    final interpreter = await Interpreter.fromAsset(modelPath);

    final labelsRaw = await rootBundle.loadString(labelPath);
    final labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.substring(e.indexOf(' ') + 1))
        .toList();

    return Classifier._(interpreter, labels, inputSize, labels.length);
  }

  Future<List<Map<String, dynamic>>> predictFromFile(File imageFile) async {
    return Isolate.run(() =>
        _predictImage(imageFile, interpreter, labels, inputSize, numClasses));
  }

  static List<Map<String, dynamic>> _predictImage(
    File imageFile,
    Interpreter interpreter,
    List<String> labels,
    int inputSize,
    int numClasses,
  ) {
    final imageBytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) throw Exception("Cannot decode image!");

    img.Image resized =
        img.copyResize(image, width: inputSize, height: inputSize);

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 255.0),
              (pixel.g / 255.0),
              (pixel.b / 255.0),
            ];
          },
        ),
      ),
    );

    var output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

    interpreter.run(input, output);

    final scores = _softmax(output[0]);

    final predictions = <Map<String, dynamic>>[];
    for (int i = 0; i < numClasses; i++) {
      predictions.add({
        "label": labels[i],
        "confidence": scores[i],
      });
    }

    predictions.sort((a, b) =>
        (b["confidence"] as double).compareTo(a["confidence"] as double));

    return predictions;
  }

  Future<List<Map<String, dynamic>>> predict(String imageAssetPath) async {
    final imageData = await rootBundle.load(imageAssetPath);
    final imageBytes = imageData.buffer.asUint8List();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) throw Exception("Cannot decode image!");

    img.Image resized =
        img.copyResize(image, width: inputSize, height: inputSize);

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 255.0),
              (pixel.g / 255.0),
              (pixel.b / 255.0),
            ];
          },
        ),
      ),
    );

    var output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

    interpreter.run(input, output);

    final scores = _softmax(output[0]);

    final predictions = <Map<String, dynamic>>[];
    for (int i = 0; i < numClasses; i++) {
      predictions.add({
        "label": labels[i],
        "confidence": scores[i],
      });
    }

    predictions.sort((a, b) =>
        (b["confidence"] as double).compareTo(a["confidence"] as double));

    return predictions;
  }
}

List<double> _softmax(List<double> scores) {
  final maxScore = scores.reduce(max);
  final exps = scores.map((s) => exp(s - maxScore)).toList();
  final sumExps = exps.reduce((a, b) => a + b);
  return exps.map((e) => e / sumExps).toList();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final classifier = await Classifier.create(
    modelPath: 'assets/models/SkinDisease.tflite',
    labelPath: 'assets/models/diseaseLabels.txt',
    inputSize: 384,
  );

  final results = await classifier.predict('assets/images/test.jpg');

  print("Predictions:");
  for (var r in results.take(5)) {
    print("${r['label']}: ${(r['confidence'] as double).toStringAsFixed(2)}");
  }
}
