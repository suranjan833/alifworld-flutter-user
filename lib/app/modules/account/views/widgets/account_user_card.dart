import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../routes/app_pages.dart';
import '../../controllers/account_controller.dart';

class AccountUserCard extends GetView<AccountController> {
  const AccountUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Obx(() {
        final isLoggedIn = controller.isLoggedIn.value;
        final isBn = controller.currentLangCode.value == 'bn';
        final name = controller.userName.value.trim();
        final phone = controller.userPhone.value.trim();
        final email = controller.userEmail.value.trim();
        final member = controller.memberSince.value.trim();

        final displayName = isLoggedIn
            ? (name.isNotEmpty
                ? name
                : (isBn ? 'আমার অ্যাকাউন্ট' : 'My Account'))
            : (isBn ? 'স্বাগতম, অতিথি 👋' : 'Welcome, Guest ');

        String subtitle = isBn
            ? 'অর্ডার, ওয়ালেট ও রিওয়ার্ড পেতে সাইন ইন করুন'
            : 'Sign in to access orders, wallet & rewards';
        if (isLoggedIn) {
          if (phone.isNotEmpty) {
            subtitle = phone.startsWith('+') ? phone : '+$phone';
          } else if (email.isNotEmpty) {
            subtitle = email;
          } else if (member.isNotEmpty) {
            subtitle = member;
          } else {
            subtitle = isBn
                ? 'প্রোফাইল দেখুন ও পরিবর্তন করুন'
                : 'View & edit profile';
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: InkWell(
              onTap: () => isLoggedIn
                  ? controller.openMyProfile()
                  : Get.toNamed(Routes.LOGIN),
              borderRadius: BorderRadius.circular(16.r),
              child: Row(
                children: [
                  Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A)
                              .withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isLoggedIn
                            ? Icons.person_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 28.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displayName,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (!isLoggedIn)
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.LOGIN),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.5.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF7A1A),
                              Color(0xFFFF4800),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5722)
                                    .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              isBn ? 'সাইন ইন' : 'Sign In',
                              style: GoogleFonts.lato(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20.r,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
