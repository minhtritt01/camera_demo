import 'package:get/get.dart';

import 'cloud_play_logic.dart';

class CloudPlayBind implements Bindings {
  @override
  void dependencies() {
    Get.put<CloudPlayLogic>(CloudPlayLogic());
  }

  void dispose() {
    Get.delete<CloudPlayLogic>();
  }
}
