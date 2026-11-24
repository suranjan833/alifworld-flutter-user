import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';

class TypewriterSearchHintController extends GetxController {
  final currentText = ''.obs;
  Timer? _timer;
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  List<String> _hints = const [];

  void setHints(List<String> hints) {
    if (listEquals(_hints, hints) || hints.isEmpty) return;
    _hints = List.unmodifiable(hints);
    _hintIndex = 0;
    _charIndex = 0;
    _isDeleting = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      currentText.value = '';
      _startAnimation();
    });
  }

  void _startAnimation() {
    _timer?.cancel();
    if (_hints.isEmpty) return;
    _tick();
  }

  void _tick() {
    if (_hints.isEmpty) return;
    final fullText = _hints[_hintIndex];

    if (!_isDeleting) {
      if (_charIndex < fullText.length) {
        _charIndex++;
        currentText.value = fullText.substring(0, _charIndex);
        _timer = Timer(const Duration(milliseconds: 70), _tick);
      } else {
        _timer = Timer(const Duration(milliseconds: 1200), () {
          _isDeleting = true;
          _tick();
        });
      }
    } else {
      if (_charIndex > 0) {
        _charIndex--;
        currentText.value = fullText.substring(0, _charIndex);
        _timer = Timer(const Duration(milliseconds: 35), _tick);
      } else {
        _isDeleting = false;
        _hintIndex = (_hintIndex + 1) % _hints.length;
        _timer = Timer(const Duration(milliseconds: 250), _tick);
      }
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class TypewriterSearchHintText extends GetView<TypewriterSearchHintController> {
  final List<String> hints;
  final TextStyle? style;

  const TypewriterSearchHintText({
    super.key,
    required this.hints,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<TypewriterSearchHintController>()
        ? Get.find<TypewriterSearchHintController>()
        : Get.put(TypewriterSearchHintController());

    ctrl.setHints(hints);

    final textStyle = style ??
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
          child: Obx(
            () => Text(
              ctrl.currentText.value,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
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
