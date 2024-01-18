import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk_example/tf_settings/tf_settings_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import '../model/plan_model.dart';
import '../utils/super_put_controller.dart';

class TFSettingsLogic extends SuperPutController<TFSettingsState> {
  TFSettingsLogic() {
    value = TFSettingsState();
  }

  @override
  void onInit() {
    initTF();
    getResolution();
    super.onInit();
  }

  initTF() async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    bool bl0 = await device.getRecordParam();
    if (bl0) {
      print(
          "-----getRecordParam---true----${device.recordResult.record_time_enable}-------");
      state!.audioSwitch.value =
          (device.recordResult.record_audio == '1' ? true : false);
      int timeEnable =
          int.tryParse(device.recordResult.record_time_enable ?? "0") ?? 0;
      if (timeEnable > 0) {
        state!.recordModel(0); //24小时录像
        return;
      }
    }
    bool bl1 = await device.getReocrdPlan();
    if (bl1) {
      Map planMap = device.realTimeRecordPlanData ?? {};
      print(
          "-----getReocrdPlan---true----${planMap["record_plan_enable" ?? "0"]}-------");
      if (planMap.isNotEmpty) {
        int planEnable =
            int.tryParse(planMap["record_plan_enable" ?? "0"]) ?? 0;
        List<PlanModel> planModels = [];
        for (int i = 1; i <= 21; i++) {
          String value = planMap["record_plan$i"];
          int num = int.tryParse(value) ?? 0;
          if (num != 0 && num != -1 && num != 1) {
            PlanModel model = PlanModel.fromCgi(num);
            planModels.add(model);
          }
        }
        if (planModels.isNotEmpty) {
          DeviceManager.getInstance().deviceModel!.actionCustomPlans.clear();
          DeviceManager.getInstance()
              .deviceModel!
              .actionCustomPlans
              .addAll(planModels);
        }
        if (planEnable > 0) {
          state!.recordModel(1); //计划录像
          return;
        }
      }
    }
    bool bl2 = await device.getDetectionReocrdPlan();
    if (bl2) {
      Map planMap = device.detectionRecordPlanData ?? {};
      print(
          "-----getDetectionReocrdPlan---true----${planMap["motion_record_enable" ?? "0"]}-------");
      if (planMap.isNotEmpty) {
        int motionEnable =
            int.tryParse(planMap["motion_record_enable" ?? "0"]) ?? 0;
        if (motionEnable > 0) {
          state!.recordModel(2); //运动侦测录像
          return;
        }
      }
    }
    state!.recordModel(3); //不录像
  }

  ///获取录像时间
  void getResolution() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .recordResolutionCommand
            ?.getRecordResolutionState() ??
        false;
    if (bl == true) {
      state!.tfResolution.value = DeviceManager.getInstance()
              .mDevice!
              .recordResolutionCommand
              ?.recordResolut ??
          2;
    }
  }

  ///设置录像时间
  void setTFRecordResolution(int resolution) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .recordResolutionCommand
            ?.controlRecordResolution(resolution) ??
        false;
    print("----setTFRecordResolution--$bl--resolution-$resolution-");
    if (bl) {
      state!.tfResolution.value = resolution;
    }
  }

  ///设置全天录制
  void setRecordDay(int enable) async {
    bool bl =
        await DeviceManager.getInstance().mDevice!.setRecordParams(enable);
    if (bl) {
      print("------setRecordDay----true------");
    }
  }

  ///运动侦测录制
  void setRecordMotion(int enable) async {
    var actionPlans = <PlanModel>[];
    actionPlans
        .addAll(DeviceManager.getInstance().deviceModel!.actionMotionPlans);
    List records = [];
    actionPlans.forEach((element) {
      records.add(element.sum);
    });

    if (records.length < 21) {
      int num = 21 - records.length;
      for (int i = 0; i < num; i++) {
        records.add(-1);
      }
    }
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .setDetectionReocrdPlan(records: records, enable: enable);
    if (bl) {
      print("------setRecordMotion----true------");
    }
  }

  ///计划录像
  void setRecordPlan(int enable) async {
    var actionPlans = <PlanModel>[];

    ///使用的是智能侦测定时的自定义时间段，可自行创建独立的自定义时间段，没有值则默认24小时侦测
    actionPlans
        .addAll(DeviceManager.getInstance().deviceModel!.actionCustomPlans);
    List records = [];
    actionPlans.forEach((element) {
      records.add(element.sum);
    });
    if (records.length < 21) {
      int num = 21 - records.length;
      for (int i = 0; i < num; i++) {
        records.add(-1);
      }
    }
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .setReocrdPlan(records: records, enable: enable);
    if (bl) {
      print("------setRecordPlan----true------");
    }
  }

  ///设置录像模式
  void setRecordMode(int index) {
    switch (index) {
      case 0:

        ///24小时全天录像
        setRecordDay(1);
        setRecordMotion(0);
        setRecordPlan(0);
        break;
      case 1:

        ///计划录像
        setRecordDay(0);
        setRecordMotion(0);
        setRecordPlan(1);
        break;
      case 2:

        ///运动侦测录像
        setRecordDay(0);
        setRecordMotion(1);
        setRecordPlan(0);
        break;
      case 3:

        ///不录像
        setRecordDay(0);
        setRecordMotion(0);
        setRecordPlan(0);
        break;
    }
    state!.recordModel(index);
  }

  String getPlanTime() {
    String time = "未添加自定义时间，默认24小时全天录制 \n（自定义计划可参考智能侦测定时的自定义时间段设置）";
    if (DeviceManager.getInstance().deviceModel!.actionCustomPlans.isNotEmpty) {
      var actionPlan =
          DeviceManager.getInstance().deviceModel!.actionMotionPlans[0];
      String startTime = actionPlan.startTime ?? "00:00";

      String endTime = actionPlan.endTime ?? "00:00";

      String weeks = "";
      List days = (actionPlan.weekData ?? "[]")
          .split(",")
          .map((e) => int.parse(e))
          .toList();
      days.forEach((element) {
        weeks += "周" + element.toString() + "、";
      });
      time = "$startTime - $endTime, $weeks";
    }

    return time;
  }

  ///设置录制声音
  void setAudioSwitch(bool isOpen) async {
    bool bl =
        await DeviceManager.getInstance().mDevice!.changedRecordVoice(isOpen);
    if (bl) {
      state!.audioSwitch(isOpen);
    }
  }

  Future<bool> tfFormat() async {
    bool bl = await DeviceManager.getInstance().mDevice!.formatSD();
    return bl;
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  getTFStatus() async {
    state!.times.value++;
    bool bl = await DeviceManager.getInstance().mDevice!.getRecordParam();
    String tfStatus = "4"; //正在格式化
    if (bl) {
      tfStatus =
          DeviceManager.getInstance().mDevice!.recordResult.record_sd_status;
      if (tfStatus == "1" || tfStatus == "2" || tfStatus == "0") {
        state!.isFormating.value = false;
        state!.times.value = 0;
      } else {
        if (state!.times.value < 30) {
          Future.delayed(Duration(seconds: 2), () {
            getTFStatus();
          });
        }
      }
    } else {
      if (state!.times.value < 30) {
        Future.delayed(Duration(seconds: 2), () {
          getTFStatus();
        });
      }
    }
  }

  String getTFStatusName() {
    String status =
        DeviceManager.getInstance().mDevice!.recordResult.record_sd_status;
    String stateStr = "未检测到TF卡";
    if (status == "3") {
      stateStr = '文件系统错误';
    } else if (status == "4") {
      stateStr = '正在格式化';
    } else if (status == "5") {
      stateStr = '未挂载';
    }
    return stateStr;
  }
}
