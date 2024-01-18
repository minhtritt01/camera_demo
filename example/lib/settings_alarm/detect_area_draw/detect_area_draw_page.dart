import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';

import '../../utils/device_manager.dart';
import '../../widget/other/grid_painter_widget.dart';
import 'detect_area_draw_logic.dart';

class DetectAreaDrawPage extends GetView<DetectAreaDrawLogic> {
  @override
  Widget build(BuildContext context) {
    double aWidth = MediaQuery.of(context).size.width;
    double aHeight = aWidth * 9 / 16;
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('侦测区域绘制'),
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: Column(
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                      child: AppPlayerView(
                        controller: DeviceManager.getInstance().controller!,
                      ),
                    ),
                    Obx(() {
                      return GridPainter(aWidth, aHeight, (data) {
                        ///保存数据
                        controller.save(data);
                      }, controller.state!.gridState.value);
                    })
                  ],
                )
              ],
            )));
  }
}
