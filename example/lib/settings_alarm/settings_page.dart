import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk_example/app_routes.dart';
import 'package:vsdk_example/utils/device_manager.dart';

import '../widget/slider_widget/slider_widget.dart';
import 'Settings_logic.dart';
import 'Settings_state.dart';

class SettingsPage extends GetView<SettingsLogic> {
  SettingsLogic? logic;
  SettingsState? state;

  @override
  Widget build(BuildContext context) {
    logic = controller;
    state = controller.state!;
    if (logic == null || state == null) return SizedBox();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Alarm Settings'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              return Column(
                children: [
                  ///运动侦测开关
                  motionDetectionSwitch(),

                  alarmSoundSwitch(),

                  ///人形判断开关，仅低功耗设备显示
                  Visibility(
                      visible: DeviceManager.getInstance()
                          .getDeviceModel()!
                          .isSupportLowPower
                          .value,
                      child: humanJudge()),

                  ///侦测距离设定, 运动侦测打开时才可设置
                  Visibility(
                      visible: state!.motionPushEnable.value != 0,
                      child: detectionRange()),

                  ///侦测频率，运动侦测打开时才可设置,（supportAI==1时不显示侦测频率，显示的是灵敏度)
                  Visibility(
                      visible: state!.motionPushEnable.value != 0 &&
                          DeviceManager.getInstance()
                                  .getDeviceModel()!
                                  .supportAI
                                  .value ==
                              0,
                      child: detectionFrequency()),

                  ///侦测灵敏度，运动侦测打开时才可设置,与侦测频率不会同时出现
                  Visibility(
                      visible: state!.motionPushEnable.value != 0 &&
                          DeviceManager.getInstance()
                                  .getDeviceModel()!
                                  .supportAI
                                  .value ==
                              1,
                      child: detectionSensitivity()),

                  ///报警闪光灯，运动侦测打开且设备有白光灯才可开关
                  Visibility(
                      visible: state!.motionPushEnable.value != 0 &&
                          DeviceManager.getInstance()
                              .getDeviceModel()!
                              .haveWhiteLight
                              .value,
                      child: alarmLightSwitch()),

                  ///云视频录像开关，只有低功耗人形侦测开启时才有该功能
                  Visibility(
                      visible: state!.motionPushEnable.value == 5 &&
                          DeviceManager.getInstance()
                              .getDeviceModel()!
                              .isSupportLowPower
                              .value,
                      child: cloudVideoSwitch()),

                  ///录制时长,只有云视频录像开关开启的时候显示
                  Visibility(
                      visible: state!.motionPushEnable.value == 5 &&
                          DeviceManager.getInstance()
                              .getDeviceModel()!
                              .isSupportLowPower
                              .value,
                      child: ObxValue<RxBool>((data) {
                        return data.value ? recordTimeWidget() : SizedBox();
                      }, state!.cloudVideoOpen)),

                  ///侦测区域绘制
                  Visibility(
                      visible: state!.motionPushEnable.value != 0,
                      child: detectAreaDraw()),

                  ///智能侦测定时
                  Visibility(
                      visible: DeviceManager.getInstance()
                              .deviceModel!
                              .smartdetecttime
                              .value !=
                          "0",
                      child: smartDetectTime()),
                ],
              );
            })),
      ),
    );
  }

  ///侦测灵敏度
  Widget detectionSensitivity() {
    logic?.initPut();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      alignment: Alignment.center,
      height: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("侦测灵敏度：", style: TextStyle(fontWeight: FontWeight.bold)),
          BottomSlider(isSensitity: true)
        ],
      ),
    );
  }

  ///侦测频率
  Widget detectionFrequency() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      alignment: Alignment.center,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("侦测频率：", style: TextStyle(fontWeight: FontWeight.bold)),
          detectionFrequencyItem()
        ],
      ),
    );
  }

  ///侦测距离调节：设备需支持PIR
  Widget detectionRange() {
    return Visibility(
      visible: DeviceManager.getInstance()
              .getDeviceModel()!
              .supportPirDistanceAdjust
              .value ==
          1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide()),
        ),
        height: 50,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("侦测距离：", style: TextStyle(fontWeight: FontWeight.bold)),
            detectionRangeItem()
          ],
        ),
      ),
    );
  }

  Widget humanJudge() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("人形判断：", style: TextStyle(fontWeight: FontWeight.bold)),
              humanJudgeItem()
            ],
          ),
          SizedBox(height: 6),
          Text("仅有人出现时触发报警，此功能可以提高报警准确度", style: TextStyle(color: Colors.grey))
        ],
      ),
    );
  }

  Widget motionDetectionSwitch() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("运动侦测：", style: TextStyle(fontWeight: FontWeight.bold)),
          motionDetectionItem()
        ],
      ),
    );
  }

  Widget motionDetectionItem() {
    String result = "已关闭 >>";
    if (state!.motionPushEnable.value == 1) {
      result = "移动侦测 >>";
    }
    if (state!.motionPushEnable.value == 5) {
      result = "人形侦测 >>";
    }
    return GestureDetector(
        onTap: () {
          logic!.clickChangeType();
        },
        child: Text(result, style: TextStyle(color: Colors.grey)));
  }

  Widget humanJudgeItem() {
    return GestureDetector(
        onTap: () {
          ///打开或关闭人形判断
          logic!.setHumanDetect(state!.humanJudge.value == true ? 0 : 1);
        },
        child: Text(state!.humanJudge.value == true ? "已开启 >>" : "已关闭 >>",
            style: TextStyle(color: Colors.grey)));
  }

  Widget detectionRangeItem() {
    String result = ">>";
    if (DeviceManager.getInstance().getDeviceModel()!.support_pir_level.value ==
        0) {
      if (state!.detectionRange.value == 1) {
        result = "近 >>";
      } else if (state!.detectionRange.value == 2) {
        result = "中 >>";
      } else if (state!.detectionRange.value == 3) {
        result = "远 >>";
      }
    }
    return GestureDetector(
        onTap: () {
          logic!.onDetectionRangeClick();
        },
        child: Text(result, style: TextStyle(color: Colors.grey)));
  }

  Widget detectionFrequencyItem() {
    String result = " 关闭 >>";
    if (state!.detectionFrequency.value == 3) {
      result = " 频繁 >>";
    } else if (state!.detectionFrequency.value == 2) {
      result = " 一般 >>";
    } else if (state!.detectionFrequency.value == 1) {
      result = " 定期 >>";
    }
    return GestureDetector(
        onTap: () {
          logic!.onDetectionFrequencyClick();
        },
        child: Text(result, style: TextStyle(color: Colors.grey)));
  }

  ///报警声设置
  Widget alarmSoundSwitch() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("报警声开关：", style: TextStyle(fontWeight: FontWeight.bold)),
          ObxValue<RxBool>((data) {
            return Switch(
                value: data.value,
                onChanged: (value) {
                  print("----------报警声-------Switch--$value--");
                  int voiceType = logic!.getVoiceType();
                  if (value) {
                    ///打开声音
                    logic!.setVoiceInfo(voiceType);
                  } else {
                    ///关闭声音
                    logic!.setVoice("", "无", 0, voiceType);
                  }
                });
          }, state!.alarmSoundOpen)
        ],
      ),
    );
  }

  ///报警闪光灯
  Widget alarmLightSwitch() {
    String name = " 关闭 >>";
    if (state!.alarmLightOpen.value) {
      name = " 已开启 >>";
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("报警闪光灯：", style: TextStyle(fontWeight: FontWeight.bold)),
          GestureDetector(
              onTap: () {
                ///打开或关闭报警闪光灯
                logic!.setAlarmLightSwitch(state!.alarmLightOpen.value ? 0 : 2);
              },
              child: Text(name, style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
  }

  ///云视频录像开关
  Widget cloudVideoSwitch() {
    String name = " 关闭 >>";
    if (state!.cloudVideoOpen.value) {
      name = " 已开启 >>";
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("云视频录像：", style: TextStyle(fontWeight: FontWeight.bold)),
          GestureDetector(
              onTap: () {
                ///打开或关闭云视频录像
                logic!.setCloudVideoSwitch(!state!.cloudVideoOpen.value);
              },
              child: Text(name, style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
  }

  ///侦测区域绘制
  Widget detectAreaDraw() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.areaDraw);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("侦测区域绘制：", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(">>", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }

  ///智能侦测定时
  Widget smartDetectTime() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          showSmartDetectTimeSheet();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("智能侦测定时：", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(">>", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }

  ///录制时长
  Widget recordTimeWidget() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("录制时长：", style: TextStyle(fontWeight: FontWeight.bold)),
          ObxValue<RxInt>((data) {
            return recordTimeItem(data.value);
          }, state!.recordTimeIndex)
        ],
      ),
    );
  }

  Widget recordTimeItem(int index) {
    String result = " 10秒";
    switch (index) {
      case 0:
        result = " 自动";
        break;
      case 1:
        result = " 5秒";
        break;
      case 2:
        result = " 10秒";
        break;
      case 3:
        result = " 15秒";
        break;
      case 4:
        result = " 30秒";
        break;
    }
    return GestureDetector(
        onTap: () {
          showRecordTimeSheet();
        },
        child: Text(result, style: TextStyle(color: Colors.grey)));
  }

  void showRecordTimeSheet() {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
              height: 300,
              margin: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(border: Border(top: BorderSide())),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Visibility(
                      visible: DeviceManager.getInstance()
                              .getDeviceModel()!
                              .supportAutoRecordMode
                              .value ==
                          2,
                      child: recordTimeSelectItem("自动", " (最长3分钟)", 0)),
                  Visibility(
                      visible: DeviceManager.getInstance()
                              .getDeviceModel()!
                              .supportAutoRecordMode
                              .value ==
                          2,
                      child: SizedBox(height: 20)),
                  recordTimeSelectItem("5秒", " (录制时长5秒)", 1),
                  SizedBox(height: 20),
                  recordTimeSelectItem("10秒", " (录制时长10秒)", 2),
                  SizedBox(height: 20),
                  recordTimeSelectItem("15秒", " (录制时长15秒)", 3),
                  SizedBox(height: 20),
                  recordTimeSelectItem("30秒", " (录制时长30秒)", 4),
                ],
              ));
        });
  }

  ///录制时长选项
  Widget recordTimeSelectItem(String name, String desc, int index) {
    return InkWell(
      onTap: () {
        controller.setRecordTime(index);
      },
      child: ObxValue<RxInt>((data) {
        return timeItem(name, desc, data.value == index);
      }, state!.recordTimeIndex),
    );
  }

  Widget timeItem(String name, String desc, bool isSelected) {
    return Row(
      children: [
        Icon(Icons.circle, color: isSelected ? Colors.blue : Colors.grey),
        SizedBox(
          width: 6,
        ),
        Text(name,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
        Text(desc,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400))
      ],
    );
  }

  ///智能侦测定时选项
  Widget smartDetectTimeItem(String name, String desc, int index) {
    return InkWell(
      onTap: () {
        controller.setSmartDetect(index);
      },
      child: ObxValue<RxInt>((data) {
        return timeItem(name, desc, data.value == index);
      }, state!.smartTimeIndex),
    );
  }

  ///智能侦测定时
  void showSmartDetectTimeSheet() {
    controller.initSmartTimePlan();
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
              height: 300,
              margin: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(border: Border(top: BorderSide())),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  smartDetectTimeItem("全天", " (全天24小时智能侦测)", 0),
                  SizedBox(height: 20),
                  smartDetectTimeItem("仅白天", " (早8:00-晚20:00启动)", 1),
                  SizedBox(height: 20),
                  smartDetectTimeItem("仅夜间", " (晚20:00-次日早8:00启动)", 2),
                  SizedBox(height: 20),
                  smartDetectTimeItem("自定义", " (自定义侦测时间段)", 3),
                  SizedBox(height: 30),
                  InkWell(
                      onTap: () {
                        //保存
                        controller.setMotionSmartDetectTime();
                      },
                      child: Text("保存"))
                ],
              ));
        });
  }
}
