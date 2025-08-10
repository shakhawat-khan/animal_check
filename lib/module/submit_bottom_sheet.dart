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

  final List<Map<String, String>> _messages =
      []; // {role: "user"/"ai", content: "..."}
  final TextEditingController _chatController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    // Initial AI Analysis
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

        // Add as first AI message
        _messages.add({"role": "ai", "content": response ?? "No response"});
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _isSending) return;

    final userMsg = _chatController.text.trim();
    setState(() {
      _messages.add({"role": "user", "content": userMsg});
      _chatController.clear();
      _isSending = true;
    });

    final response = await sendImageToChatGPT(widget.imageFile, userMsg);

    setState(() {
      _messages.add({"role": "ai", "content": response ?? "No response"});
      _isSending = false;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // ✅ Makes sure the sheet moves up with the keyboard
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AnimatedContainer(
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

            const SizedBox(height: 12),

            // Chat Area
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
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg["role"] == "user";
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.deepPurpleAccent
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(
                              msg["content"] ?? "",
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Chat Input
            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ask something...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send,
                            color: Colors.deepPurpleAccent),
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
