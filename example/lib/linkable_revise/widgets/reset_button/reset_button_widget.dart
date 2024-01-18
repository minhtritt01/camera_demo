import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_page_view.dart';
import 'reset_button_logic.dart';

class ResetButton<S> extends GetWidgetView<ResetButtonLogic, S> {
  ResetButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = controller;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 15, bottom: 10),
          height: 44.0,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 22.0, right: 22.0, top: 17, bottom: 12),
          height: 40.0,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: InkWell(
              onTap: logic.retRevise,
              child: Center(
                child: Text(
                  '复位'.tr,
                  style: TextStyle(fontSize: 15, color: Colors.blue),
                ),
              )),
        )
      ],
    );
  }
}
