import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk_example/app_routes.dart';
import 'package:vsdk_example/play/play_logic.dart';
import 'package:vsdk_example/play/play_state.dart';
import 'package:vsdk_example/settings_main/settings_main.dart';
import 'package:vsdk_example/settings_main/settings_main_logic.dart';
import 'package:vsdk_example/settings_main/settings_main_state.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../main/main_logic.dart';
import '../model/device_model.dart';
import '../widget/focal_point_widget.dart';
import '../widget/scale_offset_widget.dart';
import '../widget/virtual_three_view.dart';
import 'app_player_slider.dart';
import 'app_extension.dart';

class PlayerPage extends GetView<PlayLogic> {
  late final PlayLogic logic;

  late final PlayState state;

  PlayerPage({super.key});

  Widget buildStartButton(PlayLogic logic, PlayState state) {
    return ObxValue<RxBool>((data) {
      print("RxBool videoStop ${data.value}");
      if (data.value == true) {
        return IconButton(
          icon: Icon(Icons.play_arrow),
          color: Colors.white,
          onPressed: () async {
            logic.startVideo();
          },
        );
      } else {
        return IconButton(
          icon: Icon(Icons.stop),
          color: Colors.white,
          onPressed: () async {
            logic.stopPlay();
          },
        );
      }
    }, state.videoStop);
  }

  Widget buildPlayButton(PlayLogic logic, PlayState state) {
    return ObxValue<RxBool>((data) {
      print("RxBool videoPause ${data.value}");
      if (data.value == true) {
        return IconButton(
          icon: Icon(Icons.play_circle_outline),
          color: Colors.white,
          onPressed: () {
            logic.controller?.resume();
            state.videoPause.value = false;
          },
        );
      } else {
        return IconButton(
          icon: Icon(Icons.pause_circle_outline),
          color: Colors.white,
          onPressed: () {
            logic.controller?.pause();
            state.videoPause.value = true;
          },
        );
      }
    }, state.videoPause);
  }

  Widget buildVoiceButton(PlayLogic logic, PlayState state) {
    return ObxValue<RxBool>((data) {
      print("RxBool videoVoiceStop ${data.value}");
      if (data.value) {
        return IconButton(
          icon: Icon(Icons.volume_off),
          color: Colors.white,
          onPressed: () {
            DeviceManager.getInstance().mDevice?.startSoundStream();
            logic.controller?.startVoice();
            state.videoVoiceStop.value = false;

            ///保存静音状态
            DeviceManager().setMonitorState(false);
          },
        );
      } else {
        return IconButton(
          icon: Icon(Icons.volume_up),
          color: Colors.white,
          onPressed: () {
            SettingsMainLogic settingsLogic = Get.find<SettingsMainLogic>();
            if (settingsLogic.state?.voiceState.value == VoiceState.play) {
              EasyLoading.showToast("正在对话中，无法关闭语音");
              return;
            }

            print(
                "DeviceManager.getInstance().mDevice ${DeviceManager.getInstance().mDevice}");

            DeviceManager.getInstance().mDevice?.stopSoundStream();
            logic.controller?.stopVoice();
            state.videoVoiceStop.value = true;
            //
            // ///保存静音状态
            // DeviceManager().setMonitorState(false);
          },
        );
      }
    }, state.videoVoiceStop);
  }

  //
  // bool save_flag = false;
  // int start;

