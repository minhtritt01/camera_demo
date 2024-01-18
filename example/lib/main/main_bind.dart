import 'package:get/get.dart';
import 'main_logic.dart';

class MainBind implements Bindings {
  @override
  void dependencies() {
    Get.put<MainLogic>(MainLogic());
  }

  void dispose() {
    Get.delete<MainLogic>();
  }
}
