import 'package:get/get.dart';

class ShippingPolicyController extends GetxController {
  final freeShippingThreshold = '₹499'.obs;

  final shippingDetails = const [
    {
      'title': 'Standard Delivery (2 - 4 Days)',
      'description': 'Orders above ₹499 qualify for FREE standard delivery across India. A nominal fee of ₹49 applies to smaller orders.',
    },
    {
      'title': 'Express Same-Day Delivery',
      'description': 'Available in select metro areas for orders placed before 12:00 PM. Express delivery charge is ₹99.',
    },
    {
      'title': 'Order Dispatch & Tracking',
      'description': 'Once your order is dispatched, you will receive an SMS and push notification containing a real-time live tracking link.',
    },
    {
      'title': 'Delivery Inspection',
      'description': 'Please inspect the package seal at delivery. Do not accept open or damaged parcels.',
    },
  ];
}
