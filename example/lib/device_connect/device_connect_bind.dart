import 'package:get/get.dart';

import 'device_connect_logic.dart';

class DeviceConnectBind implements Bindings {
  @override
  void dependencies() {
    Get.put<DeviceConnectLogic>(DeviceConnectLogic());
  }
}
