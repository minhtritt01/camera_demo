import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';
import 'package:vsdk_example/play/play_state.dart';
import 'package:vsdk_example/settings_main/settings_main_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'dart:io';
import 'package:vsdk_example/utils/permission_handler/permission_handler.dart';
import 'package:vsdk_example/utils/permission_util.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:vsdk_example/utils/super_put_controller.dart';

import '../model/device_model.dart';

class SettingsMainLogic extends SuperPutController<SettingsMainState> {
  SettingsMainLogic() {
    value = SettingsMainState();
  }

  @override
  void onInit() {
    initData();
    super.onInit();
  }

  void initData() async {
    ///初始化白光灯开关状态
    await DeviceManager.getInstance().mDevice!.lightCommand?.getLightState();
    state?.lightOpen.value =
        DeviceManager.getInstance().mDevice!.lightCommand?.lightSwitch ?? false;

    ///初始化人形框定开关状态
    getHumanFrame();

    ///初始化人形追踪开关状态
    getHumanTrack();

    ///初始化画质
    int resolution = await DeviceManager.getInstance()
        .getResolutionValue(DeviceManager.getInstance().mDevice!.id);
    state?.resolution.value = _intToResolution(resolution);

    ///初始化夜视模式
    getNightMode();

    ///人形变倍跟踪
    getZoomTrack();

    ///红蓝灯
    if (DeviceManager.getInstance().deviceModel?.haveRedBlueLight.value ??
        false) {
      getRedBlueLight();
    }
  }

  ///对讲开关
  Future<bool> startStopTalk(PlayState playState) async {
    ///获取麦克风权限
    if (Platform.isIOS) {
      var status = await Permission.microphone.status;
      if (status != PermissionStatus.granted) {
        await [Permission.microphone].request();
      }
    }
    if (Platform.isAndroid) {
      if (await Permission.microphone.isUndetermined) {
        await [Permission.microphone].request();
      }
    }

    if (DeviceManager.getInstance().getDevice() == null) return false;
    if (DeviceManager.getInstance().getController() == null) return false;

    if (state == null) return false;
    var micBool = await checkMicroPhonePermission();
    if (micBool) {
      if (state?.voiceState.value == VoiceState.none ||
          state?.voiceState.value == VoiceState.stop) {
        print("voiceState:${state?.voiceState.value}");

        ///开启对话

        if (state?.siren.value ?? false) {
          ///关闭警笛
          bool bl = await DeviceManager.getInstance()
                  .getDevice()
                  ?.sirenCommand
                  ?.controlSiren(false) ??
              false;
        }
        print("voiceState:${state?.voiceState.value}");
        return await startTalk();
      } else if (state?.voiceState.value == VoiceState.play) {
        ///关闭对话
        return await stopTalk();
      } else {
        EasyLoading.showToast("麦克风权限未打开");
      }
    }
    return false;
  }

  ///开始对话
  Future<bool> startTalk() async {
    CameraDevice device = DeviceManager.getInstance().getDevice()!;
    AppPlayerController controller =
        DeviceManager.getInstance().getController()!;

    bool bothWaySupport = device.supportbothWay();
    if (controller.voiceStatus != VoiceStatus.PLAY && bothWaySupport) {
      await device.startSoundStream();
      await controller.startVoice();
    }
    await controller
        .setSoundTouch(SoundTouchType.values[state?.soundType.value ?? 0]);
    var g711 = device.supportG711();
    RecordEncoderType encoderType =
        g711 == true ? RecordEncoderType.G711 : RecordEncoderType.ADPCM;
    await controller.startRecord(encoderType: encoderType);
    print("voiceState:-------open---------------");
    state?.voiceState.value = VoiceState.play;
    return true;
  }

  ///结束对话
  Future<bool> stopTalk() async {
    CameraDevice device = DeviceManager.getInstance().getDevice()!;
    AppPlayerController controller =
        DeviceManager.getInstance().getController()!;

    await controller.stopRecord();
    bool autoVoice = await DeviceManager.getInstance().getMonitorState();
    bool bothWaySupport = device.supportbothWay();
    if (bothWaySupport) {
      if (autoVoice) {
        //发送cgi 指令
        await device.startSoundStream();
        //调用原生方法开启声音
        await controller.startVoice();
      } else {
        //发送cgi 指令
        await device.stopSoundStream();
        //调用原生方法开启声音
        await controller.stopVoice();
      }
      print("voiceState:-------close---------------");
      state?.voiceState.value = VoiceState.stop;
      return true;
    } else {
      print("voiceState:-------error---------------");
      state?.voiceState.value = VoiceState.error;
    }
    return false;
  }

