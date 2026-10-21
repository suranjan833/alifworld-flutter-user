import 'package:get/get.dart';

class AboutUsController extends GetxController {
  final appVersion = '1.0.0+1'.obs;
  final companyName = 'Alif Commerce Inc.'.obs;

  final coreValues = const [
    {
      'title': 'Customer First',
      'description': 'We prioritize customer satisfaction with 24/7 support and hassle-free services.',
    },
    {
      'title': 'Quality Assurance',
      'description': 'Every product on Alif is verified for authenticity and top-notch build quality.',
    },
    {
      'title': 'Fast Delivery',
      'description': 'Swift, reliable shipping networks bringing your orders right to your doorstep.',
    },
  ];
}
