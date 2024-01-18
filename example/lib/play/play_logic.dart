import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';
import 'package:vsdk_example/play/play_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:vsdk_example/utils/super_put_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../model/device_model.dart';
import '../widget/scale_offset_gesture_detector.dart';

class PlayLogic extends SuperPutController<PlayState> {
  AppPlayerController? controller;
  LiveVideoSource? videoSource;
  ValueNotifier<ScaleOffset>? videoScaleNotifierFirst;
  ValueNotifier<ScaleOffset>? videoScaleNotifierSecond;
  double defaultValue = 1.0;

  PlayLogic() {
    value = PlayState();
  }

  @override
  void onInit() {
    init(DeviceManager.getInstance().mDevice!).then((data) {
      if (DeviceManager.getInstance().deviceModel!.supportPinInPic.value == 1 ||
          DeviceManager.getInstance()
                  .deviceModel!
                  .supportMutilSensorStream
                  .value ==
              1) {
        getLinkableEnable(); //获取联动开关状态
      }
    });
    videoScaleNotifierFirst = ValueNotifier(ScaleOffset());
    videoScaleNotifierSecond = ValueNotifier(ScaleOffset());

    state!.zoomValue.value =
        DeviceManager.getInstance().deviceModel!.CurZoomMultiple.value;
    super.onInit();
  }

  void addScaleOffset() {
    initScaleNotifier();
    defaultValue++;
    if (defaultValue > 5) {
      defaultValue = 5.0;
    }
    setScaleNotifier();
  }

  void setScaleNotifier() {
    if (state!.select.value == 1) {
      ///第一个枪机
      videoScaleNotifierFirst!.value.scale = defaultValue;
      videoScaleNotifierFirst!.notifyListeners();
    } else if (state!.select.value == 2) {
      ///第二个枪机
      videoScaleNotifierSecond!.value.scale = defaultValue;
      videoScaleNotifierSecond!.notifyListeners();
    }
  }

  void initScaleNotifier() {
    bool split =
        DeviceManager.getInstance().deviceModel?.splitScreen.value == 1;
    if (videoScaleNotifierFirst == null && state!.hasSubPlay.value != 0) {
      videoScaleNotifierFirst = ValueNotifier(ScaleOffset());
    }
    if (videoScaleNotifierSecond == null &&
        ((state!.hasSubPlay.value == 1 && split) ||
            state!.hasSubPlay.value == 2)) {
      videoScaleNotifierSecond = ValueNotifier(ScaleOffset());
    }
  }

  void reduceScaleOffset() {
    initScaleNotifier();
    defaultValue--;
    if (defaultValue < 1) {
      defaultValue = 1.0;
    }
    setScaleNotifier();
  }

  @override
  void onClose() {
    controller?.removeProgressChangeCallback(onProgress);
    controller?.dispose();
    if (state?.player2Controller != null) {
      state?.player2Controller?.stop();
      state?.player2Controller?.dispose();
    }
    if (state?.player3Controller != null) {
      state?.player3Controller?.stop();
      state?.player3Controller?.dispose();
    }
    videoScaleNotifierFirst!.dispose();
    videoScaleNotifierSecond!.dispose();
    super.onClose();
  }

  ///视频播放状态监听回调
  void playChange(userData, VideoStatus videoStatus, VoiceStatus voiceStatus,
      RecordStatus recordStatus, SoundTouchType touchType) {
    state?.playChange.value = state?.playChange.value ?? 0 + 1;
    state?.voiceStatus = voiceStatus;
    state?.recordStatus = recordStatus;
    state?.videoStatus.value = videoStatus;
    state?.videoStop.value = videoStatus == VideoStatus.STOP;
    state?.videoPause.value = videoStatus == VideoStatus.PAUSE;

    print(
        "videoStatus:$videoStatus voiceStatus:$voiceStatus recordStatus:$recordStatus touchType:$touchType");
  }

