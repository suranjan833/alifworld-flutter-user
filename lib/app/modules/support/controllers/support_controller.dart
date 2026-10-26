import 'package:get/get.dart';

import '../../../data/config/app_color.dart';
import '../../../data/mixins/skeleton_loading_mixin.dart';

class SupportController extends GetxController with SkeletonLoadingMixin {
  final supportPhone = '+91 1800 123 4567'.obs;
  final supportEmail = 'support@alif.com'.obs;

  final faqs = <Map<String, String>>[
    {
      'question': 'How do I track my order?',
      'answer': 'Go to My Orders section in your account to see real-time status of your orders.',
    },
    {
      'question': 'What is the return policy?',
      'answer': 'We offer a 7-day hassle-free return policy for unused products in original packaging.',
    },
    {
      'question': 'How can I contact customer care?',
      'answer': 'You can call our toll-free number or email us directly from the buttons above.',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
  }

  void openLiveChat() {
    Get.snackbar(
      'Live Chat',
      'Connecting to support agent...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.primary,
      colorText: AppColor.black,
    );
  }
}
