import 'package:get/get.dart';

class TermsAndConditionsController extends GetxController {
  final lastUpdated = '24 September 2026'.obs;

  final sections = const [
    {
      'title': '1. Agreement to Terms',
      'content': 'By accessing or using the Alif Shopping Application, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree, please refrain from using our services.',
    },
    {
      'title': '2. User Accounts',
      'content': 'You are responsible for maintaining the confidentiality of your account credentials and for all activities conducted under your account. Promptly notify us of any unauthorized usage.',
    },
    {
      'title': '3. Orders & Pricing',
      'content': 'All orders are subject to availability and acceptance. Prices listed are in Indian Rupees (INR) and include applicable taxes unless specified otherwise.',
    },
    {
      'title': '4. Intellectual Property',
      'content': 'All trademarks, logos, content, software code, and graphics on the Alif Application remain the exclusive property of Alif Commerce Inc.',
    },
    {
      'title': '5. Limitation of Liability',
      'content': 'Alif shall not be liable for indirect, incidental, special, or consequential damages resulting from the use or inability to use our platform or products.',
    },
  ];
}
