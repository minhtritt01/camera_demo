import 'package:get/get.dart';
import 'package:vsdk_example/play/play_logic.dart';
import 'package:vsdk_example/settings_main/settings_main_logic.dart';
import '../settings_alarm/Settings_logic.dart';
import '../settings_main/ptz/ptz_logic.dart';
import '../widget/slider_widget/slider_logic.dart';

class PlayBind implements Bindings {
  @override
  void dependencies() {
    Get.put<PlayLogic>(PlayLogic());
    Get.put<SettingsMainLogic>(SettingsMainLogic());
    Get.put<SettingsLogic>(SettingsLogic());
    SettingsLogic settingsLogic = Get.find<SettingsLogic>();
    Get.put<SliderLogic>(SliderLogic(settingsLogic.state!));
    SettingsMainLogic mainLogic = Get.find<SettingsMainLogic>();
    Get.put<PTZLogic>(PTZLogic(mainLogic.state!));
  }

  void dispose() {
    Get.delete<PlayLogic>();
    Get.delete<SettingsMainLogic>();
    // Get.delete<SettingsLogic>();
  }
}