  ///拍照
  void getSnapShot() async {
    //todo 当开启物理遮挡时功能不可用，应做判断处理

    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status != PermissionStatus.granted) {
        await [Permission.photos].request();
      }
    }
    var photoGranted = await checkPhotoPermissionGranted();
    if (!photoGranted) return;
    var result = await screenshotPlayer();
    if (result) {
      EasyLoading.showToast("文件已保存到App“我的”-“相册”中");
    }
  }

  ///截图拍照
  Future<bool> screenshotPlayer() async {
    var dir = await getApplicationDocumentsDirectory();
    AppPlayerController controller = DeviceManager.getInstance().controller!;

    /// if device pixel >= 500 imageSize = 0; 这里默认2960x1665
    String imageSize = "2960x1665";

    File? f0 = await playerScreenshot(dir, controller, imageSize);

    ///二目或假三目
    File? f1 = await subPlayerScreenshot(controller, dir, imageSize);

    ///三目
    File? f2 = await sub2PlayerScreenshot(controller, dir, imageSize);
    if (controller.sub_controller == null &&
        controller.sub2_controller == null) {
      return f0 != null;
    }
    if (controller.sub_controller != null &&
        controller.sub2_controller == null) {
      return f0 != null && f1 != null;
    }
    if (controller.sub_controller != null &&
        controller.sub2_controller != null) {
      return f0 != null && f1 != null && f2 != null;
    }
    return false;
  }

  Future<File?> playerScreenshot(
      Directory dir, AppPlayerController controller, String imageSize,
      {bool isPreset = false}) async {
    File file = File(
        "${dir.path}/image/${DateTime.now().toUtc().millisecondsSinceEpoch}.jpg");
    file.parent.createSync(recursive: true);
    var result = await controller.screenshot(file.path, imageSize: imageSize);
    if (result == true) {
      ///截图同步保存到系统相册
      if (!isPreset) {
        await ImageGallerySaver.saveFile(file.path,
            isReturnPathOfIOS: Platform.isIOS);
      }

      File smallFile = File("${file.path}_smail");
      if (smallFile.existsSync()) {
        //对小图进行压缩
        String targetPath = "${dir.path}/image/tempScreenShort.jpg";
        File tempFile = File(targetPath);
        await compressFile(tempFile, smallFile, targetPath);
        if (smallFile.existsSync()) {
          return smallFile;
        }
      }
      return file;
    }
    return null;
  }

  Future<File?> subPlayerScreenshot(
      AppPlayerController controller, Directory dir, String imageSize) async {
    if (controller.sub_controller != null) {
      File file = File(
          "${dir.path}/image/${DateTime.now().toUtc().millisecondsSinceEpoch}.jpg");
      file.parent.createSync(recursive: true);
      var result = await controller.sub_controller!
          .screenshot(file.path, imageSize: imageSize);
      if (result == true) {
        ///截图同步保存到系统相册
        await ImageGallerySaver.saveFile(file.path,
            isReturnPathOfIOS: Platform.isIOS);

        File smallFile = File("${file.path}_smail");
        if (smallFile.existsSync()) {
          //对小图进行压缩
          String targetPath = "${dir.path}/image/tempScreenShort1.jpg";
          File tempFile = File(targetPath);
          await compressFile(tempFile, smallFile, targetPath);
          if (smallFile.existsSync()) {
            return smallFile;
          }
        }
        return file;
      }
    }
    return null;
  }

  Future<File?> sub2PlayerScreenshot(
      AppPlayerController controller, Directory dir, String imageSize) async {
    if (controller.sub2_controller != null) {
      File file = File(
          "${dir.path}/image/${DateTime.now().toUtc().millisecondsSinceEpoch}.jpg");
      file.parent.createSync(recursive: true);
      var result = await controller.sub_controller!
          .screenshot(file.path, imageSize: imageSize);
      if (result == true) {
        ///截图同步保存到系统相册
        await ImageGallerySaver.saveFile(file.path,
            isReturnPathOfIOS: Platform.isIOS);

        File smallFile = File("${file.path}_smail");
        if (smallFile.existsSync()) {
          //对小图进行压缩
          String targetPath = "${dir.path}/image/tempScreenShort2.jpg";
          File tempFile = File(targetPath);
          await compressFile(tempFile, smallFile, targetPath);
          if (smallFile.existsSync()) {
            return smallFile;
          }
        }
        return file;
      }
    }
    return null;
  }

  Future<void> compressFile(
      File tempFile, File smallFile, String targetPath) async {
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
      tempFile.createSync();
    } else {
      tempFile.createSync();
    }

    await FlutterImageCompress.compressAndGetFile(
      smallFile.path,
      targetPath,
      quality: 50,
      rotate: 0,
      minWidth: 320,
      minHeight: 180,
    );

    if (tempFile.existsSync()) {
      smallFile.deleteSync();
      tempFile.renameSync(smallFile.path);
    }
  }

  ///录像
  void startOrStopRecord(PlayState playState) async {
    //todo 当开启物理遮挡时功能不可用，应做判断处理

    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status != PermissionStatus.granted) {
        await [Permission.photos].request();
      }
    }
    var photoGranted = await checkPhotoPermissionGranted();
    if (!photoGranted) return;

    if (state?.recordState.value == RecordState.stop ||
        state?.recordState.value == RecordState.none) {
      playState.recordProgress.value = 0;
      bool bl = await startPlayerRecord(playState);
      if (bl == true) {
        state?.recordState.value = RecordState.recording;
        playState.recordStartSec = playState.progress;
        playState.videoRecord.value = true;
      }
    } else {
      if (playState.recordProgress.value < 5) {
        EasyLoading.showToast("录像时间太短");
        return;
      }
      var file = await stopPlayerRecord(playState);
      state?.recordState.value = RecordState.stop;
      playState.videoRecord.value = false;
      if (file != null) {
        EasyLoading.showToast("视频已保存到相册！");
      } else {
        EasyLoading.showToast("出错了，录制失败！");
      }
    }
  }

  ///开始录制
  Future<bool> startPlayerRecord(PlayState playState) async {
    ///视频暂停或关闭状态，无法录制
    if (playState.videoStatus.value != VideoStatus.PLAY) return false;

    ///视频已经在录制状态
    if (state?.recordState.value == RecordState.recording) return true;

    ///创建保存视频文件的路径
    Directory dir = await getApplicationDocumentsDirectory();
    String recordFilePath =
        "${dir.path}/admin/video/${DateTime.now().toUtc().millisecondsSinceEpoch}_1920x1080";
    playState.recordFile = File(recordFilePath);
    playState.recordFile.parent.createSync(recursive: true);
    File jpegFile = File("${playState.recordFile.path}.jpg");

    ///截图（开始录制的第一帧）
    AppPlayerController controller = DeviceManager.getInstance().controller!;

    var result = await controller.screenshot(jpegFile.path);
    if (result) {
      File smallFile = File("${jpegFile.path}_smail");
      if (smallFile.existsSync()) {
        //对小图进行压缩
        String targetPath = "${dir.path}/admin/video/tempScreenShort.jpg";
        File tempFile = File(targetPath);
        await compressFile(tempFile, smallFile, targetPath);
      }
    }

    return result;
  }

  ///停止录制
  Future<File?> stopPlayerRecord(PlayState playState) async {
    /// 没有开始录制，直接返回
    if (state?.recordState.value != RecordState.recording) return null;

    state?.recordState.value = RecordState.stop;
    playState.recordProgress.value = 0;

    ///录制开始时间与视频当前进度时间相同，录制失败
    if (playState.recordStartSec == playState.progress) {
      File("${playState.recordFile.path}.jpg").deleteSync();
      return null;
    }
    AppPlayerController controller = DeviceManager.getInstance().controller!;

    ///视频存放路径，开始录制时间，结束录制时的视频时间
    var ret = await controller.save(playState.recordFile.path,
        start: playState.recordStartSec, end: playState.progress);
    if (ret < 0) {
      File("${playState.recordFile.path}.jpg").deleteSync();
      return null;
    }

    ///单目
    if (ret == 0) {
      ///录像视频同步保存到系统相册
      var mp4File = File("${playState.recordFile.path}.mp4");

      ///保存录制的视频
      bool bl = await AppPlayerController.saveMP4(
          playState.recordFile.path, mp4File.path);
      if (bl != false) {
        await ImageGallerySaver.saveFile(mp4File.path);
      }
    }

    ///双目
    if (ret == 1) {
      File("${playState.recordFile.path}.jpg")
          .renameSync("${playState.recordFile.path}_sub.jpg");

      var mp4FileSub = File("${playState.recordFile.path}_sub_sub.mp4");
      var bl = await AppPlayerController.saveMP4(
          "${playState.recordFile.path}_sub", mp4FileSub.path,
          enableSub: 1);
      print('==>>结束录像_SUB:${bl}');
      if (bl != false) {
        print('==>>mp4FileSub.path:${mp4FileSub.path}');
        var result = await ImageGallerySaver.saveFile(mp4FileSub.path);
        print('==>>保存到手机子播放器:${result}');
      }

      var mp4File = File("${playState.recordFile.path}_sub.mp4");
      bl = await AppPlayerController.saveMP4(
          "${playState.recordFile.path}_sub", mp4File.path);
      print('==>>结束录像_MAIN:${bl}');
      if (bl != false) {
        print('==>>mp4File.path:${mp4File.path}');

        var result = await ImageGallerySaver.saveFile(mp4File.path);
        print('==>>保存到手机:${result}');
      }
    }

    ///三目
    if (ret == 2) {
      File("${playState.recordFile.path}.jpg")
          .renameSync("${playState.recordFile.path}_sub2.jpg");

      var mp4FileSub = File("${playState.recordFile.path}_sub2_sub1.mp4");
      var bl = await AppPlayerController.saveMP4(
          "${playState.recordFile.path}_sub2", mp4FileSub.path,
          enableSub: 1);
      print('==>>结束录像_SUB1:${bl}');
      if (bl != false) {
        print('==>>mp4FileSub.path:${mp4FileSub.path}');
        var result = await ImageGallerySaver.saveFile(mp4FileSub.path);
        print('==>>保存到手机子播放器:${result}');
      }

      var mp4FileSub2 = File("${playState.recordFile.path}_sub2_sub2.mp4");
      var bl2 = await AppPlayerController.saveMP4(
          "${playState.recordFile.path}_sub2", mp4FileSub2.path,
          enableSub: 2);
      print('==>>结束录像_SUB2:${bl}');
      if (bl2 != false) {
        print('==>>mp4FileSub.path:${mp4FileSub2.path}');
        var result = await ImageGallerySaver.saveFile(mp4FileSub2.path);
        print('==>>保存到手机子播放器:${result}');
      }

      var mp4File = File("${playState.recordFile.path}_sub2.mp4");
      bl = await AppPlayerController.saveMP4(
          "${playState.recordFile.path}_sub2", mp4File.path);
      print('==>>结束录像_MAIN:${bl}');
      if (bl != false) {
        print('==>>mp4File.path:${mp4File.path}');

        var result = await ImageGallerySaver.saveFile(mp4File.path);
        print('==>>保存到手机:${result}');
      }
    }

    return playState.recordFile;
  }

  ///警笛开关，每次打开播放10S ，10S后自动关闭
  void onClickSiren(PlayState playState) async {
    // 如果设备电量过低<20%, 该功能不可用
    String battery = await DeviceManager.getInstance().getBatteryRate();
    print('==>>battery:$battery');
    if (int.parse(battery) < 20) {
      EasyLoading.showToast("电量过低，该功能不可用!");
      return;
    }

    ///已经打开警笛则关闭
    // bool siren = await DeviceManager.getInstance().getSirenState();
    if (state?.siren.value ?? false) {
      /// false 关闭警笛
      sirenCommand(false, playState);
      print('==>>sirenCommand:false');
    } else {
      ///打开警笛时如果对讲已打开要先关闭对讲
      if (state?.voiceState.value == VoiceState.play) {
        bool isStop = await stopTalk();
        if (isStop) {
          ///true 打开警笛
          sirenCommand(true, playState);
          // 备注： 关闭对话后开启警笛可能无效
          print('==>>sirenCommand:true voice is stop');
        }
      } else {
        ///true 打开警笛
        sirenCommand(true, playState);
        print('==>>sirenCommand:true');
      }
    }
  }

  void sirenCommand(bool isStart, PlayState sta) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.sirenCommand
            ?.controlSiren(isStart) ??
        false;

    if (bl) state?.siren.value = isStart;
  }

  ///白光灯开关
  Future<bool> openOrCloseLight() async {
    //todo 开启物理遮挡或电量不足20% 该功能不可用

    String battery = await DeviceManager.getInstance().getBatteryRate();
    print('==>>battery:$battery');
    if (int.parse(battery) < 20) {
      EasyLoading.showToast("电量过低，该功能不可用!");
      return false;
    }
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    if (device.lightCommand == null) return false;
    bool curLight = device.lightCommand!.lightSwitch ?? false;
    bool? bl = await device.lightCommand!.controlLight(!curLight);
    if (bl) {
      state?.lightOpen.value = !curLight;
      return true;
    }
    return false;
  }

  Future<bool> openOrClosePeopleFrame(PlayState sta) async {
    //todo 开启物理遮挡 该功能不可用
    /// >0 支持人形检测
    bool isEnable = !(state?.peopleFrameOpen.value ?? false);
    bool isSupport = await DeviceManager.getInstance()
        .getIsSupportDetect(DeviceManager.getInstance().mDevice!.id);
    if (isSupport) {
      ///关闭人形框定则先关闭人形检测，否则打开人形检测
      bool isSuc = await DeviceManager.getInstance()
              .mDevice
              ?.setHuanoidDetection(isEnable ? 1 : 0) ??
          false;
      print("人形检测----------------isSuc:$isSuc");
    }

    ///人形框定
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.humanFraming
            ?.setHumanFraming(isEnable ? 1 : 0) ??
        false;
    if (bl) {
      state?.peopleFrameOpen.value = isEnable;
      return true;
    }
    return false;
  }

  ///初始化人形框定功能的状态
  Future<bool> getHumanFrame() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .humanFraming
            ?.getHumanFraming() ??
        false;
    if (bl) {
      state?.peopleFrameOpen.value = (DeviceManager.getInstance()
                  .mDevice!
                  .humanFraming
                  ?.humanFrameEnable ??
              0) >
          0;
      return true;
    }
    return false;
  }

  ///设置人形追踪
  void setHumanTrack(int enable) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.humanTracking
            ?.setHumanTracking(enable) ??
        false;
    if (bl) {
      print("人形追踪设置成功");
      state?.humanTrackOpen.value = enable == 1;
    }
  }

  ///获取人形追踪状态
  void getHumanTrack() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.humanTracking
            ?.getHumanTracking() ??
        false;
    if (bl) {
      print(
          "---getHumanTrack-----enable:-${DeviceManager.getInstance().mDevice?.humanTracking?.humanTrackingEnable}-----------");
      state?.humanTrackOpen.value = (DeviceManager.getInstance()
                  .mDevice
                  ?.humanTracking
                  ?.humanTrackingEnable ??
              0) >
          0;
    }
  }

  ///设置画质
  setResolutionValue(VideoResolution resolution) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.changeResolution(resolution) ??
        false;
    if (bl) {
      print("-------setResolutionValue----success-----");
      state?.resolution.value = resolution;
      int value = _resolutionToInt(resolution);
      DeviceManager.getInstance()
          .setResolutionValue(value, DeviceManager.getInstance().mDevice!.id);
    }
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

  int _resolutionToInt(VideoResolution value) {
    switch (value) {
      case VideoResolution.none:
      case VideoResolution.unknown:
      case VideoResolution.general:
        return 2;
      case VideoResolution.high:
        return 1;
      case VideoResolution.low:
        return 4;
      case VideoResolution.superHD:
        return 100;
    }
  }

  ///设置黑白夜视0，全彩夜视1，智能夜视2，需同时把模式设置为黑白
  setNightMode(int value) async {
    bool result1 = await fullColorNightMode(value);
    bool result2 = await nightMode(1); //设为黑白
    if (result1 && result2) {
      state?.currentNightMode.value = value;
    }
  }

  ///设置星光夜视
  setNightMode2() async {
    bool result1 = await fullColorNightMode(0); //先把模式设为黑白
    bool result2 = await nightMode(0); //再切换为星光夜视
    if (result1 && result2) {
      state?.currentNightMode.value = 3;
    }
  }

  ///设置夜视模式,0 黑白模式，1全彩夜视，2智能夜视
  Future<bool> fullColorNightMode(int value) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.fullColorChangeNightVision(value) ??
        false;

    if (bl) {
      print("-------fullColorNightMode----success-----");
    }
    return bl;
  }

  /// 1 黑白夜视，0 星光夜视
  Future<bool> nightMode(int value) async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.changeNightVision(value) ??
            false;
    if (bl) {
      print("-------nightMode----success-----");
    }
    return bl;
  }

  getNightMode() async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.getCameraParams() ?? false;
    if (bl) {
      print("----getNightMode---success----");
      int mode = DeviceManager.getInstance().mDevice?.night_vision_mode ?? 0;
      switch (mode) {
        case 0:
          if (DeviceManager.getInstance().mDevice?.ircut == 0) {
            state?.currentNightMode.value = 3;

            ///星光夜视
          } else {
            state?.currentNightMode.value = 0;

            ///黑白夜视
          }
          break;
        case 1:
          state?.currentNightMode.value = 1;

          ///全彩夜视
          break;
        case 2:
          state?.currentNightMode.value = 2;

          ///智能夜视
          break;
      }
    }
  }

  ///控制摄像机上下左右调整
  void onJoystickClick(MotorDirection direction) async {
    bool result = false;
    switch (direction) {
      //往左
      case MotorDirection.startLeft:
        result = await DeviceManager.getInstance()
                .mDevice
                ?.motorCommand
                ?.startLeft(motorSpeed: 5) ??
            false;
        if (result) {
          //0.5秒后停止
          Future.delayed(Duration(milliseconds: 500), () async {
            await DeviceManager.getInstance().mDevice?.motorCommand?.stopLeft();
          });
        }
        break;
      //往右
      case MotorDirection.startRight:
        result = await DeviceManager.getInstance()
                .mDevice
                ?.motorCommand
                ?.startRight(motorSpeed: 5) ??
            false;
        if (result) {
          //0.5秒后停止
          Future.delayed(Duration(milliseconds: 500), () async {
            await DeviceManager.getInstance()
                .mDevice
                ?.motorCommand
                ?.stopRight();
          });
        }
        break;
      //往上
      case MotorDirection.startUp:
        result = await DeviceManager.getInstance()
                .mDevice
                ?.motorCommand
                ?.startUp(motorSpeed: 5) ??
            false;
        if (result) {
          //0.5秒后停止
          Future.delayed(Duration(milliseconds: 500), () async {
            await DeviceManager.getInstance().mDevice?.motorCommand?.stopUp();
          });
        }
        break;
      //往下
      case MotorDirection.startDown:
        result = await DeviceManager.getInstance()
                .mDevice
                ?.motorCommand
                ?.startDown(motorSpeed: 5) ??
            false;
        if (result) {
          //0.5秒后停止
          Future.delayed(Duration(milliseconds: 500), () async {
            await DeviceManager.getInstance().mDevice?.motorCommand?.stopDown();
          });
        }
        break;
    }
  }

  ///人形变倍跟踪
  void setZoomTrack(int enable) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.humanZoom
            ?.setHumanZoom(enable) ??
        false;
    if (bl) {
      print("人形变倍跟踪设置成功");
      state?.zoomTrackOpen.value = enable == 1;
    }
  }

  ///获取人形变倍跟踪开关状态
  void getZoomTrack() async {
    bool bl =
        await DeviceManager.getInstance().mDevice?.humanZoom?.getHumanZoom() ??
            false;
    if (bl) {
      DeviceManager.getInstance().deviceModel?.humanZoomStatus.value =
          DeviceManager.getInstance().mDevice?.humanZoom?.humanZoomEnable ?? 0;
      state?.zoomTrackOpen.value =
          (DeviceManager.getInstance().mDevice?.humanZoom?.humanZoomEnable ??
                  0) ==
              1;
    }
  }

  ///红蓝灯开关控制
  void redBlueLightSwitch(bool isOpen) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.redBlueLightCommand
            ?.controlRedBlueLightStatus(isOpen ? 1 : 0) ??
        false;
    if (bl) {
      state!.redBlueOpen.value = isOpen;
    }
  }

  ///获取红蓝灯开关状态
  void getRedBlueLight() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice
            ?.redBlueLightCommand
            ?.getRedBlueLightStatus() ??
        false;
    if (bl) {
      state!.redBlueOpen.value = DeviceManager.getInstance()
              .mDevice
              ?.redBlueLightCommand
              ?.redBlueSwitch ??
          false;
    }
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
