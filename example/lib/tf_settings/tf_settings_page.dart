import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk_example/tf_settings/tf_settings_logic.dart';
import 'package:vsdk_example/tf_settings/tf_settings_state.dart';
import '../utils/device_manager.dart';

class TFSettingsPage extends GetView<TFSettingsLogic> {
  @override
  Widget build(BuildContext context) {
    String status =
        DeviceManager.getInstance().mDevice!.recordResult.record_sd_status;
    String name = controller.getTFStatusName();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TF Settings'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: (status == "1" || status == "2")
            ? Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    recordTimeSetWidget(context), //录像时间设置
                    SizedBox(height: 10),
                    Divider(height: 1),
                    SizedBox(height: 10),
                    recordModeSetWidget(), //录像模式设置
                    recordAudioWidget(), //声音录制开关
                    SizedBox(height: 10),
                    Divider(height: 1),
                    SizedBox(height: 10),
                    InkWell(
                        onTap: () async {
                          bool bl = await controller.tfFormat();
                          if (bl) {
                            controller.state!.isFormating(true);
                            showChangeVideoFormatDialog(context);
                            controller.state!.times.value = 0;
                            controller.getTFStatus();
                          }
                        },
                        child: Container(
                            width: 120,
                            height: 46,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                color: Colors.blue),
                            alignment: Alignment.center,
                            child: Text("格式化")))
                  ],
                ),
              )
            : Center(child: Text(name)),
      ),
    );
  }

  Future<bool?> showChangeVideoFormatDialog(BuildContext context) {
    return showCupertinoDialog<bool>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: ObxValue<RxBool>((data) {
              return data.value ? Text('正在格式化') : Text('格式化完成！');
            }, controller.state!.isFormating),
            content: ObxValue<RxInt>((data) {
              return data.value > 0
                  ? Text('${3 * data.value} %, 请稍等。。。')
                  : Text('数据已删除！');
            }, controller.state!.times),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(
                  '确定',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () {
                  if (!controller.state!.isFormating.value) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  Widget recordAudioWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("录制声音："),
        ObxValue<RxBool>((data) {
          return Switch(
              value: data.value,
              onChanged: (value) {
                controller.setAudioSwitch(!data.value);
              });
        }, controller.state!.audioSwitch)
      ],
    );
  }

  Widget recordTimeSetWidget(BuildContext context) {
    return InkWell(
      onTap: () async {
        var resolution =
            await showTFRecordResolutionDialog(context, controller.state!);
        if (resolution != null && resolution != "cancel") {
          int value = int.parse(resolution);
          controller.setTFRecordResolution(value);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("录像时间"),
          ObxValue<RxInt>((data) {
            String text = "录像时间长";
            if (data.value == 0) {
              text = "录像时间超短";
            } else if (data.value == 1) {
              text = "录像时间短";
            } else if (data.value == 2) {
              text = "录像时间长";
            }
            return Text(
              "$text  >>",
              style: TextStyle(color: Colors.grey),
            );
          }, controller.state!.tfResolution),
        ],
      ),
    );
  }

  ///录像模式设置
  Widget recordModeSetWidget() {
    return Visibility(
        visible:
            DeviceManager.getInstance().deviceModel?.recordmod.value == "1",
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                showRecordModelSheet();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("录像模式"),
                  ObxValue<RxInt>((data) {
                    String text = "24小时录像";
                    if (data.value == 0) {
                      text = "24小时录像";
                    } else if (data.value == 1) {
                      text = "计划录像";
                    } else if (data.value == 2) {
                      text = "运动侦测录像";
                    } else if (data.value == 3) {
                      text = "不录像";
                    }
                    return Text(
                      "$text  >>",
                      style: TextStyle(color: Colors.grey),
                    );
                  }, controller.state!.recordModel),
                ],
              ),
            ),
            SizedBox(height: 10),
            ObxValue<RxInt>((data) {
              String customTime = controller.getPlanTime();
              return Visibility(
                  visible: data.value == 1,
                  child:
                      Text(customTime, style: TextStyle(color: Colors.grey)));
            }, controller.state!.recordModel),
            Divider(height: 1),
            SizedBox(height: 10)
          ],
        ));
  }

  ///录像分辨率
  Future<String?> showTFRecordResolutionDialog(
      BuildContext context, TFSettingsState state) {
    int selected = state.tfResolution.value;
    var hdName = '录像时间超短'.tr;
    var normalName = '录像时间短'.tr;
    var lowName = '录像时间长'.tr;
    return showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(hdName),
                onPressed: () {
                  Navigator.of(context).pop("0");
                },
                isDestructiveAction: selected == 0,
              ),
              CupertinoActionSheetAction(
                child: Text(normalName),
                onPressed: () {
                  Navigator.of(context).pop("1");
                },
                isDestructiveAction: selected == 1,
              ),
              CupertinoActionSheetAction(
                child: Text(lowName),
                onPressed: () {
                  Navigator.of(context).pop("2");
                },
                isDestructiveAction: selected == 2,
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                '取消'.tr,
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop("cancel");
              },
            ),
          );
        });
  }

  ///录像模式
  void showRecordModelSheet() {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
              height: 250,
              margin: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(border: Border(top: BorderSide())),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  recordModelItem("24小时录像", 0),
                  SizedBox(height: 20),
                  recordModelItem("计划录像", 1),
                  SizedBox(height: 20),
                  recordModelItem("运动侦测录像", 2),
                  SizedBox(height: 20),
                  recordModelItem("不录像", 3),
                ],
              ));
        });
  }

  Widget recordModelItem(String name, int index) {
    return InkWell(
        onTap: () {
          controller.setRecordMode(index);
        },
        child: ObxValue<RxInt>((data) {
          return Text(name,
              style: TextStyle(
                  color: data.value == index ? Colors.red : Colors.black));
        }, controller.state!.recordModel));
  }
}
