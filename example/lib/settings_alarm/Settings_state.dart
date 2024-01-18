import 'package:get/get.dart';

class SettingsState {
  ///报警开关（运动侦测）
  var motionAlarm = RxBool(false);

  /// 移动侦测：1 ，人形侦测：5 关闭：0
  RxInt motionPushEnable = 0.obs;

  ///人形判断开关
  var humanJudge = RxBool(false);

  ///侦测距离
  var detectionRange = RxInt(0);

  ///侦测频率
  var detectionFrequency = RxInt(0);

  ///(灵敏度)
  var sensitivity = RxInt(0);

  ///报警闪光灯
  var alarmLightOpen = RxBool(false);

  ///云视频录像
  var cloudVideoOpen = RxBool(false);

  ///报警声开关
  var alarmSoundOpen = RxBool(false);

  ///录制时长对应Index
  var recordTimeIndex = RxInt(0);

  ///智能侦测时间Index
  var smartTimeIndex = RxInt(0);

  ///自定义录制的开始时间
  var startTime = RxInt(0);

  ///自定义录制的结束时间
  var endTime = RxInt(0);

  ///自定义日期列表
  var days = <int>[].obs;
}
