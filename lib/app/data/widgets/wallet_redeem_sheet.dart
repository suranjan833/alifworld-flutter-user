import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../config/app_color.dart';
import '../config/functions/dio_function/app_config.dart';
import '../config/functions/dio_function/my_dio.dart';
import '../models/redeem_model.dart';
import '../models/wallet_model.dart';
import '../widgets/wallet_pin_dialog.dart';

class WalletRedeemSheet extends StatefulWidget {
  final List<WalletItemModel> availableWallets;
  final String? initialWalletKind;
  final VoidCallback onRedeemSuccess;

  const WalletRedeemSheet({
    super.key,
    required this.availableWallets,
    this.initialWalletKind,
    required this.onRedeemSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required List<WalletItemModel> wallets,
    String? initialWalletKind,
    required VoidCallback onRedeemSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WalletRedeemSheet(
        availableWallets: wallets,
        initialWalletKind: initialWalletKind,
        onRedeemSuccess: onRedeemSuccess,
      ),
    );
  }

  @override
  State<WalletRedeemSheet> createState() => _WalletRedeemSheetState();
}

class _WalletRedeemSheetState extends State<WalletRedeemSheet> {
  static const Set<String> _redeemableKinds = {
    'customer_cashback',
    'customer_referral',
    'customer_club_bonus',
    'customer_star_bonus',
    'customer_advanced_return',
  };

  late List<WalletItemModel> _validWallets;
  late String _selectedKind;
  final _amountController = TextEditingController();

  bool _isPreviewLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  RedeemPreviewResponseModel? _preview;

