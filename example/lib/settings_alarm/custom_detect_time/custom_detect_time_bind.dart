import 'package:get/get.dart';

import 'custom_detect_time_logic.dart';

class CustomDetectTimeBind implements Bindings {
  @override
  void dependencies() {
    Get.put<CustomDetectTimeLogic>(CustomDetectTimeLogic());
  }
}
