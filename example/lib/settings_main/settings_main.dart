import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';
import 'package:vsdk_example/play/play_logic.dart';
import 'package:vsdk_example/settings_main/ptz/ptz_widget.dart';
import 'package:vsdk_example/settings_main/settings_main_logic.dart';
import 'package:vsdk_example/settings_main/settings_main_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';

import '../app_routes.dart';
import '../model/device_model.dart';
import '../settings_alarm/Settings_logic.dart';

class SettingsMain extends GetView<SettingsMainLogic> {
  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final logic = controller;

    if (state == null) return Container();
    SettingsLogic settingsLogic = Get.find<SettingsLogic>();

    ///人形框定如果打开了，则人形检测一定打开了。
    if (state.peopleFrameOpen.value) {
      settingsLogic.state!.humanJudge.value = true;
    }

    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
                onTap: () {
                  logic.onJoystickClick(MotorDirection.startLeft);
                },
                child: Text("往左<<")),
            SizedBox(width: 20),
            GestureDetector(
                onTap: () {
                  logic.onJoystickClick(MotorDirection.startRight);
                },
                child: Text("往右>>")),
            SizedBox(width: 20),
            GestureDetector(
                onTap: () {
                  logic.onJoystickClick(MotorDirection.startUp);
                },
                child: Text("往上")),
            SizedBox(width: 20),
            GestureDetector(
                onTap: () {
                  logic.onJoystickClick(MotorDirection.startDown);
                },
                child: Text("往下")),
            SizedBox(width: 20),

            ///云台
            GestureDetector(
                onTap: () {
                  ///打开或关闭云台
                  showPTZSheet(state, logic);
                },
                child:
                    Text("云台", style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        SizedBox(height: 20),
        GetBuilder<PlayLogic>(
            builder: (c) => Wrap(
                  children: [
                    ///对讲开关
                    ObxValue<Rx<VoiceState>>((data) {
                      return GestureDetector(
                          onTap: () async {
                            ///打开对讲功能
                            if (c.state == null) return;

                            bool isSuc = await logic.startStopTalk(c.state!);
                            if (isSuc) {
                              if (data.value == VoiceState.play) {
                                c.state!.videoVoiceStop.value = false;
                              } else {
                                c.state!.videoVoiceStop.value = true;
                              }
                            }
                          },
                          child: data.value == VoiceState.play
                              ? settingSwitcher("对讲", open: true)
                              : settingSwitcher("对讲", open: false));
                    }, state.voiceState),

                    ///拍照
                    GestureDetector(
                        onTap: () {
                          ///点击拍照
                          logic.getSnapShot();
                        },
                        child: settingSwitcher("拍照")),

                    ///录像
                    ObxValue<Rx<RecordState>>((data) {
                      return GestureDetector(
                          onTap: () {
                            ///开始或停止录制视频
                            if (c.state == null) return;
                            logic.startOrStopRecord(c.state!);
                          },
                          child: data.value == RecordState.recording
                              ? settingSwitcher("录像", open: true)
                              : settingSwitcher("录像", open: false));
                    }, state.recordState),

                    ///警笛开关
                    ObxValue<RxBool>((data) {
                      return GestureDetector(
                          onTap: () {
                            ///打开或关闭警笛，设备打开或关闭可能有延时
                            if (c.state == null) return;
                            logic.onClickSiren(c.state!);
                          },
                          child: data.value
                              ? settingSwitcher("警笛", open: true)
                              : settingSwitcher("警笛", open: false));
                    }, state.siren),

                    ///白光灯开关
                    Visibility(
                      //设备支持白光灯且支持手动开启白光灯才显示
                      visible: (DeviceManager.getInstance()
                                  .deviceModel
                                  ?.haveWhiteLight
                                  .value ??
                              false) &&
                          DeviceManager.getInstance()
                                  .deviceModel
                                  ?.support_manual_light
                                  .value !=
                              "0",
                      child: ObxValue<RxBool>((data) {
                        return GestureDetector(
                            onTap: () {
                              ///打开或关闭白光灯， 白光灯模式默认不闪烁
                              logic.openOrCloseLight();
                            },
                            child: data.value
                                ? settingSwitcher("白光灯", open: true)
                                : settingSwitcher("白光灯", open: false));
                      }, state.lightOpen),
                    ),

                    ///人形框定，人形框定同时打开人形检测
                    Visibility(
                      visible: DeviceManager.getInstance()
                              .deviceModel
                              ?.supportHumanoidFrame
                              .value ==
                          1,
                      child: ObxValue<RxBool>((data) {
                        return GestureDetector(
                            onTap: () {
                              ///打开或关闭人形框定
                              if (c.state == null) return;
                              logic.openOrClosePeopleFrame(c.state!);
                            },
                            child: data.value
                                ? settingSwitcher("人形框定", open: true)
                                : settingSwitcher("人形框定", open: false));
                      }, state.peopleFrameOpen),
                    ),

                    ///运动侦测
                    ObxValue<RxBool>((data) {
                      return GestureDetector(
                          onTap: () {
                            Get.toNamed(AppRoutes.settings);
                          },
                          child: data.value
                              ? settingSwitcher("运动侦测", open: true)
                              : settingSwitcher("运动侦测", open: false));
                    }, settingsLogic.state!.motionAlarm),

                    ///TF卡回放
                    GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.tfPlay);
                        },
                        child: settingSwitcher("TF回放")),

                    ///云回放
                    Visibility(
                      visible: !DeviceManager.getInstance()
                          .deviceModel!
                          .is4GDataFlowBind
                          .value,
                      child: GestureDetector(
                          onTap: () {
                            Get.toNamed(AppRoutes.cloudplay);
                          },
                          child: settingSwitcher("云回放")),
                    ),

                    ///人形追踪
                    Visibility(
                        visible: (DeviceManager.getInstance()
                                    .deviceModel
                                    ?.supportHumanDetect
                                    .value ??
                                0) >
                            0,
                        child: ObxValue<RxBool>((data) {
                          return GestureDetector(
                              onTap: () {
                                logic.setHumanTrack(data.value ? 0 : 1);
                              },
                              child: data.value
                                  ? settingSwitcher("人形追踪", open: true)
                                  : settingSwitcher("人形追踪", open: false));
                        }, state.humanTrackOpen)),

                    ///画质
                    GestureDetector(
                        onTap: () {
                          showResolutionSheet(state, logic);
                        },
                        child: ObxValue<Rx<VideoResolution>>((data) {
                          String name = getResolutionName(data);
                          return settingSwitcher(name);
                        }, state.resolution)),

                    ///夜视模式
                    GestureDetector(
                        onTap: () {
                          showNightModeSheet(state, logic);
                        },
                        child: settingSwitcher("夜视模式")),

                    ///人形变倍跟踪
                    Visibility(
                        visible: (DeviceManager.getInstance()
                                    .deviceModel
                                    ?.supportHumanoidZoom
                                    .value ??
                                0) >
                            0,
                        child: ObxValue<RxBool>((data) {
                          return GestureDetector(
                              onTap: () {
                                logic.setZoomTrack(data.value ? 0 : 1);
                              },
                              child: data.value
                                  ? settingSwitcher("变倍跟踪", open: true)
                                  : settingSwitcher("变倍跟踪", open: false));
                        }, state.zoomTrackOpen)),

                    ///红蓝灯开关
                    Visibility(
                        visible: DeviceManager.getInstance()
                                .deviceModel
                                ?.haveRedBlueLight
                                .value ??
                            false,
                        child: ObxValue<RxBool>((data) {
                          return GestureDetector(
                              onTap: () {
                                controller.redBlueLightSwitch(!data.value);
                              },
                              child: data.value
                                  ? settingSwitcher("红蓝灯", open: true)
                                  : settingSwitcher("红蓝灯", open: false));
                        }, state.redBlueOpen)),
                  ],
                )),
        SizedBox(height: 20),
      ],
    );
  }

  void showPTZSheet(SettingsMainState state, SettingsMainLogic logic) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            decoration: BoxDecoration(border: Border(top: BorderSide())),
            child: Padding(
                padding: const EdgeInsets.all(16.0), child: PTZWidget()),
          );
        });
  }

  void showResolutionSheet(SettingsMainState state, SettingsMainLogic logic) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
            height: 200,
            decoration: BoxDecoration(border: Border(top: BorderSide())),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Visibility(
                        visible: DeviceManager.getInstance()
                                .deviceModel
                                ?.support_pixel_shift
                                .value ==
                            "1",
                        child: GestureDetector(
                            onTap: () {
                              logic.setResolutionValue(VideoResolution.superHD);
                            },
                            child: Text(
                              "超高清",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ))),
                    SizedBox(height: 24),
                    GestureDetector(
                        onTap: () {
                          logic.setResolutionValue(VideoResolution.high);
                        },
                        child: Text("高清",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(height: 24),
                    GestureDetector(
                        onTap: () {
                          logic.setResolutionValue(VideoResolution.general);
                        },
                        child: Text("普清",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(height: 24),
                    GestureDetector(
                        onTap: () {
                          logic.setResolutionValue(VideoResolution.low);
                        },
                        child: Text("低质",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                )),
          );
        });
  }

  String getResolutionName(Rx<VideoResolution> data) {
    String name = "普清";
    switch (data.value) {
      case VideoResolution.high:
        name = "高清";
        break;
      case VideoResolution.general:
        name = "普清";
        break;
      case VideoResolution.low:
        name = "低质";
        break;
      case VideoResolution.superHD:
        name = "超高清";
        break;
      case VideoResolution.unknown:
        name = "未知";
        break;
      default:
        name = "普清";
        break;
    }
    return name;
  }

  ///夜视模式设置
  void showNightModeSheet(SettingsMainState state, SettingsMainLogic logic) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
              height: 200,
              decoration: BoxDecoration(border: Border(top: BorderSide())),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ObxValue<RxInt>((data) {
                    return Column(
                      children: [
                        GestureDetector(
                            onTap: () {
                              logic.setNightMode(0);
                            },
                            child: Text("黑白夜视",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: data.value == 0
                                        ? Colors.red
                                        : Colors.black))),
                        SizedBox(height: 24),
                        GestureDetector(
                            onTap: () {
                              logic.setNightMode(1);
                            },
                            child: Text("全彩夜视",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: data.value == 1
                                        ? Colors.red
                                        : Colors.black))),
                        SizedBox(height: 24),
                        GestureDetector(
                            onTap: () {
                              logic.setNightMode(2);
                            },
                            child: Text("智能夜视",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: data.value == 2
                                        ? Colors.red
                                        : Colors.black))),
                        SizedBox(height: 24),
                        GestureDetector(
                            onTap: () {
                              logic.setNightMode2();
                            },
                            child: Text("星光夜视",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: data.value == 3
                                        ? Colors.red
                                        : Colors.black))),
                      ],
                    );
                  }, state.currentNightMode)));
        });
  }

  Widget settingSwitcher(String text, {bool open = false}) {
    return Container(
        width: 60,
        height: 60,
        color: open ? Colors.red : Colors.grey,
        margin: EdgeInsets.all(2.0),
        alignment: Alignment.center,
        child: Text(text));
  }
}
