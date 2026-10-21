import 'package:get/get.dart';

class RefundPolicyController extends GetxController {
  final refundWindowDays = 7.obs;

  final guidelines = const [
    {
      'title': '7-Day Return Window',
      'description': 'Products can be returned within 7 days from the delivery date if unused and in original packaging.',
    },
    {
      'title': 'Eligible Reasons for Refund',
      'description': 'Defective items, damaged during delivery, wrong product delivered, or size/specification mismatch.',
    },
    {
      'title': 'Refund Processing Time',
      'description': 'Refunds are credited to your original payment method or Alif Wallet within 3-5 business days after pickup inspection.',
    },
    {
      'title': 'Non-Returnable Products',
      'description': 'Perishable food items, personal hygiene products, and unsealed digital merchandise are non-refundable.',
    },
  ];
}
