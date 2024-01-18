import 'package:get/get.dart';

import 'detect_area_draw_logic.dart';

class DetectAreaDrawBind implements Bindings {
  @override
  void dependencies() {
    Get.put<DetectAreaDrawLogic>(DetectAreaDrawLogic());
  }
}
