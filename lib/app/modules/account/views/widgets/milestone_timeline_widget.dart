import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/account_controller.dart';

class MilestoneTimelineWidget extends GetView<AccountController> {
  final String currentTier;
  final double progressVal;

  const MilestoneTimelineWidget({
    super.key,
    required this.currentTier,
    required this.progressVal,
  });

  @override
  Widget build(BuildContext context) {
    const tiers = ['Regular', 'Bronze', 'Silver', 'Gold'];
    int activeIndex = 0;
    final t = currentTier.toLowerCase().trim();
    if (t.contains('gold') ||
        t.contains('diamond') ||
        t.contains('platinum')) {
      activeIndex = 3;
    } else if (t.contains('silver')) {
      activeIndex = 2;
    } else if (t.contains('bronze')) {
      activeIndex = 1;
    } else {
      activeIndex = 0;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 15.r,
            left: 20.w,
            right: 20.w,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth;
                double fillFraction = 0.0;
                if (activeIndex == 0) {
                  fillFraction = (progressVal / 3.0);
                } else if (activeIndex == 1) {
                  fillFraction = (1.0 / 3.0) + (progressVal / 3.0);
                } else if (activeIndex == 2) {
                  fillFraction = (2.0 / 3.0) + (progressVal / 3.0);
                } else {
                  fillFraction = 1.0;
                }

                return Stack(
                  children: [
                    Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Container(
                      height: 3.h,
                      width: totalW * fillFraction.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(tiers.length, (idx) {
              final isReached = idx <= activeIndex;
              final tierName = tiers[idx];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isReached ? const Color(0xFFEA580C) : Colors.white,
                      border: Border.all(
                        color: isReached
                            ? const Color(0xFFFF8A4C)
                            : const Color(0xFFCBD5E1),
                        width: isReached ? 2.5 : 2.0,
                      ),
                      boxShadow: isReached
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEA580C)
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 17.r,
                      color: isReached ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    tierName,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      fontWeight:
                          isReached ? FontWeight.w800 : FontWeight.w600,
                      color: isReached
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
