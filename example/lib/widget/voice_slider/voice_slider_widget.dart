import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk_example/widget/voice_slider/voice_slider_logic.dart';

class VoiceSliderWidget extends GetView<VoiceSliderLogic> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: 20),
          Text("麦克风："),
          ObxValue<RxDouble>((data) {
            return Slider(
              min: 0,
              max: 31,
              divisions: 100,
              value: data.value.toDouble(),
              onChanged: (value) {
                controller.state!.microphoneVoice.value = value.toDouble();
              },
            );
          }, controller.state!.microphoneVoice),
          SizedBox(height: 12),
          Text("喇叭："),
          ObxValue<RxDouble>((data) {
            return Slider(
              min: 0,
              max: 31,
              divisions: 100,
              value: data.value.toDouble(),
              onChanged: (value) {
                controller.state!.hornVoice.value = value.toDouble();
              },
            );
          }, controller.state!.hornVoice),
          SizedBox(height: 12),
          GestureDetector(
              onTap: () {
                controller.saveVolume();
                Get.back();
              },
              child: Text("保存")),
        ],
      ),
    );
  }
}
