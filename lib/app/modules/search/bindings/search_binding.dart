import 'package:get/get.dart';
import '../controllers/catalog_search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatalogSearchController>(() => CatalogSearchController());
  }
}