  ///视频信息监听回调
  void onProgress(dynamic userData, int totalSec, int playSec, int progress,
      int loadState, int velocity) async {
    print(
        "player currentSec:$playSec, totalSec:$totalSec, progress:$progress loadState:$loadState flow:$velocity)");

    if (velocity != state?.velocity.value) {
      state?.velocity.value = velocity;
    }

    ///保存视频时长
    if (totalSec >= 0) {
      state?.duration = totalSec;
    }

    ///视频播放时间，即当前播放进度
    if (playSec >= 0) {
      state?.progress = playSec;

      ///当前播放进度 - 开始录制时间 = 视频录制时间
      if (state?.videoRecord.value == true) {
        print("recordStatus recording ------------------");
        state?.recordProgress.value = playSec - state!.recordStartSec;
      }
    }
    if (playSec == 1) {
      Directory directory =
          await DeviceManager.getInstance().mDevice!.getDeviceDirectory();
      String filePath =
          '${directory.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
      File(filePath).createSync(recursive: true);
      bool bl = await controller!.screenshot(filePath);
      if (bl == true) {
        ///d.snapshotCacheFile = File(filePath);
        state?.snapshotFile.value = File(filePath);
      }
    }
    if (loadState != 0 && playSec == totalSec) {
      stopPlay();
    }
  }

  Future<void> init(CameraDevice device) async {
    if (DeviceManager.getInstance().deviceModel!.connectState.value ==
            DeviceConnectState.disconnect ||
        DeviceManager.getInstance().deviceModel!.connectState.value ==
            DeviceConnectState.none ||
        DeviceManager.getInstance().deviceModel!.connectState.value ==
            DeviceConnectState.timeout) {
      print("-----------reconnect-------------");

      ///重新连接
      CameraConnectState connectState =
          await DeviceManager.getInstance().mDevice!.connect();
      if (connectState == CameraConnectState.disconnect ||
          connectState == CameraConnectState.none ||
          connectState == CameraConnectState.timeout) {
        return;
      }
    }
    controller = AppPlayerController(changeCallback: playChange);
    state?.playerController = controller;

    controller!.setCreatedCallback((data) async {
      print("--------------setCreatedCallback---------------");
      DeviceManager.getInstance().setController(controller!);

      ///判断是否要加载多目播放器
      await setSubPlayer();

      await start(device);
      return;
    });
    if (controller!.isCreated) {
      await controller!.start();
    } else {
      await controller!.create();
      await controller!.start();
      print("--------------controller.create---------------");
    }

    controller!.addProgressChangeCallback(onProgress);
  }

  Future<void> start(CameraDevice device) async {
    if (controller == null) return;
    videoSource = LiveVideoSource(device.clientPtr!);
    await controller!.setVideoSource(videoSource!);
    int resolution =
        await DeviceManager.getInstance().getResolutionValue(device.id);
    var live =
        await device.startStream(resolution: _intToResolution(resolution));
    print("-------live--$live-------");
    await controller!.stop();
    await controller!.start();
    device.keepAlive(time: 10);
    // await controller.start();
    state?.videoStop.value = false;
    state?.videoPause.value = false;
  }

  ///设置多目播放器
  Future<bool> setSubPlayer() async {
    bool bl = false;

    ///创建多目设备的播放控制器
    int sensor = DeviceManager.getInstance()
            .deviceModel
            ?.supportMutilSensorStream
            .value ??
        0;

    int splitScreen =
        DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;

    ///splitScreen=1 代表二目分屏为三目，为假三目。只有splitScreen !=1 时才是真三目
    if (sensor == 3 && splitScreen != 1) {
      bl = await enableSubPlayer(sub2Player: true);
      print("-----------3-------enableSubPlayer---$bl---------------");
    } else if (sensor == 1 || (sensor == 3 && splitScreen == 1)) {
      ///二目或者假三目
      bl = await enableSubPlayer();
      print("-----------2-------enableSubPlayer---$bl---------------");
    }
    return bl;
  }

