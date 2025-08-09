import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BirdClassifier {
  late Interpreter interpreter;
  late List<String> labels;
  final int inputSize = 224;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/animal_ml_model.tflite');
    final labelData =
        await rootBundle.loadString('assets/animal_ml_model_labels.txt');
    labels = labelData
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<String> classify(File imageFile) async {
    // Decode image
    final rawImage = img.decodeImage(await imageFile.readAsBytes())!;

    // Resize to model input size
    final resizedImage =
        img.copyResize(rawImage, width: inputSize, height: inputSize);

    // Normalize image to [0,1]
    var input = List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
              final pixel = resizedImage.getPixel(x, y);
              final r = pixel.r;
              final g = pixel.g;
              final b = pixel.b;
              return [r / 255.0, g / 255.0, b / 255.0];
            }));

    // Add batch dimension: [1, 224, 224, 3]
    var inputTensor = [input];

    // Prepare output buffer
    var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);

    // Run inference
    interpreter.run(inputTensor, output);

    // Get result
    final List<double> scores = List<double>.from(output[0]);
    final maxIndex =
        scores.indexWhere((x) => x == scores.reduce((a, b) => a > b ? a : b));

    return labels[maxIndex];
  }
}
