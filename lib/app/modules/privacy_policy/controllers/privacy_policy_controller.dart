import 'package:get/get.dart';

class PrivacyPolicyController extends GetxController {
  final lastUpdated = '24 September 2026'.obs;

  final policyPoints = const [
    {
      'title': '1. Information We Collect',
      'content': 'We collect personal details such as your name, email address, phone number, delivery address, and payment preferences when you create an account or place an order.',
    },
    {
      'title': '2. How We Use Your Data',
      'content': 'Your information is used strictly to process orders, improve application features, send transactional updates, and personalize your shopping experience.',
    },
    {
      'title': '3. Data Sharing & Security',
      'content': 'We do not sell your personal data. Data is shared with verified delivery partners and payment gateways solely to fulfill your requests using industry-standard encryption.',
    },
    {
      'title': '4. Cookies & Tracking',
      'content': 'We use essential session tokens and analytics cookies to maintain user logins and optimize performance.',
    },
    {
      'title': '5. Your Privacy Rights',
      'content': 'You may access, modify, or delete your account information anytime from the Account settings page or by reaching out to support.',
    },
  ];
}
