import '../../settings_alarm/Settings_state.dart';
import '../../utils/device_manager.dart';
import '../../utils/super_put_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SliderLogic extends SuperPutController<SettingsState> {
  SliderLogic(SettingsState state) {
    value = state;
  }

  ///默认近中远三级，对应 1-3
  void setDetectionRange(int distance) async {
    bool bl =
        await DeviceManager.getInstance().mDevice!.setDetectionRange(distance);
    if (bl) {
      print("-------侦测距离----设置成功--------");
      state?.detectionRange.value = distance;
    } else {
      EasyLoading.showToast("设置失败，请确保设备已连接！");
    }
  }

  ///灵敏度，低中高
  Future<bool> setSensitivity(int level) async {
    bool bl = false;
    if (state?.motionPushEnable.value == 5) {
      bl = await DeviceManager.getInstance()
          .mDevice!
          .setHumanDetectionLevel(level);
      print("--------setSensitivity------$bl-----------");
    } else if (state?.motionPushEnable.value == 1) {
      int le = 5;
      bool isOpen = true;
      if (level == 2) {
        le = 5;
      } else if (level == 1) {
        le = 9;
      } else if (level == 3) {
        le = 1;
      } else if (level == 0) {
        le = 5;
        isOpen = false;
      }
      bl = await DeviceManager.getInstance()
          .mDevice!
          .setAlarmMotionDetection(isOpen, le);
    }
    if (bl) {
      state?.sensitivity.value = level;
    }
    return bl;
  }

  @override
  void onHidden() {
    print("---------onHidden-----------");
  }
}
