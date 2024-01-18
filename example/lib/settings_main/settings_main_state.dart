import 'package:get/get.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';

import '../model/device_model.dart';

enum VoiceState {
  /// 默认状态
  none,

  /// 正在发送
  play,

  /// 停止
  stop,

  /// 出现错误
  error,
}

enum RecordState {
  /// 默认状态
  none,

  /// 录像中
  recording,

  /// 停止
  stop,

  /// 出现错误
  error,
}

class SettingsMainState {
  /// 对讲语音状态
  Rx<VoiceState> voiceState = VoiceState.none.obs;

  ///录像状态
  Rx<RecordState> recordState = RecordState.none.obs;

  /// [soundType] 0 不使用声音效果
  /// [soundType] 1 大叔声音效果
  /// [soundType] 2 搞怪声音效果
  RxInt soundType = 0.obs;

  ///白光灯开关状态
  var lightOpen = RxBool(false);

  ///人形框定开关
  var peopleFrameOpen = RxBool(false);

  ///警笛开关
  var siren = RxBool(false);

  ///人形追踪
  var humanTrackOpen = RxBool(false);

  ///清晰度
  Rx<VideoResolution> resolution = VideoResolution.general.obs;

  ///夜视模式，0黑白夜视，1全彩夜视，2智能夜视，3星光夜视
  RxInt currentNightMode = 0.obs;

  ///水平巡航
  var isHorizontal = RxBool(false);

  ///垂直巡航
  var isVertical = RxBool(false);

  ///预置位巡航
  var isCruising = RxBool(false);

  ///云台矫正
  var isPtzAdjust = RxBool(false);

  ///人形变倍追踪
  var zoomTrackOpen = RxBool(false);

  ///预置位数据
  var presetData = <PresetModel?>[].obs;

  ///是否支持看守卫设置
  var isSupportGuard = RxBool(false);

  ///看守卫设置状态
  var isGuardEdit = RxBool(false);

  ///看守卫位置
  RxInt guardIndex = (-1).obs;

  ///红蓝灯开关
  var redBlueOpen = RxBool(false);
}
