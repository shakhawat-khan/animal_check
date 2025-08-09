import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bird_detector/animal_classifier.dart';
import 'package:bird_detector/module/submit_bottom_sheet.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _pickedImage;
  String _predictionText = "";
  bool _isTyping = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _predictionText = "";
        _isTyping = true;
      });

      final classifier = BirdClassifier();
      await classifier.loadModel();
      final result = await classifier.classify(File(pickedFile.path));

      _simulateTyping(result);
    }
  }

  void _simulateTyping(String fullText) async {
    _predictionText = "";
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _predictionText += fullText[i];
      });
    }
    setState(() {
      _isTyping = false;
    });
  }

  void _openBottomSheet() {
    if (_pickedImage != null && _predictionText.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Material(
                color: Colors.white,
                child: ImageTextBottomSheet(
                  imageFile: _pickedImage!,
                  text: _predictionText,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text("Animal Identifier"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImage,
        icon: const Icon(Icons.image),
        label: const Text("Choose Image"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _pickedImage != null
                ? Hero(
                    tag: 'selected-image',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _pickedImage!,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white10,
                    ),
                    child: const Center(
                      child: Text(
                        'No image selected',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
            const SizedBox(height: 30),
            if (_predictionText.isNotEmpty || _isTyping)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TensorFlow Prediction",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _predictionText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    if (_isTyping)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: AnimatedTypingDots(),
                      ),
                    if (!_isTyping)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _openBottomSheet,
                          child: const Text(
                            "Try this with AI",
                            style: TextStyle(color: Colors.tealAccent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ChatGPT-style Typing Dots Animation
class AnimatedTypingDots extends StatefulWidget {
  const AnimatedTypingDots({super.key});

  @override
  State<AnimatedTypingDots> createState() => _AnimatedTypingDotsState();
}

class _AnimatedTypingDotsState extends State<AnimatedTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (_, __) {
        return Text(
          '.' * _dotCount.value,
          style: const TextStyle(fontSize: 24, color: Colors.white70),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
