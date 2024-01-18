import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_page_view.dart';
import '../focal_pointa_widget.dart';
import 'camera_one_logic.dart';

class CameraOne<S> extends GetWidgetView<CameraOneLogic, S> {
  CameraOne({Key? key}) : super(key: key);

  Widget _maskBuilder({
    double? width,
    double? height,
    required double top,
    required double left,
    double? bottom,
    double? right,
    BlendMode? backgroundBlendMode,
    BorderRadiusGeometry? borderRadiusGeometry,
    Widget? child,
  }) {
    final decoration = BoxDecoration(
      color: Colors.white,
      backgroundBlendMode: backgroundBlendMode,
      borderRadius: borderRadiusGeometry,
    );
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      child: AnimatedContainer(
        decoration: decoration,
        width: width,
        height: height,
        child: child,
        duration: Duration(milliseconds: 300),
      ),
      top: top,
      left: left,
      bottom: bottom,
      right: right,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = controller;
    final state = controller.state;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    double width = MediaQuery.of(context).size.width - 40;
    double height = width * 9 / 16;
    double tmpW = (MediaQuery.of(context).size.width) / 2 - 20;
    return Container(
      margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 15, bottom: 10),
      width: MediaQuery.of(context).size.width - 4,
      height: width * 9 / 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17.0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          ObxValue<Rx<File?>>((data) {
            return data.value == null
                ? Container()
                : Image.file(
                    data.value!,
                    fit: BoxFit.cover,
                  );
          }, state!.backgroundImageA),
          /*Container(
            color: Colors.grey.withOpacity(0.6),
          ),*/

          // ColorFiltered(
          //   colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          //   child: Stack(
          //     children: [
          //       Container(
          //         width: width,
          //         height: width * 9 / 16,
          //         color: Colors.transparent,
          //         child: Center(
          //           child: IconButton(
          //             padding: EdgeInsets.zero,
          //             iconSize: 100,
          //             icon: ClipOval(
          //               clipBehavior: Clip.antiAlias,
          //               child: _maskBuilder(
          //                 width: 80,
          //                 height: 80,
          //                 left: width / 2 - 70,
          //                 top: width * 9 / 16 / 2 - 50,
          //               ),
          //             ),
          //             onPressed: () {},
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          FocalPointAWidget(
            tmpW,
            tmpW * 9 / 16,
            Colors.blue,
          ),
        ],
      ),
    );
  }
}
