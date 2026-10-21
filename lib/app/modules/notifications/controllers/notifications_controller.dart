
import 'package:get/get.dart';

import '../../../data/mixins/skeleton_loading_mixin.dart';

class NotificationsController extends GetxController
    with SkeletonLoadingMixin {
  final notificationsList = <Map<String, dynamic>>[
    {
      'title': 'Order Dispatched! 🚚',
      'body': 'Your order #ALF-98742 has been dispatched and is on its way.',
      'time': '10 mins ago',
      'isRead': false,
    },
    {
      'title': 'Weekend Offer 20% OFF! 🎉',
      'body':
          'Use code WEEKEND20 at checkout to get 20% OFF on all Electronics.',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'title': 'Order Delivered 📦',
      'body': 'Your order #ALF-85412 has been delivered successfully.',
      'time': '1 day ago',
      'isRead': true,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    initSkeletonLoading();
  }

  void markAllAsRead() {
    for (var n in notificationsList) {
      n['isRead'] = true;
    }
    notificationsList.refresh();
  }
}
