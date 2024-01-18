import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';
import '../../model/record_file_model.dart';
import '../../tf_play/tf_play_logic.dart';
import '../../tf_play/tf_play_state.dart';
import '../../utils/super_put_controller.dart';

/// cloud_time_slider 控制器
mixin TFTimeSliderLogic on SuperPutController<TFPlayState> {
  @override
  void initPut() {
    lazyPut<TFTimeSliderLogic>(this);
    super.initPut();
  }

  int _sartCurrentTime = 0;

  Timer? _timer;
  bool _sliding = false;
  Worker? _selectTimeWorker;

  @override
  void onInit() {
    configLoading();
    super.onInit();
  }

  @override
  void onReady() {
    _selectTimeWorker = ever(state!.selectTime, onSelectTimeChanged);
    super.onReady();
  }

  ///选择的日期时间改变的时候，更新数据，日期选择未实现
  void onSelectTimeChanged(DateTime? date) {
    //print("onSelectTimeChanged: $date");
    if (date != null && state!.gestureSliding.value == true) {
      List<RecordFileModel> temp = state!.filterMap.values
              .where((element) =>
                  ((state!.supportTimeLine.value == true &&
                          element.recordAlarm != 0) ||
                      state!.supportTimeLine.value != true) &&
                  element.recordTime.year == date.year &&
                  element.recordTime.month == date.month &&
                  element.recordTime.day == date.day)
              .toList() ??
          [];

      // ///数据排序
      // temp.sort((a, b) {
      //   return b.recordTime.compareTo(a.recordTime);
      // });
      state!.recordFileModels.value.clear();
      state!.recordFileModels.value.addAll(temp);
    }
  }

  ///获取缩放数据
  void getScaleMode(int value) {
    print("缩放的结果: $value， ${state!.currentScale}");
    state!.currentScale = state!.tfCardKey?.currentState?.currentScale;
    state!.zoom(value);
    List<double> scales = state!.tfCardKey?.currentState?.scales;
    if (value == 1 && state!.currentScale == scales.last) {
      EasyLoading.showToast("已缩放到最小".tr);
      state!.scaleAddEnable(false);
      state!.scaleReduceEnable(true);
    } else if (value == -1 && state!.currentScale == scales.first) {
      EasyLoading.showToast("已缩放到最小".tr);
      state!.scaleAddEnable(true);
      state!.scaleReduceEnable(false);
    } else {
      if (state!.currentScale != scales.last &&
          state!.currentScale != scales.first) {
        state!.scaleAddEnable(true);
        state!.scaleReduceEnable(true);
      }
    }
  }

  int _preDirection = 0;

  ///滑动时间轴后的回调（包含缩放数据）
  void getMoveAndScaleMode(String mode) {
    //print("mode>>$mode");
    if (mode == "start") {
      _sliding = true;
      state!.gestureSliding.value = true;
      _sartCurrentTime = state!.tfCardKey.currentState.currentTime;
      state!.currentTimeLine.value = _sartCurrentTime;
      _cancelTimer();
    } else if (mode == "update") {
      state!.gestureSliding.value = true;
      int currentTime = state!.tfCardKey.currentState.currentTime;
      state!.currentTimeLine.value = currentTime;
      int direction = currentTime - _sartCurrentTime;

      ///防止手指松开后的抖动
      if ((_preDirection <= 0 && direction > 0) ||
          (_preDirection >= 0 && direction < 0)) {
        _preDirection = direction;
        return;
      }
      if (direction < 0) {
        state!.sliderDirection(-1);
      } else if (direction > 0) {
        state!.sliderDirection(1);
      }
      _preDirection = direction;
      _sartCurrentTime = currentTime;
    } else if (mode == "end") {
      ///end 时间轴拖动结束
      Future.delayed(Duration(milliseconds: 1500), () {
        state!.gestureSliding.value = false;
      });
      state!.currentScale = state!.tfCardKey.currentState.currentScale;

      ///获取到拖动后的时间点
      int currentTime = state!.tfCardKey.currentState.currentTime;
      state!.currentTimeLine.value = currentTime;
      int lefTime = state!.tfCardKey.currentState.leftTime;
      int rightTime = state!.tfCardKey.currentState.rightTime;
      int direction = currentTime - _sartCurrentTime;
      int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print(
          "currentTime>> $currentTime, $lefTime, $rightTime, $direction, $nowTime");
      if (state!.allRecordTimes.value.isEmpty) return;
      var model = state!.allRecordTimes.value.last;

      ///如果拖动的时间节点在最新的数据之后，则设置为最后一条数据
      if (currentTime > nowTime ||
          (model != null && currentTime > model.timeLine!.endTime)) {
        print("-------------设置为最后一条数据--------------");
        currentTime = nowTime;
        Future.delayed(Duration(milliseconds: 1), () async {
          setSliderCurrentTime(model.timeLine!.startTime);
          // await Future.delayed(Duration(milliseconds: 10));
          // setSliderCurrentTime(model.timeLine!.startTime);
          state!.modelIndex = state!.allRecordTimes.value.length - 1;
          if (state!.selectModel.value == model) {
            _setPlayerProgress(0.0);
          } else {
            state!.selectModel.value = model;
          }
          _sliding = false;
        });
        return;
      }

      ///加载当前时间对应的视频数据
      loadRealTimeData(currentTime, lefTime, rightTime, direction);
    }
  }

  void loadRealTimeData(
      int currentTime, int lefTime, int rightTime, int direction) async {
    // var ct = DateTime.fromMillisecondsSinceEpoch(currentTime * 1000);
    // var lt = DateTime.fromMillisecondsSinceEpoch(lefTime * 1000);
    // var rt = DateTime.fromMillisecondsSinceEpoch(rightTime * 1000);
    // DateTime time = DateTime(ct.year, ct.month, ct.day);
    // state!.selectTime(time);
    // print("ct>>$ct, $lt, $rt, $direction");
    // if (direction < 0) {
    //   bool bll = await Get.find<ICloudVideoProvider>().isLeftTimeDay(ct, lt);
    //   print("bll>>左>>$bll");
    //   if (bll == true) {
    //     //await loadRealTimeforSever(lt);
    //   }
    // } else if (direction > 0) {
    //   bool blr = await Get.find<ICloudVideoProvider>().isRightTimeDay(ct, rt);
    //   print("blr>>右>>$blr");
    //   if (blr == true) {
    //     //await loadRealTimeforSever(rt);
    //   }
    // }
    state!.currentTime = currentTime;
    newTimeLineModelPlay();
    // _startTimer();
  }

  Future<bool> loadRealTimeforSever(DateTime dateTime) async {
    int tempTime = dateTime.millisecondsSinceEpoch ~/ 1000;
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (tempTime > nowTime) {
      return false;
    }
    _showLoading();
    // List<CloudVideoGroupModel> realClouds =
    //     await Get.tryFind<ICloudVideoProvider>()
    //         ?.getCloudRealTime(state.deviceModel.value.id, dateTime);
    // state.realTimeClouds.value.clear();
    // state.realTimeClouds.addAll(realClouds);
    _dismissLoading();
    return true;
  }

  void _startTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    _timer = Timer(Duration(milliseconds: 1500), timerCallBack);
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _setSelectTime(RecordFileModel model) {
    DateTime ct = model.recordTime;
    DateTime time = DateTime(ct.year, ct.month, ct.day);
    state?.selectTime(time);
  }

  ///通过时间戳查找对应的视频model
  int _queryIndex(List<RecordFileModel> modeList, int timeSec) {
    int index = -1;
    if (modeList.isNotEmpty) {
      for (int i = 0; i < modeList.length; i++) {
        var model = modeList[i];
        if (model.timeLine == null) {
          continue;
        }
        int time = model.timeLine!.endTime;
        if (timeSec < time) {
          index = i;
          break;
        }
      }
    }
    return index;
  }

  ///定时回调，
  void timerCallBack() async {
    print("-------------timerCallBack------------------");
    _showLoading();

    ///查询选中的时间对应的视频文件
    var index = _queryIndex(state!.allRecordTimes.value, state!.currentTime);
    _cancelTimer();
    state!.progressValue = 0;
    if (index != -1) {
      state!.modelIndex = index;

      ///获取到选中时间对应的视频model
      var model = state!.allRecordTimes.value[index];
      int start = model.timeLine!.startTime;
      int diff = state!.currentTime - start;
      print(
          "model>>${model.recordName}, $start, 是有效偏移值: $diff, ${model.timeLine!.recordStart}");
      if (diff > 0) {
        state!.progressValue = diff;
      }
      state!.selectModel.value = model;
      state!.playModel.value = model;

      ///设置视频最新的进度
      _setPlayerProgress(state!.progressValue.toDouble());
    }
    _dismissLoading();
    _sliding = false;
  }

  void newTimeLineModelPlay() async {
    _showLoading();
    print("-----------newTimeLineModelPlay---------------");

    ///查询选中的时间对应的视频文件
    var index = _queryIndex(state!.allRecordTimes.value, state!.currentTime);
    print("-----------index-$index--------------");
    state!.progressValue = 0;
    if (index != -1) {
      state!.modelIndex = index;

      ///获取到选中时间对应的视频model
      var model = state!.allRecordTimes.value[index];
      state!.selectModel.value = model;
      state!.playModel.value = model;
      TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
      if (model.timeLine?.recordStart == null) {
        return;
      }
      await tfPlayLogic.stopVideo();
      print("-----------startPlayer---------------");
      tfPlayLogic.startPlayer();
    }
    _dismissLoading();
    _sliding = false;
  }

  void setSliderCurrentTime(int currentTime) {
    state?.tfCardKey?.currentState?.setCurrentTime(currentTime);
    state?.currentTime = currentTime;
  }

  void setSliderCurrentScale(double scale) {
    state?.tfCardKey?.currentState?.setCurrentScale(scale);
  }

  var progressEnd = false;

  ///设置视频进度
  void _setPlayerProgress(double value) async {
    int timestamp = value.floor();

    RecordFileModel model = state!.selectModel.value!;
    if (model.timeLine?.recordStart == null) {
      return;
    }
    var startTime = model.timeLine!.recordStart.millisecondsSinceEpoch ~/ 1000;
    timestamp += startTime;
    // player.playModel = model;
    // print("player.videoState1: ${player?.videoState}");
    if (state!.videoStatus.value == VideoStatus.PAUSE) {
      await state?.tfPlayer?.resume();
    }
    await state?.tfPlayer?.setProgress(timestamp);
    var current = state!.playDuration;
    int currentTime = model.timeLine!.startTime;
    int currentProgress = currentTime + current;
    setSliderCurrentTime(currentProgress);
    print("player.videoState2: ${state?.videoStatus.value}");
  }

  void getSliderProgress(int current, int total) async {
    var model = state?.selectModel.value;
    if (model == null ||
        current == 0 ||
        total == 0 ||
        _sliding == true ||
        model.timeLine == null) {
      return;
    }

    Future.delayed(Duration(milliseconds: 1), () {
      int currentTime = model.timeLine!.startTime;

      ///视频当前时间 = 视频的开始时间+视频当前播放时间
      int currentProgress = currentTime + current;

      ///把计算的视频当前时间，设置给Slider widget和 TF播放器
      setSliderCurrentTime(currentProgress);
      print("getSliderProgress>>$currentProgress, $current, $total");
    });

    ///当前视频已播放完，通过时间查找对应的视频，继续播放
    if (current == total && progressEnd == false) {
      progressEnd = true;
      state!.progressValue = 0;
      print("loadProgress>>end current ${model.recordName}, "
          "${model.timeLine!.endTime}, "
          "${model.timeLine!.recordStart}, "
          "${state!.modelIndex}");
      var index =
          _queryIndex(state!.allRecordTimes.value, state!.currentTime - 1);
      if (index != -1) {
        state!.modelIndex = index;
        print("----------modelIndex--$index----------");
      } else {
        return;
      }
      Future.delayed(Duration(milliseconds: 1), () async {
        state!.modelIndex = state!.modelIndex + 1;
        if (state!.modelIndex < state!.allRecordTimes.value.length) {
          var model = state!.allRecordTimes.value[state!.modelIndex];
          print("loadProgress>>end next ${model.recordName}, "
              "${model.timeLine!.startTime}, "
              "${model.timeLine!.recordStart}, "
              "${state!.modelIndex}");
          state!.selectModel.value = model;
          state!.playModel.value = model;
          _setSelectTime(model);
          TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
          tfPlayLogic.startPlayer();
        }
      });
    } else {
      progressEnd = false;
    }
  }

  void _showLoading() {
    EasyLoading.show();
  }

  void _dismissLoading() {
    EasyLoading.dismiss();
  }

  void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = Colors.yellow
      ..backgroundColor = Colors.white
      ..indicatorColor = Colors.yellow
      ..textColor = Colors.yellow
      ..maskColor = Colors.blue.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false
      ..maskType = EasyLoadingMaskType.black;
  }

  @override
  void onClose() {
    _selectTimeWorker?.dispose();
    _cancelTimer();
    EasyLoading.dismiss();
    state?.tfCardKey = null;
    super.onClose();
  }
}
