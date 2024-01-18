import 'package:flutter/cupertino.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/status_command.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';
import 'package:vsdk_example/model/device_model.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:vsdk_example/utils/super_put_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'main_state.dart';

class MainLogic extends SuperPutController<MainState> {
  TextEditingController idController = TextEditingController();
  TextEditingController pswController = TextEditingController();

  MainLogic() {
    // AppPlayerController();
    value = MainState();
  }

  @override
  void onInit() {
    super.onInit();
  }

  saveDeviceInfo() {
    if (idController.text.length < 1) {
      EasyLoading.showToast("请输入设备id");
      return;
    }
    state!.uid = idController.text;
    if (pswController.text.isEmpty) {
      state!.psw = "888888";
    } else {
      state!.psw = pswController.text;
    }
  }

  Future<bool> init(String did, {String psw = "888888"}) async {
    ///did 你的摄像机did
    CameraDevice device = CameraDevice(did, 'Margaret', 'admin', psw, 'QW6-T');
    DeviceManager.getInstance().setDevice(device);
    device.getClientPtr();
    DeviceModel deviceModel = DeviceModel(device.id, device);
    DeviceManager.getInstance().setDeviceModel(deviceModel);
    bool bl = await connectDevice(device);
    return bl;
  }

  Future<bool> connectDevice(CameraDevice device) async {
    device.removeListener(statusListener);
    device.removeListener(_connectStateListener);
    device.addListener<StatusChanged>(statusListener);
    device.addListener<CameraConnectChanged>(_connectStateListener);
    CameraConnectState connectState = await device.connect();
    state?.connectState = connectState;
    _connectStateListener(device, connectState);
    print("设备状态：connectState $connectState");
    if (connectState == CameraConnectState.connected) {
      var result = await device.getParams(cache: false);
      print("result $result");
      return true;
    }
    return false;
  }

  void _connectStateListener(
      CameraDevice device, CameraConnectState connectState) {
    var deviceModel = DeviceManager.getInstance().deviceModel;
    if (deviceModel == null) return;
    print("------connectState------$connectState---------------");
    state!.connectState = connectState;
    switch (connectState) {
      case CameraConnectState.connecting:
        deviceModel.connectState.value = DeviceConnectState.connecting;
        break;
      case CameraConnectState.logging:
        deviceModel.connectState.value = DeviceConnectState.logging;
        break;
      case CameraConnectState.connected:
        deviceModel.connectState.value = DeviceConnectState.connected;
        break;
      case CameraConnectState.timeout:
        deviceModel.connectState.value = DeviceConnectState.timeout;
        break;
      case CameraConnectState.disconnect:
        deviceModel.connectState.value = DeviceConnectState.disconnect;
        break;
      case CameraConnectState.password:
        deviceModel.connectState.value = DeviceConnectState.password;
        break;
      case CameraConnectState.maxUser:
        deviceModel.connectState.value = DeviceConnectState.maxUser;
        break;
      case CameraConnectState.offline:
        deviceModel.connectState.value = DeviceConnectState.offline;
        break;
      case CameraConnectState.illegal:
        deviceModel.connectState.value = DeviceConnectState.illegal;
        break;
      case CameraConnectState.none:
        deviceModel.connectState.value = DeviceConnectState.none;
        break;
    }
  }

