import '../../../utils/super_put_controller.dart';
import '../../linkable_revise_state.dart';

/// CameraTwo 控制器
mixin CameraTwoLogic on SuperPutController<LinkableReviseState> {
  @override
  void initPut() {
    lazyPut<CameraTwoLogic>(this);
    super.initPut();
  }
}
