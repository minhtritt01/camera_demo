import 'package:get/get.dart';
import 'package:vsdk_example/tf_play/tf_play_logic.dart';

class TFPlayBind implements Bindings {
  @override
  void dependencies() {
    Get.put<TFPlayLogic>(TFPlayLogic());
  }

  void dispose() {
    Get.delete<TFPlayLogic>();
  }
}