  @override
  Widget build(BuildContext context) {
    logic = controller;
    state = logic.state!;
    int sensor = DeviceManager.getInstance()
            .deviceModel
            ?.supportMutilSensorStream
            .value ??
        0;
    print("-----build sensor-$sensor----------");
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Video Player'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            GestureDetector(
                onTap: () {
                  ///点击设置
                  Get.toNamed(AppRoutes.normalSetting);
                },
                child: Container(
                    width: 50, alignment: Alignment.center, child: Text("设置")))
          ],
        ),
        body: Stack(
          children: [
            sensor == 3
                ? buildThreePlay(context)
                : sensor == 1
                    ? buildTwoPlay(context)
                    : buildSinglePlayWidget(context),
            Visibility(
                visible: DeviceManager.getInstance()
                            .deviceModel!
                            .support_focus
                            .value >
                        0 ||
                    DeviceManager.getInstance()
                            .deviceModel!
                            .MaxZoomMultiple
                            .value >
                        0,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 30,
                      height: 300,
                      color: Colors.grey.shade400,
                      margin: EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("变"),
                          Text("倍"),
                          RotatedBox(
                            quarterTurns: -1,
                            child: ObxValue<RxInt>((data) {
                              return Slider(
                                min: 1.0,
                                max: (DeviceManager.getInstance()
                                            .deviceModel!
                                            .MaxZoomMultiple
                                            .value >
                                        0)
                                    ? (DeviceManager.getInstance()
                                        .deviceModel!
                                        .MaxZoomMultiple
                                        .value
                                        .toDouble())
                                    : 4.0,
                                divisions: (DeviceManager.getInstance()
                                            .deviceModel!
                                            .MaxZoomMultiple
                                            .value >
                                        0)
                                    ? (DeviceManager.getInstance()
                                            .deviceModel!
                                            .MaxZoomMultiple
                                            .value -
                                        1)
                                    : 3,
                                value: data.value.toDouble(),
                                onChanged: (value) {
                                  controller.setZoom(value.toInt());
                                },
                              );
                            }, controller.state!.zoomValue),
                          )
                        ],
                      ),
                    )))
          ],
        ),
      ),
    );
  }

  ///三目或假三目
  Widget buildThreePlay(BuildContext context) {
    print("------------buildThreePlay-------------");
    double width = MediaQuery.of(context).size.width / 2 - 5;
    double height = width * 9 / 16;
    bool split =
        DeviceManager.getInstance().deviceModel?.splitScreen.value == 1;
    return ObxValue<RxInt>((data) {
      return data.value == 2 || (data.value == 1 && split)
          ? Column(
              children: [
                SizedBox(height: 10),
                Text("追踪球机"),
                SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                  child: Stack(
                    children: [
                      InkWell(
                          onTap: () {
                            ///点击了球机
                            state.select(0);
                          },
                          child: ObxValue<RxInt>((data) {
                            return Container(
                              decoration: BoxDecoration(
                                  border: data.value == 0
                                      ? Border.all(color: Colors.red, width: 2)
                                      : null),
                              child: AppPlayerView(
                                controller: state.playerController!,
                              ),
                            );
                          }, state.select)),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black54,
                          child: Row(
                            children: [
                              buildStartButton(logic, state),
                              buildPlayButton(logic, state),
                              buildVoiceButton(logic, state),
                            ],
                          ),
                        ),
                      ),
                      RecordProgressWidget(state: state)
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text("全景枪机"),
                SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        ///点击第一个枪机
                        state.select(1);
                      },
                      child: ObxValue<RxInt>((data) {
                        return Container(
                          width: width,
                          decoration: BoxDecoration(
                              border: data.value == 1
                                  ? Border.all(color: Colors.red, width: 2)
                                  : null),
                          child: AspectRatio(
                              aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                              child: split
                                  ? ScaleOffsetView(
                                      notifier: logic.videoScaleNotifierFirst!,
                                      supportBinocular:
                                          DeviceManager.getInstance()
                                              .deviceModel!
                                              .supportBinocular
                                              .value,
                                      child: VirtualThreeView(
                                        child: AppPlayerView(
                                          controller:
                                              state.player2Controller!, //假三目
                                        ),
                                        alignment: Alignment.centerLeft,
                                        width: width,
                                        height: height,
                                      ),
                                    )
                                  : ScaleOffsetView(
                                      notifier: logic.videoScaleNotifierFirst!,
                                      supportBinocular:
                                          DeviceManager.getInstance()
                                              .deviceModel!
                                              .supportBinocular
                                              .value,
                                      child: AppPlayerView(
                                        controller:
                                            state.player2Controller!, //真三目
                                      ),
                                    )),
                        );
                      }, state.select),
                    ),
                    SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        ///点击了第二个枪机
                        state.select(2);
                      },
                      child: ObxValue<RxInt>((data) {
                        return Container(
                          width: MediaQuery.of(context).size.width / 2 - 5,
                          decoration: BoxDecoration(
                              border: data.value == 2
                                  ? Border.all(color: Colors.red, width: 2)
                                  : null),
                          child: AspectRatio(
                              aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                              child: split
                                  ? ScaleOffsetView(
                                      notifier: logic.videoScaleNotifierSecond!,
                                      supportBinocular:
                                          DeviceManager.getInstance()
                                              .deviceModel!
                                              .supportBinocular
                                              .value,
                                      child: VirtualThreeView(
                                        child: AppPlayerView(
                                          controller:
                                              state.player2Controller!, //假三目
                                        ),
                                        alignment: Alignment.centerRight,
                                        width: width,
                                        height: height,
                                      ),
                                    )
                                  : ScaleOffsetView(
                                      notifier: logic.videoScaleNotifierSecond!,
                                      supportBinocular:
                                          DeviceManager.getInstance()
                                              .deviceModel!
                                              .supportBinocular
                                              .value,
                                      child: AppPlayerView(
                                        controller:
                                            state.player3Controller!, //真三目
                                      ),
                                    )),
                        );
                      }, state.select),
                    )
                  ],
                ),
                SizedBox(height: 20),
                ScaleButtonWidget(logic: logic),
                Container(
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).size.width * 9 / 16 -
                        MediaQuery.of(context).size.width / 2 * 9 / 16 -
                        MediaQuery.of(context).padding.top -
                        180,
                    child: SingleChildScrollView(child: SettingsMain()))
              ],
            )
          : Container();
    }, state.hasSubPlay);
  }

  ///双目
  Widget buildTwoPlay(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return ObxValue<RxInt>((data) {
      return data.value == 1
          ? Column(
              children: [
                Text("追踪球机"),
                Container(
                  color: Colors.black,
                  height: 250,
                  child: Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                          child: AppPlayerView(
                            controller: logic.controller!,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          color: Colors.black54,
                          child: ObxValue<RxInt>((data) {
                            return Text(
                              "${(data.value / 1024.0).toStringAsFixed(2)}KB/s",
                              style: Theme.of(context)
                                  .textTheme
                                  .button
                                  ?.apply(color: Colors.white),
                            );
                          }, state.velocity ?? RxInt(0)),
                        ),
                      ),

                      ///视频加载中
                      StartingWaveWidget(state: state),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black54,
                          child: Row(
                            children: [
                              buildStartButton(logic, state),
                              buildPlayButton(logic, state),
                              buildVoiceButton(logic, state),
                            ],
                          ),
                        ),
                      ),

                      ///重连提示
                      // ReConnectWidget(logic: logic, deviceModel: deviceModel),
                      ///录制计时
                      RecordProgressWidget(state: state)
                    ],
                  ),
                ),
                Text("全景枪机"),
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                      child: AppPlayerView(
                        controller: state.player2Controller!,
                      ),
                    ),
                    ObxValue<RxBool>((data) {
                      return data.value
                          ? Visibility(
                              visible: (DeviceManager.getInstance()
                                          .deviceModel!
                                          .supportPinInPic
                                          .value ==
                                      1 ||
                                  DeviceManager.getInstance()
                                          .deviceModel!
                                          .supportMutilSensorStream
                                          .value ==
                                      1),
                              child: FocalPointWidget(
                                width / 2,
                                width * 9 / 16 / 2 - 20,
                                Colors.red,
                                onDragEndListener: (x, y) {
                                  print("-----x-$x-----y-$y----");
                                  logic.linkable(x, y);
                                },
                              ))
                          : SizedBox();
                    }, state.isLinkableOpen),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).size.width * 9 / 16 * 2 -
                      MediaQuery.of(context).padding.top -
                      150,
                  child: SingleChildScrollView(
                    child: SettingsMain(),
                  ),
                )
              ],
            )
          : Container();
    }, state.hasSubPlay);
  }

  ///单目
  Widget buildSinglePlayWidget(BuildContext context) {
    var deviceModel = DeviceManager.getInstance().deviceModel;
    return Column(
      children: [
        Container(
          color: Colors.black,
          height: 250,
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                  child: AppPlayerView(
                    controller: logic.controller!,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  color: Colors.black54,
                  child: ObxValue<RxInt>((data) {
                    return Text(
                      "${(data.value / 1024.0).toStringAsFixed(2)}KB/s",
                      style: Theme.of(context)
                          .textTheme
                          .button
                          ?.apply(color: Colors.white),
                    );
                  }, state.velocity ?? RxInt(0)),
                ),
              ),

              ///视频加载中
              StartingWaveWidget(state: state),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black54,
                  child: Row(
                    children: [
                      buildStartButton(logic, state),
                      buildPlayButton(logic, state),
                      buildVoiceButton(logic, state),
                      /*   Expanded(
                              child: ProgressBar(
                            controller: _controller,
                          )),*/
                    ],
                  ),
                ),
              ),

              ///重连提示
              // ReConnectWidget(logic: logic, deviceModel: deviceModel),

              ///录制计时
              RecordProgressWidget(state: state)
            ],
          ),
        ),
        SizedBox(height: 10),
        SettingsMain()
      ],
    );
  }
}