  @override
  void initState() {
    super.initState();
    _validWallets = widget.availableWallets
        .where((w) => _redeemableKinds.contains(w.kind))
        .toList();

    if (_validWallets.isEmpty) {
      _selectedKind = 'customer_cashback';
    } else if (widget.initialWalletKind != null &&
        _redeemableKinds.contains(widget.initialWalletKind)) {
      _selectedKind = widget.initialWalletKind!;
    } else {
      _selectedKind = _validWallets.first.kind;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  WalletItemModel? get _currentWallet {
    try {
      return _validWallets.firstWhere((w) => w.kind == _selectedKind);
    } catch (_) {
      return null;
    }
  }

  void _onAmountChanged(String val) {
    if (_preview != null) {
      setState(() {
        _preview = null;
        _errorMessage = null;
      });
    }
  }

  void _fillMaxAmount() {
    final bal = _currentWallet?.balance ?? 0.0;
    if (bal <= 0) return;
    _amountController.text = bal.toStringAsFixed(2);
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount in ৳');
      return;
    }

    final amountMinor = (amount * 100).round();
    final currentBalMinor = _currentWallet?.balanceMinor ?? 0;

    if (amountMinor > currentBalMinor) {
      setState(() => _errorMessage = 'Amount exceeds available balance');
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await dioPost(
        endUrl: 'wallets/redeem/preview',
        data: {
          'walletKind': _selectedKind,
          'amountMinor': amountMinor,
        },
        isJson: true,
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final data = raw['data'] ?? raw;
      final error = raw['error'] is Map ? raw['error'] : null;

      if (!mounted) return;
      setState(() => _isPreviewLoading = false);

      if (statusCode == 200 && data is Map<String, dynamic>) {
        setState(() {
          _preview = RedeemPreviewResponseModel.fromJson(data);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _preview = null;
          _errorMessage = error?['message'] ?? raw['message'] ?? 'Unable to preview redeem';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreviewLoading = false;
        _errorMessage = 'Network error during preview: $e';
      });
    }
  }

  Future<void> _executeRedeem() async {
    if (_preview == null) {
      await _fetchPreview();
      if (_preview == null) return;
    }
    if (!mounted) return;

    // Prompt for 6-digit Wallet PIN
    final pin = await WalletPinDialog.promptPin(
      context,
      title: 'Confirm Redeem PIN',
      subtitle: 'Enter your 6-digit wallet PIN to complete redemption',
    );

    if (pin == null || pin.isEmpty) return;

    final idempotencyKey = generateUuidV4();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await dioPost(
        endUrl: 'wallets/redeem',
        data: {
          'walletKind': _preview!.walletKind,
          'amountMinor': _preview!.amountMinor,
          'idempotencyKey': idempotencyKey,
          'walletPin': pin,
        },
        isJson: true,
      );

      final statusCode = res.statusCode ?? 500;
      final raw = res.data is Map ? res.data : {};
      final error = raw['error'] is Map ? raw['error'] : null;

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (statusCode >= 200 && statusCode < 300) {
        showSnack(
          'Redeem Successful',
          '৳${_preview!.amount.toStringAsFixed(2)} redeemed successfully!',
          bg: AppColor.green,
        );
        widget.onRedeemSuccess();
        Navigator.of(context).pop();
      } else {
        final code = error?['code']?.toString() ?? '';
        final msg = error?['message']?.toString() ?? raw['message']?.toString() ?? 'Redemption failed';
        if (code == 'WALLET_PIN_INVALID') {
          showSnack('Invalid PIN', msg, bg: AppColor.red);
        } else if (code == 'WALLET_PIN_LOCKED') {
          showSnack('PIN Locked', msg, bg: AppColor.red);
        } else {
          setState(() => _errorMessage = msg);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error executing redeem: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final wallet = _currentWallet;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: bottomInset + 24.h,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.repeat, color: AppColor.primary, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redeem Bonus Balance',
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        'Convert bonus balances into Main, Shopping & Good-Luck',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Wallet Selector
            Text(
              'Select Bonus Wallet',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColor.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKind,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _validWallets.map((w) {
                    return DropdownMenuItem<String>(
                      value: w.kind,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(w.icon, size: 18.r, color: AppColor.primary),
                              SizedBox(width: 10.w),
                              Text(
                                w.title,
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '৳${w.balance.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newKind) {
                    if (newKind != null && newKind != _selectedKind) {
                      setState(() {
                        _selectedKind = newKind;
                        _preview = null;
                        _errorMessage = null;
                        _amountController.clear();
                      });
                    }
                  },
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Amount Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount to Redeem (৳)',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  'Available: ৳${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _onAmountChanged,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter amount in taka',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Center(
                    widthFactor: 1.0,
                    child: Text(
                      '৳',
                      style: GoogleFonts.lato(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ),
                ),
                suffixIcon: TextButton(
                  onPressed: _fillMaxAmount,
                  child: Text(
                    'MAX',
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.primary,
                    ),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              SizedBox(height: 10.h),
              Text(
                _errorMessage!,
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: AppColor.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Preview Section
            if (_isPreviewLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColor.primary),
                ),
              )
            else if (_preview != null) ...[
              _buildPreviewDetails(_preview!),
              SizedBox(height: 18.h),
            ],

            // Action Button
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (_preview == null ? _fetchPreview : _executeRedeem),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.white),
                        ),
                      )
                    : Text(
                        _preview == null ? 'Preview Breakdown' : 'Confirm & Redeem with PIN',
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewDetails(RedeemPreviewResponseModel preview) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeem Amount',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                '৳${preview.amount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFCBD5E1)),

          // 1. You will receive
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColor.green, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                'You will receive:',
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...preview.receiveShares.map((s) => Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.displayName,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      '+ ৳${s.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.green.shade700,
                      ),
                    ),
                  ],
                ),
              )),

          SizedBox(height: 10.h),

          // 2. Deducted
          if (preview.deductedShares.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.remove_circle_outline, color: const Color(0xFFE11D48), size: 16.r),
                SizedBox(width: 6.w),
                Text(
                  'Deducted:',
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ...preview.deductedShares.map((s) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.displayName,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        '- ৳${s.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
