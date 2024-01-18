import 'package:vsdk_example/utils/device_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../utils/super_put_controller.dart';
import '../../linkable_revise_state.dart';
import 'package:get/get.dart';

/// SureButton 控制器
mixin SureButtonLogic on SuperPutController<LinkableReviseState> {
  @override
  void initPut() {
    lazyPut<SureButtonLogic>(this);
    super.initPut();
  }

  void goDeviceRevise() async {
    var dateTime = new DateTime.now().millisecondsSinceEpoch;
    String time = dateTime.toString().substring(0, 10);
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .qiangQiuCommand
            ?.controlRevisePoint(
                state!.xPercent.value, state!.yPercent.value) ??
        false;
    if (bl) {
      ///
      print("----------校正完成------------------");
      EasyLoading.showToast("校正完成 !");
      Get.back();
    }
  }
}
