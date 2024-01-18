import 'package:get/get.dart';
import 'package:vsdk_example/settings_normal/settings_normal_logic.dart';

import '../widget/voice_slider/voice_slider_logic.dart';

class SettingsNormalBind implements Bindings {
  @override
  void dependencies() {
    Get.put<SettingsNormalLogic>(SettingsNormalLogic());
    SettingsNormalLogic normalLogic = Get.find<SettingsNormalLogic>();
    Get.put<VoiceSliderLogic>(VoiceSliderLogic(normalLogic.state!));
  }
}