class ScaleButtonWidget extends StatelessWidget {
  const ScaleButtonWidget({
    super.key,
    required this.logic,
  });

  final PlayLogic logic;

  @override
  Widget build(BuildContext context) {
    return ObxValue<RxInt>((data) {
      return data.value == 0
          ? SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                    onTap: () {
                      logic.addScaleOffset();
                    },
                    child: Text("   +   ")),
                Text("  变倍  "),
                InkWell(
                    onTap: () {
                      logic.reduceScaleOffset();
                    },
                    child: Text("   -   ")),
              ],
            );
    }, logic.state!.select);
  }
}

class StartingWaveWidget extends StatelessWidget {
  const StartingWaveWidget({
    super.key,
    required this.state,
  });

  final PlayState state;

  @override
  Widget build(BuildContext context) {
    return ObxValue<Rx<VideoStatus>>((data) {
      if (data.value == VideoStatus.STARTING) {
        return Center(
            child: SpinKitWave(
          color: Colors.white,
          size: 32,
        ));
      } else {
        return SizedBox();
      }
    }, state.videoStatus);
  }
}

class ReConnectWidget extends StatelessWidget {
  const ReConnectWidget({
    super.key,
    required this.logic,
    required this.deviceModel,
  });

  final PlayLogic logic;
  final DeviceModel? deviceModel;

