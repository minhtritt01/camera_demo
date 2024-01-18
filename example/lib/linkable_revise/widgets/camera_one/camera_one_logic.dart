import 'package:get/get.dart';

import '../../../utils/super_put_controller.dart';
import '../../linkable_revise_state.dart';

/// CameraOne 控制器
mixin CameraOneLogic on SuperPutController<LinkableReviseState> {
  @override
  void initPut() {
    lazyPut<CameraOneLogic>(this);
    super.initPut();
  }
}
