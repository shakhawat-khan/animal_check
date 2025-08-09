import 'dart:async';
import 'package:flutter/material.dart';

class WordByWordTextAnimator extends StatefulWidget {
  final String fullText;
  final Duration wordDelay;
  final TextStyle? textStyle;

  const WordByWordTextAnimator({
    super.key,
    required this.fullText,
    this.wordDelay = const Duration(milliseconds: 120),
    this.textStyle,
  });

  @override
  State<WordByWordTextAnimator> createState() => _WordByWordTextAnimatorState();
}

class _WordByWordTextAnimatorState extends State<WordByWordTextAnimator> {
  List<String> _words = [];
  int _currentWordIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _words = widget.fullText.trim().split(' ');
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.wordDelay, (timer) {
      if (_currentWordIndex < _words.length) {
        setState(() {
          _currentWordIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = _words.take(_currentWordIndex).join(' ');

    return Text(
      visibleText,
      style: widget.textStyle ?? const TextStyle(fontSize: 16),
    );
  }
}
