import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/number_util.dart';
import 'custom_detect_time_logic.dart';
import 'custom_detect_time_state.dart';

class CustomDetectTimePage extends GetView<CustomDetectTimeLogic> {
  @override
  Widget build(BuildContext context) {
    double aWidth = MediaQuery.of(context).size.width;
    double aHeight = aWidth * 9 / 16;
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('自定义侦测时间'),
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      showTimeSelectWidget(true);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("开始时间"),
                        ObxValue<RxInt>((data) {
                          String selectedHour = twoDigits(data.value);
                          String selectedMinute =
                              twoDigits(controller.state!.startMinute.value);
                          return Text("$selectedHour : $selectedMinute  >>");
                        }, controller.state!.startHour)
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(height: 1),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      showTimeSelectWidget(false);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("结束时间"),
                        ObxValue<RxInt>((data) {
                          String selectedHour = twoDigits(data.value);
                          String selectedMinute =
                              twoDigits(controller.state!.endMinute.value);
                          return Text("$selectedHour : $selectedMinute  >>");
                        }, controller.state!.endHour)
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(height: 1),
                  SizedBox(height: 10),
                  Text("一周中的几天："),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      dayWidget("周日", 7, controller.state!),
                      dayWidget("周一", 1, controller.state!),
                      dayWidget("周二", 2, controller.state!),
                      dayWidget("周三", 3, controller.state!),
                      dayWidget("周四", 4, controller.state!),
                      dayWidget("周五", 5, controller.state!),
                      dayWidget("周六", 6, controller.state!),
                    ],
                  ),
                  SizedBox(height: 50),
                  InkWell(
                      onTap: () {
                        controller.save();
                      },
                      child: Text("保存"))
                ],
              ),
            )));
  }

  Widget dayWidget(String day, int index, CustomDetectTimeState state) {
    return InkWell(
      onTap: () {
        if (state.days.contains(index)) {
          state.days.remove(index);
        } else {
          state.days.add(index);
        }
      },
      child: ObxValue<RxList<int>>((data) {
        return Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(20),
              color: data.contains(index) ? Colors.blue : Colors.white),
          child: Text(day),
        );
      }, state.days),
    );
  }

  void showTimeSelectWidget(bool isStart) {
    var tempHour = isStart ? 0 : 23;
    var tempMinute = isStart ? 0 : 59;
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 15,
                    height: 50,
                  ),
                  InkWell(
                    child: Text(
                      '取消'.tr,
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    onTap: () {
                      Get.back();
                    },
                  ),
                  Spacer(),
                  InkWell(
                    child: Text(
                      '完成'.tr,
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                    onTap: () {
                      if (isStart) {
                        controller.state!.startHour.value = tempHour;
                        controller.state!.startMinute.value = tempMinute;
                      } else {
                        controller.state!.endHour.value = tempHour;
                        controller.state!.endMinute.value = tempMinute;
                      }
                      Get.back();
                    },
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
              Divider(
                height: 1,
              ),
              Container(
                ///width: 300,
                alignment: Alignment.center,
                height: 250,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      child: CupertinoPicker(
                        itemExtent: 45,
                        onSelectedItemChanged: (index) {
                          print('The start hour index is $index');
                          tempHour = index;
                        },
                        children: _hourWiget(context, controller.state!),
                        looping: true,
                        scrollController: FixedExtentScrollController(
                            initialItem: isStart ? 0 : 23),
                        squeeze: 1.1,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      width: 40,
                      child: CupertinoPicker(
                        itemExtent: 45,
                        onSelectedItemChanged: (index) {
                          print('The start minute index is $index');
                          tempMinute = index;
                        },
                        children: _minuteWiget(context, controller.state!),
                        looping: true,
                        scrollController: FixedExtentScrollController(
                            initialItem: isStart ? 0 : 59),
                        squeeze: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  List<Widget> _hourWiget(BuildContext context, CustomDetectTimeState state) {
    List<Widget> _wigets = [];
    for (int i in state.hours) {
      _wigets.add(Container(
        alignment: Alignment.center,
        child: Text(
          twoDigits(i),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ));
    }
    return _wigets;
  }

  List<Widget> _minuteWiget(BuildContext context, CustomDetectTimeState state) {
    List<Widget> _wigets = [];
    for (int i in state.minutes) {
      _wigets.add(Container(
        alignment: Alignment.center,
        child: Text(
          twoDigits(i),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ));
    }
    return _wigets;
  }
}
