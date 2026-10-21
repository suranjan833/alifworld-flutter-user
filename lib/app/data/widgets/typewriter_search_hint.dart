import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';

class TypewriterSearchHintText extends StatefulWidget {
  final List<String> hints;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration deletingSpeed;
  final Duration pauseDuration;

  const TypewriterSearchHintText({
    super.key,
    required this.hints,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 70),
    this.deletingSpeed = const Duration(milliseconds: 35),
    this.pauseDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<TypewriterSearchHintText> createState() =>
      _TypewriterSearchHintTextState();
}

class _TypewriterSearchHintTextState extends State<TypewriterSearchHintText> {
  Timer? _timer;
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant TypewriterSearchHintText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hints != widget.hints && widget.hints.isNotEmpty) {
      _hintIndex = 0;
      _charIndex = 0;
      _isDeleting = false;
      _currentText = '';
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    if (widget.hints.isEmpty) return;
    _tick();
  }

  void _tick() {
    if (!mounted) return;

    final fullText = widget.hints[_hintIndex];

    if (!_isDeleting) {
      if (_charIndex < fullText.length) {
        _charIndex++;
        setState(() {
          _currentText = fullText.substring(0, _charIndex);
        });
        _timer = Timer(widget.typingSpeed, _tick);
      } else {
        // Pause at the end before deleting
        _timer = Timer(widget.pauseDuration, () {
          if (!mounted) return;
          setState(() {
            _isDeleting = true;
          });
          _tick();
        });
      }
    } else {
      if (_charIndex > 0) {
        _charIndex--;
        setState(() {
          _currentText = fullText.substring(0, _charIndex);
        });
        _timer = Timer(widget.deletingSpeed, _tick);
      } else {
        // Switch to the next hint string
        _isDeleting = false;
        _hintIndex = (_hintIndex + 1) % widget.hints.length;
        _timer = Timer(const Duration(milliseconds: 250), _tick);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.style ??
        GoogleFonts.lato(
          fontSize: 14.sp,
          color: AppColor.textSecondary,
          fontWeight: FontWeight.w400,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            _currentText,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Blinking cursor (|)
        Text(
          '|',
          style: textStyle.copyWith(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