  VideoResolution _intToResolution(int value) {
    if (value == 4) {
      return VideoResolution.low;
    } else if (value == 2) {
      return VideoResolution.general;
    } else if (value == 1) {
      return VideoResolution.high;
    } else if (value == 100) {
      return VideoResolution.superHD;
    }
    return VideoResolution.general;
  }

  void stopPlay() async {
    if (controller != null && controller!.isCreated) {
      await controller!.stop();
    }
    state?.videoStop.value = true;
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  void startVideo() async {
    if (controller == null) return;
    await controller!.setVideoSource(LiveVideoSource(videoSource!.clientPtr));
    await DeviceManager.getInstance()
        .mDevice
        ?.startStream(resolution: VideoResolution.general);
    controller!.start();
    state?.videoStop.value = false;
  }

  ///创建多目播放器
  Future<bool> enableSubPlayer({bool sub2Player = false}) async {
    if (controller!.sub_controller != null) return true;
    var subController = AppPlayerController();

    var result = await subController.create();
    if (result != true) {
      print("-------------subController.create---false---------------");
      return false;
    }
    result = await subController.setVideoSource(SubPlayerSource());
    if (result != true) {
      print("-------------subController.setVideoSource---false---------------");
      return false;
    }
    await subController.start();
    result = await controller!.enableSubPlayer(subController);
    if (result != true) {
      print("-------------enableSubPlayer---false---------------");
      return false;
    }
    state?.player2Controller = subController;

    //sub2Player
    if (sub2Player == true) {
      if (controller!.sub2_controller != null) return true;
      var sub2Controller = AppPlayerController();
      var result = await sub2Controller.create();
      if (result != true) {
        print("-------------sub2Controller.create---false---------------");
        return false;
      }
      result = await sub2Controller.setVideoSource(SubPlayerSource());
      if (result != true) {
        print(
            "-------------sub2Controller.setVideoSource---false---------------");
        return false;
      }
      await sub2Controller.start();
      result = await controller!.enableSub2Player(sub2Controller);
      if (result != true) {
        print("-------------enableSub2Player---false---------------");
        return false;
      }
      state?.player3Controller = sub2Controller;
    }
    if (sub2Player) {
      state?.hasSubPlay.value = 2;
    } else {
      state?.hasSubPlay.value = 1;
    }
    return true;
  }

  ///二目联动
  linkable(int xPercent, int yPercent) async {
    if (DeviceManager.getInstance().deviceModel!.isSupportLowPower.value &&
        DeviceManager.getInstance().deviceModel!.batteryRate.value < 20) {
      EasyLoading.showToast("电量不足，云台无法使用");
      return;
    }
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .qiangQiuCommand
            ?.controlFocalPoint(xPercent, yPercent) ??
        false;
    if (bl) {
      print("------------------");
    }
  }

  ///获取联动开关状态
  getLinkableEnable() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .qiangQiuCommand
            ?.getLinkageEnable() ??
        false;
    if (bl) {
      state!.isLinkableOpen.value = DeviceManager.getInstance()
              .mDevice!
              .qiangQiuCommand
              ?.gblinkage_enable ==
          1;
    }
  }

  ///设置光学变焦
  setZoom(int scale) async {
    bool bl = false;
    if (DeviceManager.getInstance().deviceModel!.MaxZoomMultiple.value > 0) {
      //新版本固件
      bl = await DeviceManager.getInstance()
              .mDevice!
              .multipleZoomCommand
              ?.multipleZoomCommand(scale) ??
          false;
    } else {
      //老版本固件
      bl = await DeviceManager.getInstance()
              .mDevice!
              .multipleZoomCommand
              ?.multipleZoom4XCommand(scale) ??
          false;
    }
    if (bl) {
      state!.zoomValue.value = scale;
      print("-----setZoom----true--------");
    }
  }
}