  void statusListener(P2PBasisDevice device, StatusResult? result) {
    if (result == null) return;
    print("device status changed -----support_PeopleDetection:"
        "--${result.support_PeopleDetection}--"
        "---sirenStatus--${result.sirenStatus}--"
        "--移动侦测开关-alarmStatus--${result.alarm_status}--"
        "--是否支持人形侦测-support_humanDetect--${result.support_humanDetect}--"
        "--低功耗（可充电后待机使用）-isSupportLowPower--${result.support_low_power}--"
        "-----preset_cruise_status_v-------${result.preset_cruise_status_v}"
        "-----preset_cruise_curpos-------${result.preset_cruise_curpos}"
        "result.batteryRate--${result.batteryRate}"
        "-----preset_cruise_status_h-------${result.preset_cruise_status_h}");
    if (result.batteryRate != null) {
      DeviceManager.getInstance().getDeviceModel()!.batteryRate.value =
          int.tryParse(result.batteryRate ?? "0") ?? 0;
    }

    if (result.support_humanDetect != null) {
      DeviceManager.getInstance().getDeviceModel()!.supportHumanDetect.value =
          int.tryParse(result.support_humanDetect ?? "0") ?? 0;
    }

    if (result.hardwareTestFunc != null) {
      DeviceManager.getInstance()
          .setHardwareTestFunc(device.id, result.hardwareTestFunc!);
      int supportMode = int.tryParse(result.hardwareTestFunc ?? "") ?? 0;
      if (DeviceManager.getInstance().getDeviceModel() != null) {
        if (supportMode & 0x02 != 0) {
          DeviceManager.getInstance().getDeviceModel()!.alarmType.value = 0;
          print("----alarmType  0----支持人形侦测（低功耗）------");
        } else {
          DeviceManager.getInstance().getDeviceModel()!.alarmType.value = 1;
          print("----alarmType  1----支持移动侦测（长电）------");
        }

        ///是否支持白光灯
        if (supportMode & 0x4 != 0) {
          DeviceManager.getInstance().getDeviceModel()!.haveWhiteLight.value =
              true;
        }

        ///是否支持红蓝灯单独开关
        if (supportMode & 0x200 != 0) {
          DeviceManager.getInstance().getDeviceModel()!.haveRedBlueLight.value =
              true;
        }
      }
    }

    //智能电量
    if (result.support_Smart_Electricity_Sleep != null) {
      DeviceManager.getInstance()
              .getDeviceModel()!
              .supportSmartElectricitySleep
              .value =
          int.tryParse(result.support_Smart_Electricity_Sleep ?? "0") ?? 0;
    }

    ///是否低功耗
    if (int.tryParse(result.support_low_power ?? "0") != 0) {
      /// support_low_power = 3，4，7，8 时，支持超强低功耗（充电后超长待机）
      DeviceManager.getInstance().getDeviceModel()!.isSupportLowPower.value =
          true;
      DeviceManager.getInstance().getDeviceModel()!.supportLowPower.value =
          int.tryParse(result.support_low_power ?? "0") ?? 0;

      int supportPower =
          DeviceManager.getInstance().getDeviceModel()!.supportLowPower.value;
      if (supportPower == 3 ||
          supportPower == 4 ||
          supportPower == 7 ||
          supportPower == 8) {
        DeviceManager.getInstance()
            .getDeviceModel()!
            .isSupportDeepLowPower
            .value = true;
      }
    } else {
      ///长电
      if (int.tryParse(result.support_humanDetect ?? "0")! > 0) {
        print("-----------supportAI---true---------");
        DeviceManager.getInstance().getDeviceModel()!.supportAI.value = 1;
      }
    }

    ///新的工作模式按位 [bit 0 -> 低功耗 bit 1 -> 持续工作 bit 2 ->超低功耗 bit 3 ->微功耗]
    if (result.support_new_low_power != null) {
      DeviceManager.getInstance().getDeviceModel()!.supportNewLowPower.value =
          int.tryParse(result.support_new_low_power ?? "0") ?? 0;
    }

    if (result.support_Pir_Distance_Adjust != null) {
      DeviceManager.getInstance()
          .getDeviceModel()!
          .supportPirDistanceAdjust
          .value = int.tryParse(result.support_Pir_Distance_Adjust!) ?? 0;
    }

    //TF时间轴
    if (result.support_time_line != null) {
      DeviceManager.getInstance().deviceModel!.supportTimeLine.value =
          int.tryParse(result.support_time_line ?? "0") ?? 0;
    }

    if (result.support_mutil_sensor_stream != null) {
      int sensor = int.tryParse(result.support_mutil_sensor_stream ?? "0") ?? 0;
      print("------sensor-----$sensor---------");
      if (sensor == 1 || sensor == 2) {
        //双目
        sensor = 1;
      }
      if (result.splitScreen != null) {
        int splitScreen = int.tryParse(result.splitScreen ?? "0") ?? 0;
        print("------result.splitScreen-----${result.splitScreen}---------");
        print("------sensor-----3---------");
        sensor = 3;
        DeviceManager.getInstance().deviceModel?.splitScreen.value =
            splitScreen;
      }
      DeviceManager.getInstance().deviceModel?.supportMutilSensorStream.value =
          sensor;
    }

    ///警笛状态 1开，0 关
    DeviceManager.getInstance().setSirenState(result.sirenStatus == "1");

    ///报警开关 1开，0 关
    DeviceManager.getInstance().setAlarmStatus(result.alarm_status == "1");

    ///电量
    DeviceManager.getInstance().setBatteryRate(result.batteryRate ?? "100");

    /// 设备是否支持人形检测
    if (result.support_PeopleDetection != null) {
      DeviceManager.getInstance().setIsSupportDetect(
          int.tryParse(result.support_PeopleDetection!)! > 0,
          DeviceManager.getInstance().mDevice!.id);
    }

    if (int.tryParse(result.support_led_hidden_mode ?? "") != null &&
        int.tryParse(result.support_led_hidden_mode ?? "") != 0) {
      DeviceManager.getInstance().deviceModel?.isSupportledLight.value = true;
    }

    if (result.support_WhiteLed_Ctrl != null) {
      print(
          "-----白光灯--support_WhiteLed_Ctrl---${result.support_WhiteLed_Ctrl}");
    }

    if (result.support_manual_light != null) {
      ///是否支持手动开关白光灯
      DeviceManager.getInstance().deviceModel?.support_manual_light.value =
          result.support_manual_light!;
      print("-----白光灯--support_manual_light---${result.support_manual_light}");
    }

    ///pixel 像素
    if (result.pixel != null) {
      DeviceManager.getInstance().deviceModel?.pixel.value =
          int.tryParse(result.pixel!) ?? 0;
    }

    ///是否支持像素切换
    if (result.support_pixel_shift != null) {
      DeviceManager.getInstance().deviceModel?.support_pixel_shift.value =
          result.support_pixel_shift!;
    }

    ///是否支持双目
    if (result.support_binocular != null) {
      DeviceManager.getInstance().deviceModel?.supportBinocular.value =
          result.support_binocular == "1" ? true : false;
    }

    ///支持AI
    if (result.support_mode_AiDetect != null) {
      print(
          "--------support_mode_AiDetect-------${result.support_mode_AiDetect}-----------------");
      DeviceManager.getInstance().deviceModel?.aiDetectMode.value =
          int.tryParse(result.support_mode_AiDetect ?? "0") ?? 0;
    }

    if (result.support_pininpic != null) {
      DeviceManager.getInstance().deviceModel?.supportPinInPic.value =
          int.parse(result.support_pininpic ?? "0");
    }

    if (result.support_privacy_pos != null) {
      print(
          "-----support_privacy_pos-------${result.support_privacy_pos}--------");
      DeviceManager.getInstance().deviceModel?.support_privacy_pos.value =
          int.tryParse(result.support_privacy_pos ?? "0") ?? 0;
    }

    //人形框定
    if (result.support_humanoidFrame != null) {
      print(
          "-----support_humanoidFrame-------${result.support_humanoidFrame}--------");
      DeviceManager.getInstance().deviceModel?.supportHumanoidFrame.value =
          int.tryParse(result.support_humanoidFrame ?? "0") ?? 0;
    }

    ///是否支持人形变倍跟踪
    if (result.support_humanoid_zoom != null) {
      DeviceManager.getInstance().deviceModel?.supportHumanoidZoom.value =
          int.tryParse(result.support_humanoid_zoom ?? "0") ?? 0;
    }

    ///是否支持看守卫
    if (result.support_ptz_guard != null) {
      DeviceManager.getInstance().deviceModel?.support_ptz_guard.value =
          int.tryParse(result.support_ptz_guard ?? "0") ?? 0;
    }

    ///固件版本
    if (result.sys_ver != null) {
      DeviceManager.getInstance().deviceModel?.currentSystemVer.value =
          result.sys_ver ?? "0";
    }

    ///看守卫设置位置信息
    if (result.preset_value != null) {
      if (DeviceManager.getInstance().deviceModel?.presetValue.value !=
          int.tryParse(result.preset_value ?? "0")) {
        DeviceManager.getInstance().deviceModel?.presetValue.value =
            int.tryParse(result.preset_value ?? "0") ?? 0;
        var list = DeviceManager.getInstance()
                .deviceModel
                ?.presetValue
                .value
                .toRadixString(2)
                .padLeft(16, '0')
                .substring(0, 5)
                .split('')
                .toList() ??
            [];
        print("---看守卫设置位置信息----${list.toString()}-------");
        DeviceManager.getInstance().deviceModel?.presetPositionList.value =
            list;
      }
    }

    ///自动录像模式
    if (result.support_auto_record_mode != null) {
      DeviceManager.getInstance().deviceModel?.supportAutoRecordMode.value =
          int.tryParse(result.support_auto_record_mode ?? '0') ?? 0;
    }

    ///智能侦测定时
    if (result.smartdetecttime != null) {
      DeviceManager.getInstance().deviceModel?.smartdetecttime.value =
          result.smartdetecttime ?? "0";
    }

    ///聚焦功能
    //support_focus=1，表示支持聚焦功能
    //support_focus=2，表示支持聚焦功能，且支持定点变倍
    if (result.support_focus != null) {
      DeviceManager.getInstance().deviceModel?.support_focus.value =
          int.tryParse(result.support_focus ?? "0") ?? 0;
    }

    ///多倍变焦和支持最大的变倍数
    if (result.MaxZoomMultiple != null) {
      DeviceManager.getInstance().deviceModel?.MaxZoomMultiple.value =
          int.tryParse(result.MaxZoomMultiple ?? "0") ?? 0;
    }

    ///当前变焦倍数
    if (result.CurZoomMultiple != null) {
      DeviceManager.getInstance().deviceModel?.CurZoomMultiple.value =
          int.tryParse(result.CurZoomMultiple ?? "1") ?? 1;
    }

    ///TF录像模式
    if (result.recordmod != null) {
      DeviceManager.getInstance().deviceModel?.recordmod.value =
          result.recordmod!;
    }
  }

  @override
  void dispose() {
    DeviceManager.getInstance()
        .mDevice
        ?.removeListener<StatusChanged>(statusListener);
    super.dispose();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
