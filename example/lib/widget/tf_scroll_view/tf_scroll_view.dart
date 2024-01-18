import 'package:flutter/material.dart';
import 'package:vsdk_example/widget/tf_scroll_view/tf_scroll_logic.dart';
import '../../model/record_file_model.dart';
import '../../tf_play/tf_play_logic.dart';
import '../../tf_play/tf_play_state.dart';
import '../../utils/app_page_view.dart';
import 'package:get/get.dart';

class TFScrollView<S> extends GetWidgetView<TFScrollLogic, S> {
  TFScrollView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TFScrollLogic logic = controller;
    TFPlayState state = logic.state!;

    return Expanded(
        child: ObxValue<Rx<List<RecordFileModel>>>((data) {
      return data.value.isEmpty
          ? Center(
              child: Text("请先确保已安装TF卡！"),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    RecordFileModel model = data.value[index];
                    return GestureDetector(
                        onTap: () {
                          state.playModel.value = model;
                          state.selectModel.value = model;
                          TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
                          tfPlayLogic.startVideo();
                        },
                        child: ObxValue<Rx<RecordFileModel?>>((data) {
                          return Container(
                              height: 50,
                              margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey, width: 1.0),
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: model == state.playModel.value
                                      ? Colors.blue[100]
                                      : Colors.white),
                              alignment: Alignment.center,
                              child: Row(
                                children: [
                                  Text(model.recordAlarm == 0
                                      ? " 实时录像："
                                      : model.recordAlarm == 1
                                          ? " 报警录像："
                                          : " 人形侦测："),
                                  Text(
                                      "${model.recordTime.year}-${model.recordTime.month}-${model.recordTime.day}"),
                                  SizedBox(width: 8),
                                  Text(
                                      "${model.recordTime.hour} : ${model.recordTime.minute} : ${model.recordTime.second}"),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                      onTap: () {
                                        TFPlayLogic tfPlayLogic =
                                            Get.find<TFPlayLogic>();
                                        tfPlayLogic.deleteRecordFile(
                                            model, false);
                                      },
                                      child: Text("  删除  "))
                                ],
                              ));
                        }, state.playModel));
                  },
                  itemCount: data.value.length),
            );
    }, state.recordFileModels));
  }
}
