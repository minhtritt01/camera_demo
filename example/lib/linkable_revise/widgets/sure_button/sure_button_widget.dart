import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_page_view.dart';
import 'sure_button_logic.dart';

class SureButton<S> extends GetWidgetView<SureButtonLogic, S> {
  SureButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = controller;
    return Container(
      margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 15, bottom: 10),
      height: 44.0,

      ///width: buttonWidth,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: InkWell(
          onTap: logic.goDeviceRevise,
          child: Center(
            child: Text(
              '确定'.tr,
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          )),
    );
  }
}
