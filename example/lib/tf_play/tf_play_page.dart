import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk_example/tf_play/tf_play_logic.dart';
import 'package:vsdk_example/tf_play/tf_play_state.dart';

import '../utils/device_manager.dart';
import '../widget/tf_scroll_view/tf_scroll_view.dart';
import '../widget/virtual_three_view.dart';

class TFPlayPage extends GetView<TFPlayLogic> {
  @override
  Widget build(BuildContext context) {
    TFPlayLogic logic = controller;
    TFPlayState state = logic.state!;
    int splitScreen =
        DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;
    double width = MediaQuery.of(context).size.width / 2 - 5;
    double height = width * 9 / 16;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TF Play'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[];
          },
          body: Column(
            children: [
              Container(
                  height: MediaQuery.of(context).size.width * 9 / 16,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                          child: AppPlayerView(
                            controller: logic.controller,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            ObxValue<Rx<VideoStatus>>((data) {
                              return IconButton(
                                icon: data.value == VideoStatus.PLAY
                                    ? Icon(Icons.stop)
                                    : Icon(Icons.play_arrow),
                                color: Colors.white,
                                onPressed: () async {
                                  if (data.value == VideoStatus.STOP) {
                                    ///开始播放
                                    logic.startVideo();
                                  } else if (data.value == VideoStatus.PLAY) {
                                    ///暂停播放
                                    logic.pauseVideo();
                                  } else if (data.value == VideoStatus.PAUSE) {
                                    ///恢复
                                    logic.resumeVideo();
                                  }
                                },
                              );
                            }, state.videoStatus)
                          ],
                        ),
                      ),
                    ],
                  )),

              ///二目
              ObxValue<RxInt>((data) {
                return (data.value == 1 && splitScreen != 1)
                    ? AspectRatio(
                        aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                        child: AppPlayerView(
                          controller: state.tfPlayer2Controller!,
                        ),
                      )
                    : SizedBox();
              }, state.tfHasSubPlay),
              SizedBox(height: 10),

              ///三目或假三目
              ObxValue<RxInt>((data) {
                return (data.value == 1 && splitScreen == 1) //假三目
                    ? _VirtualThreeWidget(
                        height: height, state: state, width: width)
                    : data.value == 2 //真三目
                        ? _ThreeWidget(state: state)
                        : SizedBox();
              }, state.tfHasSubPlay),

              ///列表
              TFScrollView<TFPlayState>(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreeWidget extends StatelessWidget {
  const _ThreeWidget({
    super.key,
    required this.state,
  });

  final TFPlayState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
          child: AppPlayerView(
            controller: state.tfPlayer2Controller!, //假三目
          ),
        ),
        SizedBox(width: 10),
        AspectRatio(
          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
          child: AppPlayerView(
            controller: state.tfPlayer3Controller!, //假三目
          ),
        ),
      ],
    );
  }
}

class _VirtualThreeWidget extends StatelessWidget {
  const _VirtualThreeWidget({
    super.key,
    required this.height,
    required this.state,
    required this.width,
  });

  final double height;
  final TFPlayState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: Row(
        children: [
          VirtualThreeView(
            child: AppPlayerView(
              controller: state.tfPlayer2Controller!, //假三目
            ),
            alignment: Alignment.centerLeft,
            width: width,
            height: height,
          ),
          SizedBox(width: 10),
          VirtualThreeView(
            child: AppPlayerView(
              controller: state.tfPlayer2Controller!, //假三目
            ),
            alignment: Alignment.centerRight,
            width: width,
            height: height,
          ),
        ],
      ),
    );
  }
}
