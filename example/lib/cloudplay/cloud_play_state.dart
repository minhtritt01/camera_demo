import 'dart:io';

import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';

class CloudPlayState {
  /// Player语音状态
  VoiceStatus voiceStatus = VoiceStatus.STOP;

  ///视频播放状态
  Rx<VideoStatus> videoStatus = Rx<VideoStatus>(VideoStatus.STOP);

  RxInt playChange = 0.obs;

  ///视频时长
  int duration = 0;

  ///视频播放当前进度
  int progress = 0;

  /// 存储某个设备某天云存储数据的videoKey,如 2023-11-29:03_50_29_06
  Rx<List> keyList = Rx<List>([]);

  AppPlayerController? playerController;
  AppPlayerController? cloudPlayer2Controller; //第二目
  AppPlayerController? cloudPlayer3Controller; //第三目

  //0 球机，1有一个（双目），2有两个（三目）
  RxInt cloudHasSubPlay = 0.obs;
}
