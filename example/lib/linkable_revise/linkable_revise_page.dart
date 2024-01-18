import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk_example/linkable_revise/widgets/camera_one/camera_one_widget.dart';
import 'package:vsdk_example/linkable_revise/widgets/camera_two/camera_two_widget.dart';
import 'package:vsdk_example/linkable_revise/widgets/reset_button/reset_button_widget.dart';
import 'package:vsdk_example/linkable_revise/widgets/sure_button/sure_button_widget.dart';

import 'linkable_revise_logic.dart';
import 'linkable_revise_state.dart';

class LinkableRevisePage extends GetView<LinkableReviseLogic> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('联动校正'),
          centerTitle: true,
        ),
        body: ObxValue<RxBool>((data) {
          return data.value
              ? _buildLinkableReviseDone()
              : _buildLinkableRevise();
        }, controller.state!.linkableReviseDone));
  }

  Widget _buildLinkableReviseDone() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Divider(
              height: 1,
            ),
            Text("请将\"校正位\"中的光标拖动到与\"参考位\"中圈出的画面相同的位置,点击确定按钮完成校正."),
            Text("(如果两图圈出位置已经一致,则可直接点击确定)"),
            CameraOne<LinkableReviseState>(),
            Text(
              "参考位",
              style: TextStyle(fontSize: 16),
            ),
            CameraTwo<LinkableReviseState>(),
            Text(
              "校正位",
              style: TextStyle(fontSize: 16),
            ),
            ResetButton<LinkableReviseState>(),
            SureButton<LinkableReviseState>(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkableRevise() {
    return ObxValue<RxBool>((data) {
      return data.value
          ? Center(
              child: Text("联动校正中。。。。请等待"),
            )
          : SizedBox();
    }, controller.state!.isLinkableRevising);
  }
}
