import 'package:get/get.dart';

import 'linkable_revise_logic.dart';

class LinkableReviseBind implements Bindings {
  @override
  void dependencies() {
    Get.put<LinkableReviseLogic>(LinkableReviseLogic());
  }
}
