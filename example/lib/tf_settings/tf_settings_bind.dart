import 'package:get/get.dart';
import 'package:vsdk_example/tf_settings/tf_settings_logic.dart';

class TFSettingsBind implements Bindings {
  @override
  void dependencies() {
    Get.put<TFSettingsLogic>(TFSettingsLogic());
  }
}
