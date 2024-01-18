import 'dart:io';

import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';

import '../model/record_file_model.dart';

class TFPlayState {
  AppPlayerController? tfPlayer;

  ///是否使用时间轴播放，false 则显示列表
  RxBool isSupportTimeLine = true.obs;

  Rx<List<RecordFileModel>> recordFileModels = Rx<List<RecordFileModel>>([]);

  Rx<RecordFileModel?> playModel = Rx<RecordFileModel?>(null);

  ///视频播放状态
  Rx<VideoStatus> videoStatus = Rx<VideoStatus>(VideoStatus.STOP);

  /// Player语音状态
  VoiceStatus voiceStatus = VoiceStatus.STOP;

  ///单位为秒
  int playDuration = 0;

  ///视频时长，单位为秒
  int duration = 0;

  int channel = 0;

  ///播放速率
  double playRate = 1.0;

  File? cacheFile;

  ///时间轴
  var tfCardKey;

  ///单位为秒
  int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  double currentScale = 1;

  var tfTimeLoading = true.obs;

  /// 当前日期
  Rx<DateTime?> selectTime = Rx<DateTime?>(null);

  ///tf时间轴
  Rx<List<RecordFileModel>> allRecordTimes = Rx<List<RecordFileModel>>([]);

  ///拖拽进度
  int progressValue = 0;

  int modelIndex = 0;

  var timeLinePlayer;

  /// 当tf model
  var selectModel = Rx<RecordFileModel?>(null);

  var gestureSliding = false.obs;

  var currentTimeLine = RxInt(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  var sliderDirection = 0.obs;

  Map<String, RecordFileModel> filterMap = Map();

  ///是否支持时间轴
  var supportTimeLine = false.obs;

  /// 时间排序
  var tabData = <DateTime>[].obs;

  var scaleAddEnable = true.obs;

  var scaleReduceEnable = true.obs;

  ///缩放
  var zoom = 0.obs;

  AppPlayerController? playerController;
  AppPlayerController? tfPlayer2Controller; //第二目
  AppPlayerController? tfPlayer3Controller; //第三目

  //0 球机，1有一个（双目），2有两个（三目）
  RxInt tfHasSubPlay = 0.obs;
}
