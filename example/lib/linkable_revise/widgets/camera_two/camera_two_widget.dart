import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_page_view.dart';
import '../focalb_point_widget.dart';
import 'camera_two_logic.dart';

class CameraTwo<S> extends GetWidgetView<CameraTwoLogic, S> {
  CameraTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = controller;
    final state = controller.state!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    double width = MediaQuery.of(context).size.width - 40;
    double height = width * 9 / 16;

    double tmpW = (MediaQuery.of(context).size.width) / 2;

    return Obx(() {
      if (state.uiImageB.value == null) {
        return Container(
          width: width,
          height: height,
        );
      }
      return Stack(
        children: [
          Container(
            margin:
                EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
            /*  width: MediaQuery.of(context).size.width - 4,
                  height: width * 9 / 16,*/
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.0),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.file(
              state.backgroundImageB.value!,
              fit: BoxFit.cover,
            ),
          ),
          Obx(() {
            if (state.moveBtip.value == true) {
              return Container(
                margin: EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10, bottom: 10),
                width: MediaQuery.of(context).size.width - 40,
                height: width * 9 / 16,

                ///color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "icons/revise_b_tip.png",
                        width: 80,
                        height: 80,
                      ),
                      Text(
                        '按住拖动'.tr,
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
            return FocalPointBWidget(
              tmpW,
              tmpW * 9 / 16,
              Colors.blue,
              image: state.uiImageB.value!,
              isReSet: state.isRet.value,
              onPressEndListener: (xPercent, yPercent) async {
                state.xPercent.value = xPercent;
                state.yPercent.value = yPercent;
              },
            );
          }),
        ],
      );
    });
  }
}
