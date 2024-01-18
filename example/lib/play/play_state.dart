import 'dart:io';

import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';

class PlayState {
  /// Player语音状态
  VoiceStatus voiceStatus = VoiceStatus.STOP;

  ///Player对讲语音录制状态
  RecordStatus recordStatus = RecordStatus.STOP;

  ///视频播放状态
  Rx<VideoStatus> videoStatus = Rx<VideoStatus>(VideoStatus.STOP);

  RxInt velocity = 0.obs;
  RxInt streamHandle = 0.obs;
  RxInt playChange = 0.obs;

  var videoPause = RxBool(true);
  var videoStop = RxBool(true);

  ///声音开关
  var videoVoiceStop = RxBool(true);

  ///视频时长
  int duration = 0;

  ///视频播放当前进度
  int progress = 0;

  ///录制时长
  RxInt recordProgress = 0.obs;

  ///开始录制时间
  int recordStartSec = 0;

  ///录制视频文件
  late File recordFile;

  ///视频录制
  var videoRecord = RxBool(false);

  /// 视频截图文件
  Rx<File?> snapshotFile = Rx<File?>(null);

  AppPlayerController? playerController;
  AppPlayerController? player2Controller; //第二目
  AppPlayerController? player3Controller; //第三目

  //0 球机，1有一个（双目），2有两个（三目）
  RxInt hasSubPlay = 0.obs;

  //0球机被选中,1枪机1被选中,2枪机2被选中
  RxInt select = 0.obs;

  ///联动是否开启
  var isLinkableOpen = RxBool(false);

  ///光学变焦值
  RxInt zoomValue = 1.obs;
}
