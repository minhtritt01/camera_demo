import 'package:get/get.dart';

import 'bluetooth_connect_logic.dart';

class BlueToothConnectBind implements Bindings {
  @override
  void dependencies() {
    Get.put<BlueToothConnectLogic>(BlueToothConnectLogic());
  }
}
