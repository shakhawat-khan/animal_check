import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bird_detector/provider/function.dart';
import 'package:bird_detector/utils/show_text.dart';

class ImageTextBottomSheet extends StatefulWidget {
  final File imageFile;
  final String text;

  const ImageTextBottomSheet({
    super.key,
    required this.imageFile,
    required this.text,
  });

  @override
  State<ImageTextBottomSheet> createState() => _ImageTextBottomSheetState();
}

class _ImageTextBottomSheetState extends State<ImageTextBottomSheet>
    with TickerProviderStateMixin {
  String? chatGptResponse;
  double _loadingProgress = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    // Defer the AI call a bit to let UI render first
    Future.delayed(const Duration(milliseconds: 300), _loadResponse);
  }

  Future<void> _loadResponse() async {
    setState(() {
      _loadingProgress = 0.3;
    });

    final response = await sendImageToChatGPT(widget.imageFile, widget.text);

    if (mounted) {
      setState(() {
        chatGptResponse = response;
        _loadingProgress = 1;
        _progressController.stop();
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      height: MediaQuery.of(context).size.height * 0.95,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 60,
              height: 6,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              widget.imageFile,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 18),

          // Prompt tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              border: Border.all(color: Colors.deepPurpleAccent, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.label_important,
                    color: Colors.deepPurpleAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Title
          const Text(
            "🤖 AI Analysis",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Content area
          Expanded(
            child: chatGptResponse == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        value: _loadingProgress < 1 ? null : 1.0,
                        minHeight: 6,
                        backgroundColor: Colors.grey[900],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurpleAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Analyzing the image...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: WordByWordTextAnimator(
                      fullText: chatGptResponse!,
                      wordDelay: const Duration(milliseconds: 60),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
