import 'package:vsdk_example/utils/device_manager.dart';

import '../../utils/super_put_controller.dart';
import '../Settings_logic.dart';
import 'custom_detect_time_state.dart';
import 'package:get/get.dart';

class CustomDetectTimeLogic extends SuperPutController<CustomDetectTimeState> {
  CustomDetectTimeLogic() {
    value = CustomDetectTimeState();
  }

  @override
  void onInit() {
    for (int i = 0; i < 24; i++) {
      state!.hours.add(i);
    }
    for (int i = 0; i < 60; i++) {
      state!.minutes.add(i);
    }
    initStartEndTime();
    super.onInit();
  }

  initStartEndTime() {
    if (DeviceManager.getInstance().deviceModel!.actionMotionPlans.isNotEmpty) {
      var actionPlan =
          DeviceManager.getInstance().deviceModel!.actionMotionPlans[0];
      state!.startHour.value =
          int.parse((actionPlan.startTime ?? "00:00").split(":")[0]);
      state!.startMinute.value =
          int.parse((actionPlan.startTime ?? "23:59").split(":")[1]);
      state!.endHour.value =
          int.parse((actionPlan.endTime ?? "00:00").split(":")[0]);
      state!.endMinute.value =
          int.parse((actionPlan.endTime ?? "23:59").split(":")[1]);
      state!.days = (actionPlan.weekData ?? "[]")
          .split(",")
          .map((e) => int.parse(e))
          .toList()
          .obs;
    }
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  void save() {
    if (state!.days.length == 0) {
      Get.snackbar("提示", "请选择日期");
      return;
    }
    SettingsLogic settingsLogic = Get.find<SettingsLogic>();
    int startTime = state!.startHour.value * 60 + state!.startMinute.value;
    int endTime = state!.endHour.value * 60 + state!.endMinute.value;
    settingsLogic.state!.startTime(startTime);
    settingsLogic.state!.endTime(endTime);
    settingsLogic.state!.days(state!.days);
    settingsLogic.state!.smartTimeIndex(3);
    Get.back();
  }
}
