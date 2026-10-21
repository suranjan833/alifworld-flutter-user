import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/config/app_color.dart';

class EasyReturnsIllustration extends StatelessWidget {
  const EasyReturnsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.w,
      height: 240.h,
      child: CustomPaint(painter: _EasyReturnsPainter()),
    );
  }
}

class _EasyReturnsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final blackStroke = Paint()
      ..color = const Color(0xFF1E222B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blackFill = Paint()
      ..color = const Color(0xFF1E222B)
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final yellowBoxFill = Paint()
      ..color = AppColor.primary
      ..style = PaintingStyle.fill;

    final darkYellowBoxFill = Paint()
      ..color = const Color(0xFFE59807)
      ..style = PaintingStyle.fill;

    // 1. Character Body / Arms in background
    // Back shoulder and back body line
    final bodyPath = Path();
    bodyPath.moveTo(cx - 30, cy + 85);
    bodyPath.cubicTo(cx - 65, cy + 85, cx - 85, cy + 70, cx - 80, cy + 20);
    bodyPath.cubicTo(cx - 75, cy - 20, cx - 40, cy - 20, cx - 25, cy - 10);
    canvas.drawPath(bodyPath, whiteFill);
    canvas.drawPath(bodyPath, blackStroke);

    // 2. Character Hair (black curly clusters behind and above head)
    final hairPath = Path();
    // Back of head curls
    hairPath.addOval(
      Rect.fromCircle(center: Offset(cx - 48, cy - 35), radius: 14),
    );
    hairPath.addOval(
      Rect.fromCircle(center: Offset(cx - 52, cy - 52), radius: 15),
    );
    hairPath.addOval(
      Rect.fromCircle(center: Offset(cx - 44, cy - 68), radius: 14),
    );
    hairPath.addOval(
      Rect.fromCircle(center: Offset(cx - 28, cy - 78), radius: 15),
    );
    hairPath.addOval(
      Rect.fromCircle(center: Offset(cx - 10, cy - 74), radius: 14),
    );
    canvas.drawPath(hairPath, blackFill);

    // 3. Head & Face
    final facePath = Path();
    // Forehead
    facePath.moveTo(cx - 24, cy - 65);
    facePath.cubicTo(cx - 18, cy - 55, cx - 12, cy - 45, cx - 10, cy - 38);
    // Big rounded bulbous nose sticking forward
    facePath.cubicTo(cx - 6, cy - 40, cx + 8, cy - 40, cx + 10, cy - 30);
    facePath.cubicTo(cx + 12, cy - 22, cx + 2, cy - 18, cx - 6, cy - 18);
    // Cheerful smiling mouth and chin
    facePath.cubicTo(cx - 5, cy - 14, cx - 2, cy - 8, cx - 12, cy - 4);
    // Neck down to collar
    facePath.cubicTo(cx - 20, cy + 2, cx - 22, cy + 15, cx - 24, cy + 25);
    // Jaw/neck back to ear
    facePath.lineTo(cx - 40, cy + 10);
    facePath.cubicTo(cx - 44, cy - 10, cx - 44, cy - 35, cx - 38, cy - 50);
    facePath.close();

    canvas.drawPath(facePath, whiteFill);
    canvas.drawPath(facePath, blackStroke);

    // Ear
    final earPath = Path();
    earPath.addOval(
      Rect.fromCenter(center: Offset(cx - 30, cy - 32), width: 12, height: 16),
    );
    canvas.drawPath(earPath, whiteFill);
    canvas.drawPath(earPath, blackStroke);

    // Eye (happy cartoon eyes with eyebrow/dots)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 14, cy - 44), width: 4, height: 6),
      blackFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 4, cy - 43), width: 4, height: 6),
      blackFill,
    );

    // Cute smiling curve
    final smilePath = Path();
    smilePath.moveTo(cx - 18, cy - 26);
    smilePath.quadraticBezierTo(cx - 8, cy - 18, cx + 2, cy - 24);
    canvas.drawPath(smilePath, blackStroke..strokeWidth = 2.4);

    // 4. Delivery Box (Isometric / Perspective 3D)
    // Front Face of Box
    final boxFront = Path();
    boxFront.moveTo(cx - 24, cy - 12);
    boxFront.lineTo(cx + 48, cy - 5);
    boxFront.lineTo(cx + 46, cy + 50);
    boxFront.lineTo(cx - 24, cy + 44);
    boxFront.close();

    // Side/Flap Face of Box (left side)
    final boxSide = Path();
    boxSide.moveTo(cx - 24, cy - 12);
    boxSide.lineTo(cx - 24, cy + 44);
    boxSide.lineTo(cx - 40, cy + 34);
    boxSide.lineTo(cx - 40, cy - 2);
    boxSide.close();

    // Top Face of Box
    final boxTop = Path();
    boxTop.moveTo(cx - 40, cy - 2);
    boxTop.lineTo(cx - 24, cy - 12);
    boxTop.lineTo(cx + 48, cy - 5);
    boxTop.lineTo(cx + 34, cy + 4);
    boxTop.lineTo(cx - 30, cy + 8);
    boxTop.close();

    // Draw box parts with depth
    canvas.drawPath(boxSide, darkYellowBoxFill);
    canvas.drawPath(boxSide, blackStroke..strokeWidth = 3.0);

    canvas.drawPath(boxFront, yellowBoxFill);
    canvas.drawPath(boxFront, blackStroke..strokeWidth = 3.0);

    // Black packing tape along the left/top edge
    final tapePath = Path();
    tapePath.moveTo(cx - 28, cy - 8);
    tapePath.lineTo(cx - 20, cy - 10);
    tapePath.lineTo(cx - 20, cy + 30);
    tapePath.lineTo(cx - 28, cy + 32);
    tapePath.close();
    canvas.drawPath(tapePath, blackFill);

    // Top black flap/tape
    final topTape = Path();
    topTape.moveTo(cx - 28, cy - 8);
    topTape.lineTo(cx + 38, cy - 3);
    topTape.lineTo(cx + 36, cy + 10);
    topTape.lineTo(cx - 18, cy + 8);
    topTape.close();
    canvas.drawPath(topTape, blackFill);

    // White Arabic script / Alif logo on the front face
    final logoPath = Path();
    logoPath.moveTo(cx + 6, cy + 24);
    logoPath.cubicTo(cx + 10, cy + 18, cx + 16, cy + 16, cx + 22, cy + 22);
    logoPath.cubicTo(cx + 26, cy + 26, cx + 30, cy + 18, cx + 34, cy + 22);
    final logoPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(logoPath, logoPaint);

    // Small white dot above logo
    canvas.drawCircle(Offset(cx + 20, cy + 14), 2.2, whiteFill);

    // 5. Black Circular Badge with White Checkmark (upper right of box)
    final badgeCenter = Offset(cx + 46, cy - 4);
    canvas.drawCircle(badgeCenter, 13.0, blackFill);

    // White checkmark
    final checkPath = Path();
    checkPath.moveTo(badgeCenter.dx - 6, badgeCenter.dy - 1);
    checkPath.lineTo(badgeCenter.dx - 2, badgeCenter.dy + 4);
    checkPath.lineTo(badgeCenter.dx + 5, badgeCenter.dy - 4);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 6. Character's Hands holding the box
    // Right arm coming in front
    final armPath = Path();
    armPath.moveTo(cx - 50, cy + 50);
    armPath.cubicTo(cx - 30, cy + 60, cx - 10, cy + 64, cx + 14, cy + 58);
    armPath.cubicTo(cx + 18, cy + 50, cx + 14, cy + 44, cx + 4, cy + 46);
    armPath.cubicTo(cx - 8, cy + 48, cx - 24, cy + 52, cx - 35, cy + 46);
    canvas.drawPath(armPath, whiteFill);
    canvas.drawPath(armPath, blackStroke..strokeWidth = 3.0);

    // Fingers grasping the bottom right of the box
    final fingerPath = Path();
    fingerPath.moveTo(cx + 20, cy + 44);
    fingerPath.cubicTo(cx + 22, cy + 38, cx + 32, cy + 42, cx + 30, cy + 48);
    fingerPath.cubicTo(cx + 32, cy + 42, cx + 40, cy + 44, cx + 38, cy + 50);
    fingerPath.cubicTo(cx + 40, cy + 46, cx + 46, cy + 48, cx + 44, cy + 53);
    canvas.drawPath(fingerPath, whiteFill);
    canvas.drawPath(fingerPath, blackStroke..strokeWidth = 2.5);

    // Hand wrapping the left side
    final leftHandPath = Path();
    leftHandPath.moveTo(cx - 40, cy + 18);
    leftHandPath.cubicTo(cx - 46, cy + 24, cx - 44, cy + 34, cx - 36, cy + 34);
    canvas.drawPath(leftHandPath, whiteFill);
    canvas.drawPath(leftHandPath, blackStroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
