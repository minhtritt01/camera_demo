import 'dart:io';
import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/card_command.dart';
import 'package:vsdk_example/tf_play/tf_play_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import '../model/record_file_model.dart';
import '../utils/number_util.dart';
import '../utils/super_put_controller.dart';
import '../widget/tf_scroll_view/tf_scroll_logic.dart';
import '../widget/tf_time_slider/tf_time_slider_logic.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TFPlayLogic extends SuperPutController<TFPlayState>
    with TFTimeSliderLogic, TFScrollLogic, SingleGetTickerProviderMixin {
  late AppPlayerController controller;
  int initSec = 0;

  TFPlayLogic() {
    value = TFPlayState();
    initPut();
  }

  @override
  void onInit() {
    createPlayer();
    initTFCardStatus();

    if (DeviceManager.getInstance().deviceModel!.supportTimeLine.value == 0) {
      ///TF不支持时间轴播放模式
      state!.isSupportTimeLine.value = false;
    }

    ///获取TF卡录制的视频数据
    getRecordFile(DeviceManager.getInstance().mDevice!.id, false)
        .then((fileList) {
      if (fileList.isEmpty) return;
      state!.recordFileModels.value = fileList;
      print("------获取到了数据-----${fileList.length}");

      ///列表播放模式
      if (!state!.isSupportTimeLine.value) {
        ///默认播放第一个视频
        RecordFileModel model = state!.recordFileModels.value[0];
        state!.playModel.value = model;
        startVideo();
      } else {
        ///时间轴模式
        // getTFRecordModeTimes(fileList);
        initAnimationController();
        dealTFScrollRecordFile(fileList);
      }
    });

    super.onInit();
  }

  List<RecordFileModel> recordFiles = [];

  void initTFCardStatus() async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    bool bl = await device.getRecordParam();
    if (bl) {
      String sdStatus = device.recordResult.record_sd_status;
      String sdFree = device.recordResult.sdfree;
      String sdTotal = device.recordResult.sdtotal;
      print(
          "---sdStatus-$sdStatus----sdFree-$sdFree-----sdTotal-$sdTotal---------");
    }
  }

  ///创建播放器
  void createPlayer() {
    controller = AppPlayerController();
    controller.setStateChangeCallback(onStateChange);
    controller.setCreatedCallback(onCreated);
    controller.addProgressChangeCallback(onProgress);
    state?.tfPlayer = controller;
    setSubPlayer();
  }

  void onStateChange(
      dynamic userData,
      VideoStatus videoStatus,
      VoiceStatus voiceStatus,
      RecordStatus recordStatus,
      SoundTouchType touchType) {
    ///视频播放状态回调
    state?.videoStatus(videoStatus);
    state?.voiceStatus = voiceStatus;
  }

  void onCreated(dynamic userData) {
    print("onCreated");
  }

  ///视频信息监听回调
  void onProgress(dynamic userData, int totalSec, int playSec, int progress,
      int loadState, int velocity) async {
    state?.duration = totalSec;
    state?.playDuration = playSec;
    print(
        "player currentSec:$playSec, totalSec:$totalSec, progress:$progress loadState:$loadState flow:$velocity)");
  }

  ///demo只拿了10条数据
  Future<List<RecordFileModel>> getRecordFile(
    String deviceId,
    bool loadMore, {
    bool loadAll = false,
    String? dateName,
    bool supportRecordTypeSeach = false,
  }) async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    List<RecordFile> files = device.recordFileList;

    ///录制视频类型搜索暂未实现
    if (supportRecordTypeSeach == true) {
      if (dateName != null) {
        files = await device.getRecordFile(
            supportRecordTypeSeach: true, dateName: dateName);
      } else if (loadAll == true) {
        files = await device.getRecordFile(
            supportRecordTypeSeach: true, cache: false);
      } else {
        DateTime nowDateTime = DateTime.now();
        String year = nowDateTime.year.toString();
        String month = twoDigits(nowDateTime.month);
        String day = twoDigits(nowDateTime.day);
        String nowdDateName = year + month + day;

        if (device.recordFileList.isEmpty) {
          List<DateTime> dateTimes = await getRecordTypeSearchDate(deviceId);
          if (dateTimes.isNotEmpty) {
            dateTimes.sort((a, b) {
              return a.compareTo(b);
            });
            DateTime nearDateTime = dateTimes.last;
            year = nearDateTime.year.toString();
            month = twoDigits(nearDateTime.month);
            day = twoDigits(nearDateTime.day);
            String nearDateName = year + month + day;
            files = await device.getRecordFile(
                supportRecordTypeSeach: true, dateName: nearDateName);
          }
        }
        if (loadMore == true) {
          files = await device.getRecordFile(supportRecordTypeSeach: true);
        } else {
          files = await device.getRecordFile(
              supportRecordTypeSeach: true, dateName: nowdDateName);
        }
      }
    } else {
      if (loadAll == true) {
        ///获取全部数据
        files = await device.getRecordFile(cache: false);
      } else {
        int pageIndex = 0;
        if (loadMore == true) {
          pageIndex = device.recordFileList.length ~/ 10;
        }
        var oldList = device.recordFileList;

        ///获取录像数据
        List<RecordFile> files =
            await device.getRecordFile(pageIndex: pageIndex, pageSize: 10);
        if (oldList.length == files.length) {
          files = await device.getRecordFile(
              pageIndex: pageIndex + 1, pageSize: 10);
        }
        Directory dir = await device.getDeviceDirectory();
        dir = Directory("${dir.path}/tf_cache");
        if (dir.existsSync()) {
          files.forEach((element) {
            File file = File("${dir.path}/${element.record_name}");
            if (file.existsSync()) {
              element.record_cache_size =
                  File("${dir.path}/${element.record_name}").lengthSync();
              if (element.record_cache_size > element.record_size) {
                element.record_cache_size = element.record_size;
              }
            }
          });
        }
        //yield CameraGetRecordFileState.success(did, files);
      }
    }

    recordFiles.clear();
    files.forEach((element) {
      RecordTimeLineModel? timeLine;
      if (element.lineFile != null) {
        var line = element.lineFile!;
        print("---------------------------record_name:${line.record_name}");
        if (line.record_duration < 4 || line.record_duration > 1000) {
          print(
              "tf文件异常: record_name:${line.record_name}, record_duration:${line.record_duration}");
          return;
        }
        timeLine = RecordTimeLineModel(
            line.record_name,
            line.record_time,
            line.record_alarm,
            line.record_start!,
            line.record_end!,
            line.record_duration,
            line.frame_len,
            line.frame_interval);
        line.frames.forEach((item) {
          timeLine!.frames.add(RecordTimeFrameModel(
              item.timestamp!, item.frame_no!, item.frame_gop!));
        });
      }

      ///创建录像Model
      RecordFileModel model = RecordFileModel(
          element.record_name!,
          element.record_alarm!,
          element.record_time!,
          element.record_size,
          element.record_head!,
          timeLine: timeLine);
      recordFiles.add(model);
    });
    return recordFiles;
  }

  Future<void> dealTFScrollRecordFile(List<RecordFileModel> allData) async {
    //print("_dealTFScrollRecordFile:$pullType,$loadCount,${allData.isNotEmpty}");
    List<DateTime> tabData = [];
    print("-------------dealTFScrollRecordFile-------------");
    if (allData.isNotEmpty) {
      allData.forEach((element) {
        state!.filterMap[element.recordName] = element;
        DateTime time = DateTime(element.recordTime.year,
            element.recordTime.month, element.recordTime.day);
        if (!tabData.contains(time)) {
          tabData.add(time);
        }
      });
      tabData.sort((a, b) {
        return b.compareTo(a);
      });

      allData = state!.filterMap.values.toList();
      getTFRecordModeTimes(allData);
    }

    if (state!.selectTime.value == null && tabData.isNotEmpty) {
      state!.selectTime(tabData.first);
    }
    state!.tabData.value.clear();
    state!.tabData.addAll(tabData);
    if (allData.isNotEmpty && state!.selectTime.value != null) {
      ///获取当前下标
      int index = state!.tabData
          .indexWhere((element) =>
              element.year == state!.selectTime.value!.year &&
              element.month == state!.selectTime.value!.month &&
              element.day == state!.selectTime.value!.day)
          .toInt();
      if (index < 0) {
        //刷新最新数据
        getTFRecordModeTimes(allData);
        index = 0;
      }
      if (index > tabData.length - 1) {
        index = tabData.length - 1;
        EasyLoading.showToast('后面没有录像视频了'.tr,
            maskType: EasyLoadingMaskType.clear);
        return;
      }

      ///选中的日历
      state!.selectTime(tabData[index]);

      ///数据排序
      allData.sort((a, b) {
        return b.recordTime.compareTo(a.recordTime);
      });
      state!.recordFileModels.value.clear();
      state!.recordFileModels.value = allData;

      var model = allData.first;
      if (state!.selectModel.value == null) {
        state!.tfTimeLoading.value = false;
        startSliderAnimate();
        state!.selectModel(model);
        state!.playModel(model);
        startVideo();
      }
    }
    return;
  }

  Map<String, RecordFileModel> resultMap = Map();

  void getTFRecordModeTimes(List<RecordFileModel> lists) {
    lists.forEach((model) {
      if (model.timeLine == null || model.timeLine?.recordStart == null) {
        print(
            "----timeLine---${model.timeLine}-----recordStart--${model.timeLine?.recordStart}-----------------");
        return;
      }
      resultMap[model.recordName] = model;
    });
    List<RecordFileModel> recordLists = resultMap.values.toList() ?? [];

    recordLists.sort((a, b) => (a.recordTime).compareTo(b.recordTime));
    state!.allRecordTimes.value.clear();
    state!.allRecordTimes.value.addAll(recordLists);
    if (recordLists.length > 0 && state!.selectModel.value == null) {
      var model = state!.allRecordTimes.value.last;
      Future.delayed(Duration(milliseconds: 500), () {
        setSliderCurrentTime(model.timeLine!.endTime);
      });
    }
  }

  Future<List<DateTime>> getRecordTypeSearchDate(String deviceId) async {
    CameraDevice cameraDevice = DeviceManager.getInstance().mDevice!;
    List<String> listDates = await cameraDevice.getRecordTypeSearchDate();
    if (listDates.isNotEmpty) {
      List<DateTime> dateTimes = [];
      listDates.forEach((element) {
        if (element.length == 8) {
          int year = int.tryParse(element.substring(0, 4)) ?? 0;
          int month = int.tryParse(element.substring(4, 6)) ?? 0;
          int day = int.tryParse(element.substring(6, 8)) ?? 0;
          DateTime time = DateTime(year, month, day);
          dateTimes.add(time);
        }
      });
      return dateTimes;
    }
    return [];
  }

  Future<bool> setVideoSource(String deviceId, RecordFileModel model) async {
    CameraDevice? cameraDevice = DeviceManager.getInstance().mDevice;
    if (cameraDevice == null) return false;

    if (controller == null) return false;

    if (state?.playModel != null &&
        model.recordName == state?.playModel.value!.recordName &&
        model.loadSize >= model.recordSize) return true;

    var clientPtr = cameraDevice.clientPtr;
    if (clientPtr == null) return false;

    print("setVideoSource:${model.recordName} ${model.recordHead}");
    state!.playDuration = 0;
    initSec = 0;
    await controller.stop();
    state!.videoStatus(VideoStatus.STARTING);
    var result = false;
    if (model.timeLine == null) {
      result = await controller.setVideoSource(CardVideoSource(
          clientPtr, model.recordSize,
          checkHead: (model.recordHead == true ? 1 : 0)));
    } else {
      result = await controller.setVideoSource(TimeLineSource(clientPtr));
    }
    if (result == true) {
      state!.playModel.value = model..loadSize = 0;
      Directory dir = await cameraDevice.getDeviceDirectory();
      dir = Directory("${dir.path}/tf_cache");
      if (!dir.existsSync()) dir.createSync(recursive: true);
      state!.cacheFile = File("${dir.path}/${model.recordName}");
    }
    return result;
  }

  ///开始播放视频，timestamp时间戳，可通过时间戳获取对应的视频文件
  Future<bool> startPlayer({int? timestamp}) async {
    var model = state!.playModel.value;
    CameraDevice? device = DeviceManager.getInstance().mDevice;
    if (model == null) return false;
    if (device == null) return false;
    if (state!.supportTimeLine.value) {
      bool bl =
          await setVideoSource(DeviceManager.getInstance().mDevice!.id, model);
      // controller!.stop();
    }

    var result = true;
    if (model.timeLine == null) {
      print(
          "startPlayer:${model.recordName} loadSize:${model.loadSize} recordSize:${model.recordSize}");
      initSec = 0;
      if (model.loadSize < model.recordSize)
        result = await device.startRecordFile(model.recordName, 0);
    } else {
      RecordTimeLineModel? lineModel;
      int sec = 0;
      if (timestamp == null) {
        lineModel = model.timeLine;
        if (lineModel == null) return false;
      } else {
        lineModel = await findTimeLineModel(timestamp);
        if (lineModel == null) return false;
        sec = (timestamp * 1000) - lineModel.recordStart.millisecondsSinceEpoch;
        sec = sec ~/ 1000;
      }
      var list = lineModel.getFrameNo(sec);
      if (list.isEmpty) return false;
      sec = list[1];
      print(
          "time:${lineModel.recordTime} name:${lineModel.recordName} event:${lineModel.recordAlarm} duration:${lineModel.recordDuration} frameLen:${lineModel.frameLen} "
          "sec:$sec frameNo:${list[0]}");

      state!.playDuration = sec;
      var channel = state!.channel == 2 ? 3 : 2;
      int key = Random().nextInt(9999);
      initSec = sec;
      controller.setChannelKey(channel, key);
      result = await device.startRecordLineFile(
          lineModel.recordTime, lineModel.recordAlarm,
          channel: channel, frameNo: list[0], key: key);
      state!.channel = channel;
      state!.duration = lineModel.recordDuration;
    }

    if (state!.isSupportTimeLine.value) {
      setSliderCurrentTime(model.timeLine!.startTime);
    }
    if (state!.playRate == 1.0) {
      result = await controller.startVoice();
    }
    result = await controller.start();

    return result;
  }

  Future<RecordTimeLineModel?> findTimeLineModel(int timestamp) async {
    var dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    var list = DeviceManager.getInstance().mDevice!.getAllLineFile();
    list.sort((a, b) {
      return a.record_start!.compareTo(b.record_start!);
    });
    var lineFile = list.lastWhere((element) {
      var bl = element.record_start!.isBefore(dateTime) ||
          element.record_start == dateTime;
      return bl;
    });
    if (lineFile == null) return null;
    RecordTimeLineModel lineModel = RecordTimeLineModel(
        lineFile.record_name,
        lineFile.record_time,
        lineFile.record_alarm,
        lineFile.record_start!,
        lineFile.record_end!,
        lineFile.record_duration,
        lineFile.frame_len,
        lineFile.frame_interval);
    lineFile.frames.forEach((item) {
      lineModel.frames.add(RecordTimeFrameModel(
          item.timestamp!, item.frame_no!, item.frame_gop!));
    });
    return lineModel;
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }

  Future<bool> stopPlayer() async {
    DeviceManager.getInstance().mDevice?.stopRecordFile();
    var result = await controller.stop() ?? false;
    return result;
  }

  void startVideo() async {
    await stopPlayer();
    if (state?.recordFileModels != null &&
        state!.recordFileModels.value.isNotEmpty) {
      bool bl = await setVideoSource(
          DeviceManager.getInstance().mDevice!.id, state!.playModel.value!);
      if (!bl) state!.videoStatus(VideoStatus.STOP);
      startPlayer();
    }
  }

  AnimationController? _controller;

  startSliderAnimate() {
    _controller?.value = 1.0;
    _controller?.animateTo(14400.0,
        duration: const Duration(milliseconds: 1000));
  }

  void initAnimationController() async {
    _controller =
        AnimationController(vsync: this, lowerBound: 1.0, upperBound: 14400.0);
    _controller!.addListener(_sliderAnimationListener);
  }

  void _sliderAnimationListener() {
    var value = _controller!.value;
    Future.delayed(Duration(milliseconds: 1), () {
      var startTime = state!.selectModel.value?.timeLine?.startTime;
      if (startTime != null) {
        double time = startTime.toDouble() - 14400;
        time = time + value;
        Get.tryFind<TFTimeSliderLogic>(tag: 'TFPlayState')
            .setSliderCurrentTime(time.toInt());
      }
    });
  }

  Future<void> stopVideo() async {
    await stopPlayer();
  }

  void pauseVideo() {
    controller.pause();
  }

  void resumeVideo() {
    controller.resume();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  ///删除tf录像文件
  Future<List<RecordFileModel>> deleteRecordFile(
      RecordFileModel recordFile, bool localFile) async {
    //yield CameraDeleteRecordFileState.start(did, result: event.recordFile);
    bool result = false;
    print("------delete recordName ${recordFile.recordName}-----------------");
    if (localFile != true) {
      result = await DeviceManager.getInstance()
          .mDevice!
          .deleteRecordFile(recordFile.recordName);
      // print("------delete result $result-----------------");
      EasyLoading.showToast("数据删除成功！");
    } else {
      result = true;
    }
    if (result == true) {
      Directory dir =
          await DeviceManager.getInstance().mDevice!.getDeviceDirectory();
      dir = Directory("${dir.path}/tf_cache");
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File file = File("${dir.path}/${recordFile.recordName}");
      if (file.existsSync()) {
        file.deleteSync();
      }
      file = File("${file.path}_head");
      if (file.existsSync()) {
        file.deleteSync();
      }
      recordFile.videoProgress.value = 0;
    }

    recordFiles.clear();
    DeviceManager.getInstance().mDevice!.recordFileList.forEach((element) {
      RecordFileModel model = RecordFileModel(
          element.record_name!,
          element.record_alarm!,
          element.record_time!,
          element.record_size,
          element.record_head!);
      recordFiles.add(model);
    });

    ///数据排序
    recordFiles.sort((a, b) {
      return b.recordTime.compareTo(a.recordTime);
    });
    state!.recordFileModels.value = recordFiles;
    return recordFiles;
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
      bl = await enableCloudSubPlayer(sub2Player: true);
      print("-----------3-------enableSubPlayer---$bl---------------");
    } else if (sensor == 1 || (sensor == 3 && splitScreen == 1)) {
      ///二目或者假三目
      bl = await enableCloudSubPlayer();
      print("-----------2-------enableSubPlayer---$bl---------------");
    }
    return bl;
  }

  ///创建多目播放器
  Future<bool> enableCloudSubPlayer({bool sub2Player = false}) async {
    if (controller.sub_controller != null) return true;
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
    result = await controller.enableSubPlayer(subController);
    if (result != true) {
      print("-------------enableSubPlayer---false---------------");
      return false;
    }
    state?.tfPlayer2Controller = subController;

    //sub2Player
    if (sub2Player == true) {
      if (controller.sub2_controller != null) return true;
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
      result = await controller.enableSub2Player(sub2Controller);
      if (result != true) {
        print("-------------enableSub2Player---false---------------");
        return false;
      }
      state?.tfPlayer3Controller = sub2Controller;
    }
    if (sub2Player) {
      state?.tfHasSubPlay.value = 2;
    } else {
      state?.tfHasSubPlay.value = 1;
    }
    return true;
  }
}
