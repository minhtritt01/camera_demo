import 'package:vsdk/camera_device/commands/camera_command.dart';
import 'package:vsdk/camera_device/commands/status_command.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';
import 'package:vsdk_example/play/play_logic.dart';
import 'package:vsdk_example/settings_normal/settings_normal_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:get/get.dart';
import '../model/device_model.dart';
import '../utils/super_put_controller.dart';
import '../widget/voice_slider/voice_slider_widget.dart';

class SettingsNormalLogic extends SuperPutController<SettingsNormalState> {
  SettingsNormalLogic() {
    value = SettingsNormalState();
  }

  @override
  void onInit() {
    getPowerMode();
    getLedLightHidden();
    if (DeviceManager.getInstance().deviceModel!.supportPinInPic.value == 1 ||
        DeviceManager.getInstance()
                .deviceModel!
                .supportMutilSensorStream
                .value ==
            1) {
      getLinkableEnable();
    }
    DeviceManager.getInstance().mDevice!.getRecordParam();
    getInitState();
    getAllStatus();
    super.onInit();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  ///初始化省电模式数据
  void getPowerMode() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .powerCommand
            ?.getPowerMode() ??
        false;
    PowerMode? powerM =
        DeviceManager.getInstance().mDevice!.powerCommand?.powerMode;
    print("----bl--$bl---------getPowerMode-----------powerM:$powerM");
    if (powerM == PowerMode.none) {
      DeviceManager.getInstance().deviceModel?.lowMode.value = LowMode.none;
      state?.lowMode.value = LowMode.none;
    } else if (powerM == PowerMode.low) {
      DeviceManager.getInstance().deviceModel?.lowMode.value = LowMode.low;
      state?.lowMode.value = LowMode.low;
    } else if (powerM == PowerMode.veryLow) {
      DeviceManager.getInstance().deviceModel?.lowMode.value = LowMode.veryLow;
      state?.lowMode.value = LowMode.veryLow;
    }
  }

  ///开启省电模式
  void onClickSavePowerMode() async {
    ///打开省电模式
    controlLowPowerMode(LowMode.low);

    ///关闭智能省电模式
    closeSmartElectricity();
  }

  ///开启持续工作模式
  void onClickKeepWorkMode() async {
    //持续工作模式，设备不睡眠，一直工作，电池很快就会消耗完
    ///打开持续工作模式
    controlLowPowerMode(LowMode.none);

    ///关闭智能省电模式
    closeSmartElectricity();
  }

  ///开启超级省电模式
  void onClickVeryLowPowerMode() async {
    //超级省电模式，摄像机处于超级省电模式，只有运动侦测才会唤醒设备，App无法唤醒设备。此模式电池电力消耗最少
    ///打开超级省电模式
    controlLowPowerMode(LowMode.veryLow);

    ///关闭智能省电模式
    closeSmartElectricity();
  }

  void closeSmartElectricity() {
    if (DeviceManager.getInstance()
            .deviceModel!
            .supportSmartElectricitySleep
            .value ==
        1) {
      ///关闭智能省电模式
      setSmartElectricitySleep(0, 50);
    }
  }

  ///省电模式设置
  void controlLowPowerMode(LowMode lowMode) async {
    PowerMode powerMode = PowerMode.none;
    if (lowMode == LowMode.none) {
      powerMode = PowerMode.none;
    } else if (lowMode == LowMode.low) {
      powerMode = PowerMode.low;
    } else if (lowMode == LowMode.veryLow) {
      powerMode = PowerMode.veryLow;
    }
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .powerCommand
            ?.controlPower(powerMode) ??
        false;
    if (bl) {
      DeviceManager.getInstance().deviceModel!.lowMode.value = lowMode;
      state?.lowMode.value = lowMode;
      print("设置成功");
    } else {
      print("设置失败");
    }
  }

  ///智能省电（微功耗）开关设置
  void setSmartElectricitySleep(int switchV, int threshold) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .powerCommand
            ?.setSmartElectricitySleep(switchV,
                electricityThreshold: threshold) ??
        false;
    if (bl) {
      DeviceManager.getInstance()
          .deviceModel
          ?.smartElectricitySleepSwitch
          .value = switchV == 1;
      state?.smartElecSwitch.value = switchV == 1;
      print("智能省电（微功耗）设置成功");
    }
  }

  ///指示灯隐藏开关
  void ledLightHidden(bool hidden) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.ledCommand
            ?.controlLed(hidden) ??
        false;
    if (bl) {
      DeviceManager.getInstance().deviceModel?.ledLight.value = hidden;
      state?.ledHidden.value = hidden;
    }
  }

  ///获取指示灯隐藏状态
  void getLedLightHidden() async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.ledCommand?.getLedState() ??
            false;
    if (bl) {
      DeviceManager.getInstance().deviceModel?.ledLight.value =
          DeviceManager.getInstance().mDevice?.ledCommand?.hideLed ?? false;
      state?.ledHidden.value =
          DeviceManager.getInstance().mDevice?.ledCommand?.hideLed ?? false;
    }
  }

  void onVoiceClick() async {
    Get.bottomSheet(VoiceSliderWidget());
  }

  Future<bool> getInitState() async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.getCameraParams() ?? false;
    if (bl) {
      state?.microphoneVoice.value =
          DeviceManager.getInstance().mDevice?.involume?.toDouble() ?? 0;
      state?.hornVoice.value =
          DeviceManager.getInstance().mDevice?.outvolume?.toDouble() ?? 0;
      state?.is60Hz.value = DeviceManager.getInstance().mDevice?.lightMode == 1;
      state?.isOverturn.value =
          DeviceManager.getInstance().mDevice?.direction.index == 3;
    }
    return bl;
  }

  void getAllStatus() async {
    StatusResult? result =
        await DeviceManager.getInstance().mDevice?.getStatus(cache: false);
    state!.isTimeOSD.value = result?.osdenable == "1";
  }

  ///获取联动开关状态
  getLinkableEnable() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .qiangQiuCommand
            ?.getLinkageEnable() ??
        false;
    if (bl) {
      state!.linkableSwitch.value = DeviceManager.getInstance()
              .mDevice!
              .qiangQiuCommand
              ?.gblinkage_enable ==
          1;
    }
  }

  ///控制联动校正开关
  controlLinkableEnable(bool enable) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .qiangQiuCommand
            ?.controlLinkageEnable(enable ? 1 : 0) ??
        false;
    if (bl) {
      state!.linkableSwitch.value = enable;
      PlayLogic playLogic = Get.find<PlayLogic>();
      playLogic.state!.isLinkableOpen.value = enable;
    }
  }

  ///设置视频画面是否翻转
  void setCameraDirection(bool isOverturn) async {
    VideoDirection direction = VideoDirection.none;
    if (isOverturn) {
      direction = VideoDirection.mirrorAndFlip;
    }
    bool bl =
        await DeviceManager.getInstance().mDevice!.changeDirection(direction);
    if (bl) {
      state!.isOverturn(isOverturn);
    }
  }

  ///灯光抗干扰
  void setLightMode(bool is60Hz) async {
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .changeLightMode(is60Hz ? 1 : 0);
    if (bl) {
      state!.is60Hz(is60Hz);
    }
  }

  ///视频时间显示开关
  void setVideoTimeOsd(bool isTimeOSD) async {
    print("-----setVideoTimeOsd---$isTimeOSD-------------");
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .changeShowTime(isTimeOSD ? 1 : 0);
    if (bl) {
      print("-----setVideoTimeOsd---success-----------");
      state!.isTimeOSD(isTimeOSD);
    }
  }
}
