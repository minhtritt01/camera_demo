import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk_example/widget/slider_widget/slider_logic.dart';

import '../../settings_alarm/Settings_state.dart';

class BottomSlider extends GetView<SliderLogic> {
  bool isSensitity;

  BottomSlider({Key? key, this.isSensitity = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SettingsState state = controller.state!;
    return ObxValue<RxInt>((data) {
      if (data.value == 0) {
        return Container(
          height: 60,
          margin: EdgeInsets.only(left: 15, right: 15),
          alignment: Alignment.center,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ),
        );
      }
      return Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 10),
            ),
            Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isSensitity ? "低" : "近"),
                  Text("中"),
                  Text(isSensitity ? "高" : "远"),
                ],
              ),
            ),
            Container(
              child: Slider(
                min: 1,
                max: 3,
                divisions: 2,
                value: data.value.toDouble(),
                onChanged: (value) {
                  print("value:${value.toInt()}");
                  isSensitity
                      ? controller.setSensitivity(value.toInt())
                      : controller.setDetectionRange(value.toInt());
                },
              ),
            )
          ],
        ),
      );
    }, isSensitity ? state.sensitivity : state.detectionRange);
  }
}
