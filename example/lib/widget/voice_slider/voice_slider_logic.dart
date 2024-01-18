import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../settings_normal/settings_normal_state.dart';
import '../../utils/device_manager.dart';
import '../../utils/super_put_controller.dart';

class VoiceSliderLogic extends SuperPutController<SettingsNormalState> {
  VoiceSliderLogic(SettingsNormalState state) {
    value = state;
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  void saveVolume() async {
    bool bl = false;
    bool bl2 = false;
    bl = await DeviceManager.getInstance()
            .mDevice
            ?.changeVolume(24, state!.microphoneVoice.value.toInt()) ??
        false;
    if (bl) {
      print("------麦克风声音设置成功--------");
    }
    bl2 = await DeviceManager.getInstance()
            .mDevice
            ?.changeVolume(25, state!.hornVoice.value.toInt()) ??
        false;
    if (bl2) {
      print("------喇叭声音设置成功--------");
    }
    if (bl && bl2) {
      EasyLoading.showToast("设置成功！");
    }
  }
}
