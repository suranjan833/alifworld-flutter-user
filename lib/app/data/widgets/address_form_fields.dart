import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_color.dart';
import '../controllers/address_form_controller.dart';
import '../models/geo_model.dart';

class AddressDropdownField extends GetView<AddressFormController> {
  final String label;
  final String hint;
  final bool isLoading;
  final String? value;
  final List<GeoDropdownOption> items;
  final ValueChanged<String?>? onChanged;

  const AddressDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.isLoading,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: onChanged == null ? const Color(0xFFF8FAFC) : AppColor.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: onChanged == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.any((item) => item.id == value) ? value : null,
              hint: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.primaryDark,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Loading...',
                          style: GoogleFonts.lato(fontSize: 12.sp),
                        ),
                      ],
                    )
                  : Text(
                      hint,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: AppColor.textHint,
                      ),
                    ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: isLoading ? null : onChanged,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: onChanged == null
                    ? const Color(0xFF94A3B8)
                    : AppColor.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AddressTextInputField extends GetView<AddressFormController> {
  final TextEditingController inputController;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const AddressTextInputField({
    super.key,
    required this.inputController,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: inputController,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.lato(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(
              fontSize: 13.sp,
              color: AppColor.textHint,
            ),
            prefixIcon: Icon(icon, size: 18.r, color: AppColor.textSecondary),
            filled: true,
            fillColor: AppColor.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class BdPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = AddressFormController.normalizeBdPhone(newValue.text);
    return TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}
