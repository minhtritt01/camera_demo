import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vsdk/camera_device/commands/param_command.dart';
import 'package:vsdk_example/app_routes.dart';
import '../model/plan_model.dart';
import '../settings_main/settings_main_logic.dart';
import '../utils/device_manager.dart';
import '../utils/super_put_controller.dart';
import '../widget/slider_widget/slider_widget.dart';
import 'Settings_state.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SettingsLogic extends SuperPutController<SettingsState> {
  SettingsLogic() {
    value = SettingsState();
  }

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init() async {
    ///初始化报警开关状态
    if (DeviceManager.getInstance().deviceModel!.supportAI.value == 1) {
      await getMotionAlarmPlan();
      state?.motionAlarm.value =
          state?.motionPushEnable.value == 0 ? false : true;

      if (state?.motionPushEnable.value == 5) {
        ///获取人形检测灵敏度
        bool bl =
            await DeviceManager.getInstance().mDevice!.getHumanDetectionLevel();
        DeviceManager.getInstance().deviceModel!.alarmLevel.value =
            DeviceManager.getInstance().mDevice!.humanLevel ?? 0;
        print(
            "-----$bl-----humanLevel-${DeviceManager.getInstance().mDevice!.humanLevel}------");
        if (bl && DeviceManager.getInstance().mDevice!.humanLevel == 0) {
          bool isT = await DeviceManager.getInstance()
              .mDevice!
              .setHumanDetectionLevel(3);
          if (isT) {
            print("-----------初始化灵敏度值-------success------");
            DeviceManager.getInstance().deviceModel!.alarmLevel.value = 3;
          }
        }
      }
      if (state?.motionPushEnable.value == 1) {
        int le = await getMotionAlarmLevel();
        DeviceManager.getInstance().deviceModel!.alarmLevel.value = le;
        print("-----motion-----alarmLevel-$le------");
      }

      state?.sensitivity.value =
          DeviceManager.getInstance().deviceModel!.alarmLevel.value;
    } else {
      await getAlarmStatus();
      var alarmType = DeviceManager.getInstance().deviceModel!.alarmType.value;
      var alarmStatus =
          DeviceManager.getInstance().deviceModel!.alarmStatus.value;
      var alarmLevel =
          DeviceManager.getInstance().deviceModel!.alarmLevel.value;
      state?.detectionFrequency.value = alarmLevel;
      state?.sensitivity.value =
          DeviceManager.getInstance().deviceModel!.alarmLevel.value;
      print("------alarmLevel-------$alarmLevel-------");

      ///运动侦测开关，如果是移动侦测，则看alarmStatus,如果是人形侦测，则判断alarmLevel
      state?.motionAlarm.value = alarmType == 1 ? alarmStatus : alarmLevel != 0;
      if (state?.motionAlarm.value == true) {
        ///初始化
        state?.motionPushEnable.value = alarmType == 1 ? 1 : 5;
      }
    }

    if (DeviceManager.getInstance().deviceModel?.isSupportLowPower.value ==
        true) {
      ///获取侦测距离
      getDetectionRange();
      state?.humanJudge.value =
          (DeviceManager.getInstance().mDevice!.humanoidDetection ?? 0) > 0;
    }

    ///获取报警闪光灯状态
    if (DeviceManager.getInstance().deviceModel?.haveWhiteLight.value ??
        false) {
      getAlarmLightMode();
    }

    ///获取云视频录像开关状态
    getCloudVideoSwitch();

    ///初始化报警声开关状态
    int voiceType = getVoiceType();
    getVoiceInfo(voiceType);

    ///初始化录制时长
    initRecordTime();

    ///获取智能侦测定时
    initSmartTimePlan();
  }

  int getVoiceType() {
    int voiceType = 1;
    if (state?.motionPushEnable.value == 1) {
      //移动侦测
      voiceType = 3;
    } else if (state?.motionPushEnable.value == 5) {
      //人形侦测
      voiceType = 1;
    }
    return voiceType;
  }

  ///报警类型
  Future<String?>? showSheetMotionAlarmTypeDialog(
      BuildContext? context, List<String> contents) {
    if (context == null) return null;
    List<Widget> widgets = [];
    contents.forEach((element) {
      widgets.add(CupertinoActionSheetAction(
        child: Text(
          element,
          style: TextStyle(
              color: ((element == "移动侦测" &&
                          (state?.motionPushEnable.value == 1 ||
                              DeviceManager.getInstance()
                                      .deviceModel!
                                      .alarmStatus
                                      .value ==
                                  true)) ||
                      (element == "人形侦测" &&
                          state?.motionPushEnable.value == 5 &&
                          DeviceManager.getInstance().deviceModel!.alarmLevel >
                              0))
                  ? Colors.red
                  : Theme.of(context).textTheme.button?.color,
              fontSize: 16,
              fontWeight: FontWeight.normal),
        ),
        onPressed: () {
          Navigator.of(context).pop(element);
        },
        isDefaultAction: true,
      ));
    });
    return showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            actions: widgets,
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                "取消",
                style: TextStyle(
                    color: Theme.of(context).textTheme.button?.color,
                    fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop('取消');
              },
            ),
          );
        });
  }

  ///运动侦测报警开关
  void clickChangeType() async {
    List<String> contents = [];
    if (DeviceManager.getInstance().deviceModel?.isSupportLowPower.value ==
        true) {
      ///低供电模式不支持移动侦测；
      contents = ["关闭", "人形侦测"];
    } else {
      contents = ["关闭", "移动侦测", "人形侦测"];
    }
    String? title = await showSheetMotionAlarmTypeDialog(Get.context, contents);
    print("--------运动侦测--------$title------");
    //注意：报警离线推送，需要用户登陆，获取用户信息用于离线推送开关设置
    if (title == "关闭") {
      ///离线推送，暂未实现
      // pushSeverSwitch(0);
      setMotionDetectionSwitch(false);
      if (DeviceManager.getInstance()
          .getDeviceModel()!
          .isSupportLowPower
          .value) {
        setHumanDetectionSwitch(false);
      } else {
        ///运动侦测计划开关
        selectedMotionTypeEnable(0);
      }

      ///关闭报警声
      setVoice("", "跟随系统", 0, 0);
      state?.motionAlarm.value = false;
      state?.motionPushEnable.value = 0; //关闭0，移动侦测1，人形侦测5
    } else if (title == "移动侦测") {
      setMotionDetectionSwitch(true);

      ///运动侦测计划开关
      selectedMotionTypeEnable(1);

      ///离线推送，暂未实现
      // pushSeverSwitch(1);
    } else if (title == "人形侦测") {
      if (DeviceManager.getInstance()
          .getDeviceModel()!
          .isSupportLowPower
          .value) {
        setHumanDetectionSwitch(true);
      } else {
        ///运动侦测计划开关
        selectedMotionTypeEnable(5);
      }

      ///离线推送，暂未实现
      // pushSeverSwitch(1);
    }
  }

  ///移动侦测开关
  void setMotionDetectionSwitch(bool enable) async {
    /// 报警灵敏度  1：长时间逗留才通知； 2：有人停留5秒后才通知； 3: 有人出现立即通知
    ///默认 5，对应报警灵敏度 2
    ///level 为1，对应报警灵敏度3，level 为9，对应报警灵敏度1，
    int level = DeviceManager.getInstance().deviceModel!.alarmLevel.value;
    if (enable && level == 0) {
      level = 5;
    }
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.setAlarmMotionDetection(enable, level) ??
        false;
    if (bl) {
      DeviceManager.getInstance().deviceModel!.alarmStatus.value = enable;
      print("------移动侦测开关设置成功！------");
      state?.motionAlarm.value = enable;
      if (enable) {
        ///设置报警声
        setVoiceInfo(3);
        state?.motionPushEnable.value = 1; //关闭0，移动侦测1，人形侦测5
      }
    } else {
      // EasyLoading.showToast("移动侦测开关设置失败");
    }
  }

  ///人形侦测开关
  void setHumanDetectionSwitch(bool enable) async {
    ///打开则设置默认level = 3, 关闭则设置为0；
    int level =
        enable ? DeviceManager.getInstance().deviceModel!.alarmLevel.value : 0;
    if (level == 0 && enable) {
      level = 3;
    }
    bool bl = await DeviceManager.getInstance().mDevice?.setPriPush(
            pushEnable: enable,
            videoEnable: enable,
            videoDuration: 10,
            autoRecordMode: 1) ??
        false;

    bool bl2 =
        await DeviceManager.getInstance().mDevice?.setPriDetection(level) ??
            false;
    if (bl) {
      DeviceManager.getInstance().deviceModel!.alarmLevel.value = level;
      print("------人形侦测开关设置成功！------");
      state?.motionAlarm.value = enable;
      if (enable) {
        ///设置报警声
        setVoiceInfo(1);
        state?.motionPushEnable.value = 5; //关闭0，移动侦测1，人形侦测5
      }
    }
  }

  ///运动侦测报警开关，关闭0，移动侦测1，人形侦测5
  void selectedMotionTypeEnable(int index) async {
    ///定时报警计划，默认可设置21个
    List records = [];
    for (int i = 0; i < 21; i++) {
      records.add(-1); //-1 不设置
    }
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.setMotionAlarmPlan(records: records, enable: index) ??
        false;
    if (bl) {
      state?.motionPushEnable.value = index;
      if (index != 0) {
        state?.motionAlarm.value = true;
        if (index == 5) {
          setVoiceInfo(1);
        }
      } else {
        state?.motionAlarm.value = false;
      }
    }
  }

  ///获取运动侦测报警设置数据
  Future<void> getMotionAlarmPlan() async {
    bool bl = await DeviceManager.getInstance().mDevice!.getMotionAlarmPlan();
    if (bl) {
      Map planMap =
          DeviceManager.getInstance().mDevice!.motionAlarmPlanData ?? {};
      int? motionPushEnable = int.tryParse(planMap["motion_push_enable"]);
      print("----------运动侦测模式：------$motionPushEnable--");
      if (motionPushEnable != null) {
        state?.motionPushEnable.value = motionPushEnable;
      }
    }
  }

  /// 1 人形侦测报警提示音, 3 移动侦测提示音
  getVoiceInfo(int voiceType) async {
    bool isSuc = await DeviceManager.getInstance()
            .mDevice
            ?.customSound
            ?.getVoiceInfo(voiceType) ??
        false;
    if (isSuc) {
      print("----------获取声音成功------");
      Map? data = DeviceManager.getInstance().mDevice?.customSound?.soundData;
      if (data == null) return;
      state?.alarmSoundOpen.value = data["switch"] == "1";
    }
  }

  /// 1 人形侦测报警提示音, 3 移动侦测提示音
  setVoiceInfo(int voiceType) async {
    ///如果有下载报警声，则可用本地sourcePath
    // String path = await getDirectory();
    // if (path.isEmpty) return;
    // String savePath = path + '/ALocalVoice';
    // Directory dir = Directory(savePath);
    // if (dir.existsSync() != true) {
    //   print('不存在');
    //   dir.createSync();
    // }
    // String sourcePath = savePath + '/' + "跟随系统" + '.wav';
    // print('本地声音路径 sourcePath----$sourcePath');

    String sourcePath =
        "http://doraemon-hongkong.camera666.com/cn_jinzhi_douliu_1694253028.wav";
    String name = "此区域禁止逗留，请速离开";

    if (voiceType == 1) {
      sourcePath =
          "http://doraemon-hongkong.camera666.com/cn_yuejie_1694252725.wav";
      name = "非法越界";
    }

    ///第一次设置，让设备播放，用于检测是否设置成功
    bool isSuc = await setVoice(sourcePath, name, 1, voiceType, play: true);

    ///第二次设置播放开关
    Future.delayed(Duration(milliseconds: 500), () async {
      bool isSuc = await setVoice(sourcePath, name, 1, voiceType);
      if (isSuc) {
        print("-------voiceType------报警声设置成功！---------");
      }
    });
  }

  Future<bool> setVoice(String path, String name, int switchV, int type,
      {bool play = false}) async {
    bool isSuc = await DeviceManager.getInstance()
            .mDevice
            ?.customSound
            ?.setVoiceInfo(path, name, switchV, type, playInDevice: play) ??
        false;
    getVoiceInfo(type);
    return isSuc;
  }

  ///获取声音文件可存储在本地，可用于设置报警声
  ///{version: 940, list: [{name: 此区域禁止逗留，请速离开, url: http://doraemon-hongkong.camera666.com/cn_jinzhi_douliu_1694253028.wav}, {name: 发现有车辆逆行，请紧急处理！, url: http://doraemon-hongkong.camera666.com/cn_che_nixing_1694252823.wav}, {name: 非法越界，请速离开, url: http://doraemon-hongkong.camera666.com/cn_yuejie_1694252725.wav}, {name: 您有包裹被取走，请注意核对, url: http://doraemon-hongkong.camera666.com/cn_baoguo_quzou_1694252572.wav}, {name: 您有包裹滞留时间过长，请及时查收, url: http://doraemon-hongkong.camera666.com/cn_baoguo_zhiliu_1694252316.wav}, {name: 您有新的包裹，请注意查收, url: http://doraemon-hongkong.camera666.com/baoguo_chashou_cn_1694251266.wav}, {name: 消防警铃声, url: http://doraemon.camera666.com/xiaofang_1578107385.wav}, {name: 110警报声, url: http://doraemon.camera666.com/110_1578107412.wav}, {name: 120警报声, url: http://doraemon.camera666.com/120_1578107430.wav},
  // Future<Map?> getLocalSoundFile() async {
  //   var response = await AppWebApi().getLocalSoundFile("zh");
  //   print("data--LocalSoundFile--${response.data}");
  //   if (response.statusCode == 200) {
  //     return response.data;
  //   }
  //   return null;
  // }

  ///获取报警状态
  Future<bool> getAlarmStatus() async {
    if (DeviceManager.getInstance().deviceModel == null) return false;
    if (DeviceManager.getInstance().mDevice == null) return false;
    bool bl;
    if (DeviceManager.getInstance().deviceModel!.alarmType.value == 0) {
      ///低功耗 人体侦测
      bl = await DeviceManager.getInstance().mDevice!.getAlarmParam();
      if (bl) {
        DeviceManager.getInstance().deviceModel!.alarmStatus.value =
            DeviceManager.getInstance().mDevice!.pirPushEnable ?? false;
        DeviceManager.getInstance().deviceModel!.alarmVideoType.value =
            DeviceManager.getInstance().mDevice!.pirPushVideoEnable ?? false;
        DeviceManager.getInstance().deviceModel!.alarmLevel.value =
            DeviceManager.getInstance().mDevice!.pirDetection ?? 0;
        DeviceManager.getInstance().deviceModel!.alarmTime.value =
            DeviceManager.getInstance().mDevice!.pirCloudVideoDuration ?? 0;
        DeviceManager.getInstance().deviceModel!.autoRecordMode.value =
            DeviceManager.getInstance().mDevice!.autoRecordVideoMode ?? 0;
        return true;
      }
    } else if (DeviceManager.getInstance().deviceModel!.alarmType.value == 1) {
      ///长电
      int le = await getMotionAlarmLevel();

      ParamResult? result =
          await DeviceManager.getInstance().mDevice!.getParams(cache: false);
      if (result == null) {
        result =
            await DeviceManager.getInstance().mDevice!.getParams(cache: false);
      }
      DeviceManager.getInstance().deviceModel!.alarmStatus.value =
          result?.alarmMotionParam?.alarm_motion_armed == "1";
      DeviceManager.getInstance().deviceModel!.alarmLevel.value = le;
      DeviceManager.getInstance().deviceModel!.alarmTime.value =
          int.tryParse(result?.alarmMotionParam?.cloudVideoDuration ?? "") ??
              -1;
      return true;
    }
    return false;
  }

  Future<int> getMotionAlarmLevel() async {
    ParamResult? result =
        await DeviceManager.getInstance().mDevice!.getParams(cache: false);
    if (result == null) {
      result =
          await DeviceManager.getInstance().mDevice!.getParams(cache: false);
    }
    int level = int.tryParse(
            result?.alarmMotionParam?.alarm_motion_sensitivity ?? "") ??
        0;
    if (level == 9) {
      level = 1;
    } else if (level == 5) {
      level = 2;
    } else if (level == 1) {
      level = 3;
    }
    return level;
  }

  ///人形检测
  void setHumanDetect(int detect) async {
    print("----点击了-----human detect---$detect--------");
    bool bl =
        await DeviceManager.getInstance().mDevice!.setHuanoidDetection(detect);
    if (bl) {
      state!.humanJudge.value = detect == 1 ? true : false;
      if (detect == 0) {
        ///如果设置中关闭了人形判断，则人形框定也会失效
        SettingsMainLogic settingsMainLogic = Get.find<SettingsMainLogic>();
        settingsMainLogic.state?.peopleFrameOpen.value = false;
      }
    } else {
      EasyLoading.showToast("人形检测设置失败！");
    }
  }

  ///侦测距离
  void onDetectionRangeClick() async {
    print("----点击了-----onDetectionRangeClick-------");
    showRangeSheet();
  }

  ///显示滑动调节的底部窗口
  void showRangeSheet() {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            decoration: BoxDecoration(border: Border(top: BorderSide())),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("左右滑动调整距离:"),
                  SizedBox(height: 12),
                  Text(
                      "调整侦测范围，以实现不同的侦测灵敏度；仅适用于走廊、楼道等无太阳照射环境，室外环境使用请谨慎选择，会有概率误报警，建议打开人形检测同时工作"),
                  SizedBox(height: 20),
                  BottomSlider()
                ],
              ),
            ),
          );
        });
  }

  ///查询侦测距离设置范围
  Future<bool> getDetectionRange() async {
    bool bl = await DeviceManager.getInstance().mDevice!.getDetectionRange();
    DeviceManager.getInstance().getDeviceModel()?.detectionRange.value =
        DeviceManager.getInstance().mDevice!.distanceAdjust ?? 0;
    state?.detectionRange.value =
        DeviceManager.getInstance().mDevice!.distanceAdjust ?? 0;
    return bl;
  }

  ///侦测频率窗口
  Future<String?>? showSheetDetectionFrequencyDialog(BuildContext? context) {
    if (context == null) return null;
    List<String> contents = ["定期（低）", "一般（中）", "频繁（高）"];
    List<String> tips = [
      "运动侦测在每次报警后会间隔30S",
      "运动侦测在每次报警后会间隔15S",
      "运动侦测频率无间隔，始终保持活跃"
    ];
    List<Widget> widgets = [];
    contents.forEach((element) {
      widgets.add(CupertinoActionSheetAction(
        child: Column(
          children: [
            Text(
              element,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              tips[contents.indexOf(element)],
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        onPressed: () {
          Navigator.of(context).pop(element);
        },
        isDefaultAction: true,
      ));
    });
    return showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            actions: widgets,
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                "取消",
                style: TextStyle(
                    color: Theme.of(context).textTheme.button?.color,
                    fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop('取消');
              },
            ),
          );
        });
  }

  ///侦测频率点击
  void onDetectionFrequencyClick() async {
    String? title = await showSheetDetectionFrequencyDialog(Get.context);
    print('----------------title--$title------------------');
    bool bl = false;
    int level = 5;
    switch (title) {
      case "定期（低）":
        level = 1;
        bl = await setAlarmLever(level);
        break;
      case "一般（中）":
        level = 2;
        bl = await setAlarmLever(level);
        break;
      case "频繁（高）":
        level = 3;
        bl = await setAlarmLever(level);
        break;
      case "取消":
        level = 0;
        bl = await setAlarmLever(level);
        break;
    }
    print('------------------$bl------------------');
    if (bl) {
      state?.detectionFrequency.value = level;
    } else {
      EasyLoading.showToast("侦测频率设置失败！");
    }
  }

  ///设置侦测频率(灵敏度)
  Future<bool> setAlarmLever(int level) async {
    bool bl = false;
    if (DeviceManager.getInstance().getDeviceModel()!.alarmType.value == 0) {
      bl = await DeviceManager.getInstance().mDevice!.setPriDetection(level);
      print("--------setAlarmLever------$bl-----------");
    } else if (DeviceManager.getInstance().getDeviceModel()!.alarmType.value ==
        1) {
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
    return bl;
  }

  ///报警闪光灯开关,2打开闪烁，0关闭
  setAlarmLightSwitch(int value) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.lightCommand
            ?.controlLightMode(value) ??
        false;
    if (bl) {
      state?.alarmLightOpen.value = value == 2;
      print("---------报警闪光灯开关-----success-----------");
    }
  }

  ///获取报警闪光灯开关状态
  getAlarmLightMode() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.lightCommand
            ?.getLightSirenMode() ??
        false;
    if (bl) {
      print("---------getAlarmLightMode-----success-----------");
      int mode =
          DeviceManager.getInstance().mDevice?.lightCommand?.lightMode ?? 0;
      state?.alarmLightOpen.value = mode == 2;
    }
  }

  ///设置云视频录像开关
  setCloudVideoSwitch(bool value) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.setPriPush(videoEnable: value) ??
        false;
    if (bl) {
      state?.cloudVideoOpen.value = value;
      print("---------setCloudVideoSwitch-----success-----------");
    }
  }

  getCloudVideoSwitch() async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.getAlarmPirVideoPush() ??
            false;
    if (bl) {
      int v = DeviceManager.getInstance().mDevice?.videoEnable ?? 0;
      state?.cloudVideoOpen.value = v == 1;
      print("---------getCloudVideoSwitch-----value---$v--------");
    }
  }

  initRecordTime() {
    if (DeviceManager.getInstance().deviceModel!.autoRecordMode.value == 1) {
      state?.recordTimeIndex.value = 0;
    } else {
      if (DeviceManager.getInstance().deviceModel!.alarmTime.value == 5) {
        state?.recordTimeIndex.value = 1;
      } else if (DeviceManager.getInstance().deviceModel!.alarmTime.value ==
          10) {
        state?.recordTimeIndex.value = 2;
      } else if (DeviceManager.getInstance().deviceModel!.alarmTime.value ==
          15) {
        state?.recordTimeIndex.value = 3;
      } else if (DeviceManager.getInstance().deviceModel!.alarmTime.value ==
          30) {
        state?.recordTimeIndex.value = 4;
      } else {
        state?.recordTimeIndex.value = 2; //默认10秒
      }
    }
  }

  setRecordTime(int index) async {
    int duration = 10;
    int auto = 0;
    switch (index) {
      case 0:
        auto = 1;
        break;
      case 1:
        duration = 5;
        break;
      case 2:
        duration = 10;
        break;
      case 3:
        duration = 15;
        break;
      case 4:
        duration = 30;
        break;
      default:
        duration = 10;
        break;
    }
    bool bl = await DeviceManager.getInstance().mDevice?.setPriPush(
            pushEnable: true, videoDuration: duration, autoRecordMode: auto) ??
        false;
    if (bl) {
      state?.recordTimeIndex.value = index;
    }
  }

  List records = [];

  void setSmartDetect(int index) async {
    state!.smartTimeIndex(index);
    if (index == 0) {
      //全天
      if (records.length < 21) {
        int num = 21 - records.length;
        for (int i = 0; i < num; i++) {
          records.add(-1);
        }
      }
    } else if (index == 1) {
      //白天
      int startTime = 480;
      int endTime = 1200;
      List weeks = [7, 1, 2, 3, 4, 5, 6];
      records = getRecords(startTime, endTime, weeks);
    } else if (index == 2) {
      //夜间
      int startTime = 1200;
      int endTime = 480;
      List weeks = [7, 1, 2, 3, 4, 5, 6];
      records = getRecords(startTime, endTime, weeks);
    } else {
      //自定义
      Get.toNamed(AppRoutes.customDetectTime);
    }
  }

  ///计算自定义的records
  void getCustomRecords() {
    int startTime = state!.startTime.value;
    int endTime = state!.endTime.value;
    List weeks = state!.days;
    records = getRecords(startTime, endTime, weeks);
  }

  Future<void> setMotionSmartDetectTime() async {
    if (state!.smartTimeIndex.value == 3) {
      getCustomRecords();
    }
    if (state!.smartTimeIndex.value == 0) {
      records.clear();
      for (int i = 0; i < 21; i++) {
        records.add(-1);
      }
    }
    bool bl = await DeviceManager.getInstance().mDevice!.setMotionAlarmPlan(
        records: records, enable: state!.motionPushEnable.value);
    if (bl) {
      EasyLoading.showToast("保存成功");
      initSmartTimePlan();
      Get.back();
      print("------setMotionSmartDetectTime---$bl------");
      //重新获取新数据
    }
  }

  List getRecords(int startTime, int endTime, List<dynamic> weeks) {
    PlanModel model = PlanModel.fromPlans(
        startTime, endTime, weeks, DeviceManager.getInstance().mDevice!.id);
    var actionPlans = <PlanModel>[];
    actionPlans.add(model);
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
    return records;
  }

  void initSmartTimePlan() async {
    bool bl = await DeviceManager.getInstance().mDevice!.getMotionAlarmPlan();
    if (bl) {
      Map planMap =
          DeviceManager.getInstance().mDevice!.motionAlarmPlanData ?? {};
      int motionPushEnable = 0;
      List<PlanModel> planModels = [];
      if (planMap.isNotEmpty) {
        motionPushEnable = int.tryParse(planMap["motion_push_enable"]) ?? 0;
        for (int i = 1; i <= 21; i++) {
          String value = planMap["motion_push_plan$i"];
          int num = int.tryParse(value) ?? -1;
          if (num != 0 && num != -1 && num != 1) {
            PlanModel model = PlanModel.fromCgi(num);
            planModels.add(model);
          }
        }
      }
      DeviceManager.getInstance().deviceModel!.actionMotionPlans.clear();
      DeviceManager.getInstance().deviceModel!.motionPushEnable.value =
          motionPushEnable;
      if (planModels.isEmpty) {
        DeviceManager.getInstance().deviceModel!.has_Alarm_plan.value = false;
      } else {
        DeviceManager.getInstance().deviceModel!.has_Alarm_plan.value = true;
      }
      DeviceManager.getInstance()
          .deviceModel!
          .actionMotionPlans
          .addAll(planModels);
      getInitSmartTime();
    }
  }

  ///初始化智能侦测定时选中状态
  void getInitSmartTime() {
    if (DeviceManager.getInstance().deviceModel!.actionMotionPlans.isEmpty) {
      //全天
      state!.smartTimeIndex(0);
    } else {
      PlanModel model =
          DeviceManager.getInstance().deviceModel!.actionMotionPlans[0];
      if ((model.startTime ?? "00:00") == "08:00" &&
          (model.endTime ?? "23:59") == "20:00") {
        //白天
        state!.smartTimeIndex(1);
      } else if ((model.startTime ?? "00:00") == "20:00" &&
          (model.endTime ?? "23:59") == "08:00") {
        //夜间
        state!.smartTimeIndex(2);
      } else {
        //自定义
        state!.smartTimeIndex(3);
        //存储自定义的计划时间
        DeviceManager.getInstance()
            .deviceModel!
            .actionCustomPlans
            .addAll(DeviceManager.getInstance().deviceModel!.actionMotionPlans);
      }
    }
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