  @override
  Widget build(BuildContext context) {
    return ObxValue<Rx<DeviceConnectState>>((data) {
      if (data.value == DeviceConnectState.disconnect ||
          data.value == DeviceConnectState.timeout) {
        return Center(
            child: InkWell(
          onTap: () {
            ///重新连接
            MainLogic mainLogic = Get.find<MainLogic>();
            mainLogic
                .connectDevice(DeviceManager.getInstance().mDevice!)
                .then((v) {
              if (v) {
                print("连接成功，开始播放！");
                logic.start(DeviceManager.getInstance().mDevice!);
              }
            });
          },
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(6),
            child: Text("连接超时或未连接，点击重连", style: TextStyle(color: Colors.blue)),
          ),
        ));
      } else {
        return SizedBox();
      }
    }, deviceModel!.connectState);
  }
}

class RecordProgressWidget extends StatelessWidget {
  const RecordProgressWidget({
    super.key,
    required this.state,
  });

  final PlayState state;

  @override
  Widget build(BuildContext context) {
    return ObxValue<RxBool>((data) {
      return Visibility(
        visible: data.value,
        child: ObxValue<RxInt>((data) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Container(
              color: Colors.white,
              child: Text("正在录制中。。。 ${data.value}  ",
                  style: TextStyle(color: Colors.red)),
            ),
          );
        }, state.recordProgress),
      );
    }, state.videoRecord);
  }
}

class ProgressBar extends StatefulWidget {
  const ProgressBar({required Key key, required this.controller})
      : super(key: key);
  final AppPlayerController controller;

  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  int totalSec = 0, playSec = 0, loadProgress = 0, loadState = 0, velocity = 0;

  void progressCallback(
      userData, totalSec, playSec, loadProgress, loadState, velocity) {
    print(
        "totalSec:$totalSec playSec:$playSec loadProgress:$loadProgress loadState:$loadState velocity:$velocity ");
    setState(() {
      this.totalSec = totalSec;
      this.playSec = playSec;
      this.loadProgress = loadProgress;
      this.loadState = loadState;
      this.velocity = velocity;
    });
  }

  @override
  void initState() {
    widget.controller.addProgressChangeCallback(progressCallback);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeProgressChangeCallback(progressCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var sliderTheme = SliderTheme.of(context).copyWith(
        trackHeight: 2,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6));

    var textStyle = TextStyle(fontSize: 10.0, color: Colors.white);
    int value = playSec;
    int total = totalSec;
    var startText =
        "${(value ~/ 60).toStringDigits(2)}:${(value % 60).toStringDigits(2)}";
    var endText =
        "${(total ~/ 60).toStringDigits(2)}:${(total % 60).toStringDigits(2)}";
    double loadProgress = this.loadProgress / 100;
    return SliderTheme(
      data: sliderTheme,
      child: Container(
        height: 30,
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(startText, style: textStyle),
            ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 8),
                    child: Center(
                      child: LinearProgressIndicator(
                        value: loadProgress,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                  AppPlayerSlider(
                    totalValue:
                        totalSec ~/ (loadProgress == 0 ? 1 : loadProgress),
                    currentValue: playSec,
                    onChanged: (change) {
                      print(change);
                      widget.controller.setProgress(change.toInt());
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(endText, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}
