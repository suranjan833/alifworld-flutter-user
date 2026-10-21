import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/config/app_color.dart';
import '../../../data/widgets/skeleton_box.dart';
import '../controllers/manage_addresses_controller.dart';

class ManageAddressesView extends GetView<ManageAddressesController> {
  const ManageAddressesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColor.textPrimary,
            size: 24.r,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Manage Addresses',
          style: GoogleFonts.lato(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: const SkeletonList(itemCount: 3),
              )
            : Column(
        children: [
          // Add New Address Top Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: () => controller.openAddAddressSheet(context),
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColor.primary, width: 1.5.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.add,
                        size: 20.r,
                        color: AppColor.primaryDark,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Add New Address',
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Addresses List
          Expanded(
            child: Obx(() {
              final addrList = controller.addresses;

              if (addrList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.location_slash,
                        size: 54.r,
                        color: AppColor.textHint,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No saved addresses',
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                physics: const BouncingScrollPhysics(),
                itemCount: addrList.length,
                itemBuilder: (context, index) {
                  final address = addrList[index];
                  return _buildAddressCard(context, address);
                },
              );
            }),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Type Badge, Default radio
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  address.type.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              if (address.isDefault) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: GoogleFonts.lato(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryDark,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20.r,
                  color: AppColor.textSecondary,
                ),
                onSelected: (val) {
                  if (val == 'default') {
                    controller.setDefaultAddress(address.id);
                  } else if (val == 'delete') {
                    controller.deleteAddress(address.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Address'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),

          Text(
            address.name,
            style: GoogleFonts.lato(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),

          Text(
            '${address.street}, ${address.city}, ${address.state} - ${address.pincode}',
            style: GoogleFonts.lato(
              fontSize: 13.5.sp,
              color: AppColor.textSecondary,
              height: 1.3,
            ),
          ),
          SizedBox(height: 6.h),

          Row(
            children: [
              Icon(Iconsax.call, size: 14.r, color: AppColor.textSecondary),
              SizedBox(width: 6.w),
              Text(
                address.phone,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
