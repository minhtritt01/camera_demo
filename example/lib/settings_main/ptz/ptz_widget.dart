import 'package:flutter/material.dart';
import 'package:vsdk_example/model/device_model.dart';
import 'package:vsdk_example/settings_main/ptz/ptz_logic.dart';
import 'package:get/get.dart';

class PTZWidget extends GetView<PTZLogic> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ObxValue<RxBool>((data) {
              return GestureDetector(
                  onTap: () {
                    controller.horizontalCruise(!data.value);
                  },
                  child: Text(
                    '水平巡航',
                    style: TextStyle(
                        color: data.value ? Colors.red : Colors.black),
                  ));
            }, controller.state!.isHorizontal),
            ObxValue<RxBool>((data) {
              return GestureDetector(
                  onTap: () {
                    controller.verticalCruise(!data.value);
                  },
                  child: Text('垂直巡航',
                      style: TextStyle(
                          color: data.value ? Colors.red : Colors.black)));
            }, controller.state!.isVertical),
            ObxValue<RxBool>((data) {
              return GestureDetector(
                  onTap: () {
                    controller.presetCruise(!data.value);
                  },
                  child: Text('常看位巡航',
                      style: TextStyle(
                          color: data.value ? Colors.red : Colors.black)));
            }, controller.state!.isCruising),
            ObxValue<RxBool>((data) {
              return GestureDetector(
                  onTap: () {
                    controller.ptzCorrect();
                  },
                  child: Text('云台矫正',
                      style: TextStyle(
                          color: data.value ? Colors.red : Colors.black)));
            }, controller.state!.isPtzAdjust),
          ],
        ),
        SizedBox(height: 20),
        Text("常看位："),
        SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.of(context).size.width / 5,
          child: ObxValue<RxList<PresetModel?>>((data) {
            List<PresetModel?> models = data.toList();
            return GridView.builder(
                itemCount: 5,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  PresetModel? model;
                  model = models[index];
                  return model == null
                      ? InkWell(
                          onTap: () {
                            ///点击了常看位
                            if (!controller.state!.isGuardEdit.value) {
                              controller.getPicAndSet(index);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1)),
                            child: Center(child: Text("${index + 1}")),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            if (controller.state!.isGuardEdit.value &&
                                controller.state!.guardIndex.value != index) {
                              ///设置看守卫
                              controller.setGuard(index);
                            } else if (controller.state!.isGuardEdit.value &&
                                controller.state!.guardIndex.value == index) {
                              ///删除看守卫
                              controller.setGuard(-1);
                            } else {
                              ///删除常看位
                              controller.deletePresetSnapshot(index);
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                child: model.isExist
                                    ? Image.file(
                                        model.file,
                                        fit: BoxFit.fill,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.asset('icons/preset_pic.png',
                                        fit: BoxFit.contain),
                              ),
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: ObxValue<RxInt>((data) {
                                    return data.value == index
                                        ? Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10))),
                                            child: Center(
                                                child: Text("${index + 1}",
                                                    style: TextStyle(
                                                        color: Colors.white))),
                                          )
                                        : SizedBox();
                                  }, controller.state!.guardIndex)),
                            ],
                          ),
                        );
                });
          }, controller.state!.presetData),
        ),
        ObxValue<RxBool>((data) {
          return data.value
              ? Text("请选择一个常看位作为看守卫",
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.w500))
              : SizedBox();
        }, controller.state!.isGuardEdit),
        SizedBox(height: 20),
        ObxValue<RxBool>((data) {
          return data.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("看守位："),
                    ObxValue<RxBool>((data) {
                      return InkWell(
                          onTap: () {
                            controller.setGuardEdit(!data.value);
                          },
                          child: Icon(Icons.edit,
                              color: data.value ? Colors.blue : Colors.grey));
                    }, controller.state!.isGuardEdit)
                  ],
                )
              : SizedBox();
        }, controller.state!.isSupportGuard)
      ],
    );
  }
}
