import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/config/app_color.dart';

class TrackOrdersIllustration extends StatelessWidget {
  const TrackOrdersIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.w,
      height: 240.h,
      child: CustomPaint(painter: _TrackOrdersPainter()),
    );
  }
}

class _TrackOrdersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final blackStroke = Paint()
      ..color = const Color(0xFF1E222B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blackFill = Paint()
      ..color = const Color(0xFF1E222B)
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final yellowFill = Paint()
      ..color = AppColor.primary
      ..style = PaintingStyle.fill;

    final yellowStroke = Paint()
      ..color = AppColor.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 1. Swirl accent line looping on the right
    final swirlPath = Path();
    swirlPath.moveTo(cx + 62, cy + 45);
    swirlPath.cubicTo(cx + 70, cy + 20, cx + 80, cy - 20, cx + 65, cy - 45);
    swirlPath.cubicTo(cx + 50, cy - 70, cx + 85, cy - 75, cx + 85, cy - 40);
    swirlPath.cubicTo(cx + 85, cy - 15, cx + 68, cy + 5, cx + 65, cy + 30);
    canvas.drawPath(swirlPath, yellowStroke);

    // Little yellow sparkle lines near top right of phone
    canvas.drawLine(
      Offset(cx + 40, cy - 65),
      Offset(cx + 48, cy - 67),
      yellowStroke..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(cx + 36, cy - 56),
      Offset(cx + 44, cy - 58),
      yellowStroke..strokeWidth = 2.0,
    );

    // 2. Phone Frame
    final phoneRect = Rect.fromCenter(
      center: Offset(cx + 8, cy + 10),
      width: 110,
      height: 180,
    );
    final phoneRRect = RRect.fromRectAndRadius(
      phoneRect,
      const Radius.circular(22),
    );

    // Outer black phone body
    canvas.drawRRect(phoneRRect, blackFill);

    // Inner phone screen (white)
    final screenRect = Rect.fromCenter(
      center: Offset(cx + 8, cy + 10),
      width: 90,
      height: 135,
    );
    final screenRRect = RRect.fromRectAndRadius(
      screenRect,
      const Radius.circular(10),
    );
    canvas.drawRRect(screenRRect, whiteFill);
    canvas.drawRRect(screenRRect, blackStroke..strokeWidth = 2.0);

    // Top camera notch pill
    final notchRect = Rect.fromCenter(
      center: Offset(cx + 8, cy - 68),
      width: 24,
      height: 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(notchRect, const Radius.circular(3)),
      whiteFill,
    );

    // Bottom home button circle (white ring/circle)
    canvas.drawCircle(
      Offset(cx + 8, cy + 86),
      6.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // 3. Credit Card (tilted at top left behind the receipt)
    canvas.save();
    canvas.translate(cx - 50, cy - 40);
    canvas.rotate(-22 * math.pi / 180);

    final cardRect = Rect.fromLTWH(-35, -24, 75, 48);
    final cardRRect = RRect.fromRectAndRadius(
      cardRect,
      const Radius.circular(8),
    );
    canvas.drawRRect(cardRRect, whiteFill);
    canvas.drawRRect(cardRRect, blackStroke..strokeWidth = 3.0);

    // Yellow chip / logo on card
    final chipRect = Rect.fromLTWH(-28, -14, 18, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(5)),
      yellowFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(5)),
      blackStroke..strokeWidth = 1.5,
    );

    // Scribble lines / card numbers
    final linePaint = Paint()
      ..color = const Color(0xFF1E222B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dashPath = Path();
    dashPath.moveTo(-6, -8);
    dashPath.lineTo(26, -8);
    dashPath.moveTo(-28, 8);
    dashPath.lineTo(24, 8);
    dashPath.moveTo(-28, 14);
    dashPath.lineTo(10, 14);
    canvas.drawPath(dashPath, linePaint);

    canvas.restore();

    // 4. Receipt paper coming out of the screen
    final receiptPath = Path();
    // Top of receipt inside/above phone
    receiptPath.moveTo(cx - 15, cy - 35);
    receiptPath.lineTo(cx + 25, cy - 35);
    receiptPath.lineTo(cx + 25, cy + 10);
    // Curl folding down and left
    receiptPath.cubicTo(cx + 25, cy + 30, cx + 10, cy + 50, cx - 15, cy + 50);
    receiptPath.cubicTo(cx - 30, cy + 50, cx - 35, cy + 30, cx - 25, cy + 15);
    receiptPath.cubicTo(cx - 15, cy + 5, cx - 15, cy - 15, cx - 15, cy - 35);
    receiptPath.close();

    // Nicely shaped receipt fold
    final paperPath = Path();
    paperPath.moveTo(cx - 10, cy - 30);
    paperPath.lineTo(cx + 24, cy - 30);
    paperPath.lineTo(cx + 24, cy + 35);
    // folded curved bottom
    paperPath.cubicTo(cx + 24, cy + 52, cx + 5, cy + 58, cx - 12, cy + 58);
    paperPath.cubicTo(cx - 32, cy + 58, cx - 36, cy + 38, cx - 26, cy + 22);
    paperPath.cubicTo(cx - 18, cy + 10, cx - 10, cy - 10, cx - 10, cy - 30);
    paperPath.close();

    canvas.drawPath(paperPath, whiteFill);
    canvas.drawPath(paperPath, blackStroke..strokeWidth = 3.0);

    // Shadow / fold crease inside the curl
    final foldCrease = Path();
    foldCrease.moveTo(cx - 26, cy + 22);
    foldCrease.cubicTo(cx - 20, cy + 38, cx - 5, cy + 42, cx + 10, cy + 38);
    canvas.drawPath(
      foldCrease,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(foldCrease, blackStroke..strokeWidth = 2.0);

    // Rupee sign '₹' at the top of receipt
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '₹',
      style: TextStyle(
        color: const Color(0xFF1E222B),
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 3, cy - 26));

    // Yellow Arabic / wave logo in the middle of receipt
    final wavePath = Path();
    wavePath.moveTo(cx - 8, cy - 2);
    wavePath.cubicTo(cx - 4, cy - 8, cx + 4, cy + 2, cx + 8, cy - 4);
    wavePath.cubicTo(cx + 12, cy - 10, cx + 18, cy - 2, cx + 20, cy - 6);
    canvas.drawPath(wavePath, yellowStroke..strokeWidth = 2.4);

    // Yellow '₹' at bottom of receipt
    textPainter.text = TextSpan(
      text: '₹',
      style: TextStyle(
        color: AppColor.primary,
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - 8, cy + 18));

    // 5. Yellow Coin with '₹'
    final coinCenter = Offset(cx + 50, cy + 50);
    canvas.drawCircle(coinCenter, 15.0, yellowFill);
    canvas.drawCircle(coinCenter, 15.0, blackStroke..strokeWidth = 2.5);

    textPainter.text = TextSpan(
      text: '₹',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w900,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        coinCenter.dx - textPainter.width / 2,
        coinCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
