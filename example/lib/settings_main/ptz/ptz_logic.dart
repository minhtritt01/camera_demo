import 'dart:async';
import 'dart:io';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/status_command.dart';
import 'package:vsdk_example/model/device_model.dart';
import 'package:vsdk_example/utils/device_manager.dart';

import '../../model/plan_model.dart';
import '../settings_main_logic.dart';
import '../settings_main_state.dart';
import '../../utils/super_put_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PTZLogic extends SuperPutController<SettingsMainState> {
  Timer? _queryTimer; //查询灯的状态
  int count = 0;
  bool flag = false;

  PTZLogic(SettingsMainState state) {
    value = state;
  }

  @override
  void onInit() {
    print("-----------PTZLogic----------onInit---------------------");
    getAllStatus();
    getApplicationDocumentsDirectory().then((dir) {
      String did = DeviceManager.getInstance().mDevice!.id;

      ///获取保存的预置位快照
      savePresetModels(dir, did);
    });
    getKanShou();
    super.onInit();
  }

  void startQueryStatusTimer() {
    stopQueryStatusTimer();
    count = 0;
    flag = false;
    _queryTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      count++;
      getAllStatus();
    });
  }

  void stopQueryStatusTimer() {
    if (_queryTimer != null) {
      _queryTimer!.cancel();
      _queryTimer = null;
    }
  }

  void getAllStatus() async {
    StatusResult? result =
        await DeviceManager.getInstance().mDevice?.getStatus(cache: false);
    if (result != null) {
      if (result.preset_cruise_status_v == null ||
          result.preset_cruise_status_h == null ||
          result.preset_cruise_status == null ||
          result.center_status == null) {
        stopQueryStatusTimer();
        return;
      }

      print("ptz status ${result.toString()}");
      if (result.preset_cruise_status_v == "1") {
        state?.isVertical.value = true;
      } else if (result.preset_cruise_status_v == "0") {
        state?.isVertical.value = false;
        flag = true;
      }

      if (result.preset_cruise_status_h == "1") {
        state?.isHorizontal.value = true;
      } else if (result.preset_cruise_status_h == "0") {
        state?.isHorizontal.value = false;
        flag = true;
      }

      if (result.preset_cruise_status == "1") {
        state?.isCruising.value = true;
      } else if (result.preset_cruise_status == "0") {
        state?.isCruising.value = false;
        flag = true;
      }

      if (result.center_status == "1") {
        state?.isPtzAdjust.value = true;
      } else if (result.center_status == "0") {
        state?.isPtzAdjust.value = false;
        flag = true;
      }
    }

    ///查询超过10分钟，或者查询到状态为0，停止查询
    if (flag || count > 600) {
      stopQueryStatusTimer();
    }
  }

  ///水平巡航
  void horizontalCruise(bool isStart) async {
    if (state == null) return;
    if (isStart) {
      if (state!.isVertical.value ||
          state!.isHorizontal.value ||
          state!.isPtzAdjust.value ||
          state!.isCruising.value) {
        return;
      }
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.startLeftAndRight() ??
          false;
      print("horizontalCruise start $result");
      startQueryStatusTimer();
    } else {
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.stopLeftAndRight() ??
          false;
      print("horizontalCruise stop $result");
      if (result) {
        state?.isHorizontal.value = false;
      }
    }
  }

  ///垂直巡航
  void verticalCruise(bool isStart) async {
    if (isStart) {
      if (state!.isVertical.value ||
          state!.isHorizontal.value ||
          state!.isPtzAdjust.value ||
          state!.isCruising.value) {
        return;
      }
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.startUpAndDown() ??
          false;
      print("verticalCruise start $result");
      startQueryStatusTimer();
    } else {
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.stopUpAndDown() ??
          false;
      print("verticalCruise stop $result");
      if (result) {
        state?.isVertical.value = false;
      }
    }
  }

  ///预置位巡航
  void presetCruise(bool isStart) async {
    if (isStart) {
      if (state!.isVertical.value ||
          state!.isHorizontal.value ||
          state!.isPtzAdjust.value ||
          state!.isCruising.value) {
        return;
      }
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.startPresetCruise() ??
          false;
      print("presetCruise start $result");
      startQueryStatusTimer();
    } else {
      bool result = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.stopPresetCruise() ??
          false;
      print("presetCruise stop $result");
      if (result) {
        state?.isCruising.value = false;
      }
    }
  }

  ///云台矫正
  void ptzCorrect() async {
    ///注意：电量低于20%该功能不可用
    if (state!.isVertical.value ||
        state!.isHorizontal.value ||
        state!.isPtzAdjust.value ||
        state!.isCruising.value) {
      return;
    }
    bool bl =
        await DeviceManager.getInstance().mDevice!.motorCommand?.ptzCorrect() ??
            false;
    if (bl) {
      startQueryStatusTimer();
    }
  }

  ///获取预置位信息
  Future<bool> getPresetCruiseLine() async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    bool bl = await device.presetCruiseCommand?.getPresetCruiseLine() ?? false;

    if (bl) {
      Map? lineMap = device.presetCruiseCommand?.presetCruiseLineData;
      int sum = device.presetCruiseCommand?.sumPreset ?? 0;
      List<PresetCruiseLineModel> lineModels = [];
      if (lineMap != null) {
        for (int i = 1; i <= sum; i++) {
          int? num = int.tryParse(lineMap["preset${i}_num"] ?? "");
          int? speed = int.tryParse(lineMap["preset${i}_speed"] ?? "");
          int? time = int.tryParse(lineMap["preset${i}_stoptime"] ?? "");

          if (num != null && speed != null && time != null) {
            var model = PresetCruiseLineModel(num);
            model.speed.value = speed;
            model.time.value = time;
            model.index.value = i - 1;
            lineModels.add(model);
          }
        }
      }
      DeviceModel? dModel = DeviceManager.getInstance().deviceModel;
      if (dModel != null) {
        dModel.actionPresetCruiseLine.clear();
        dModel.actionPresetCruiseLine.addAll(lineModels);
      }
    }
    return bl;
  }

  ///截图并设置预置位
  void getPicAndSet(int index) async {
    SettingsMainLogic mainLogic = Get.find<SettingsMainLogic>();
    var dir = await getApplicationDocumentsDirectory();
    AppPlayerController controller = DeviceManager.getInstance().controller!;
    String imageSize = "2960x1665";
    File? file = await mainLogic.playerScreenshot(dir, controller, imageSize,
        isPreset: true);
    if (file != null) {
      //设置预置位
      bool bl = await DeviceManager.getInstance()
              .mDevice!
              .motorCommand
              ?.setPresetLocation(index) ??
          false;
      if (bl) {
        DeviceManager.getInstance().deviceModel?.presetPositionList[index] =
            "1";
        //设置成功，则保存图片
        copyImgFile(file, dir, index);
      } else {
        print("预置位设置失败！");
      }
    } else {
      print("截图出错了！");
    }
  }

  ///把截图文件按指定路径复制一份
  void copyImgFile(File? file, Directory dir, int index) {
    if (file != null) {
      String did = DeviceManager.getInstance().mDevice!.id;
      try {
        File copyFile = file;
        File destFile = File("${dir.path}/$did/preset/$index.jpg");

        //创建目标文件目录
        if (!destFile.parent.existsSync())
          destFile.parent.createSync(recursive: true);

        if (copyFile.existsSync()) {
          copyFile.copySync(destFile.path);
        }

        if (file.existsSync()) {
          file.deleteSync();
        }

        File file2 = File('${file.path}_small');
        if (file2.existsSync()) {
          file2.deleteSync();
        }
      } catch (e) {
        print("文件复制出错了：$e");
      }

      ///更新保存数据
      savePresetModels(dir, did);
    }
  }

  void savePresetModels(Directory dir, String did) async {
    //更新 preset model
    List<PresetModel?> presetModels = [];
    //获取已设置的预置位信息，如：[1,1,0,1,0] 1代表已设置，0代表未设置
    List presetList =
        DeviceManager.getInstance().deviceModel?.presetPositionList ??
            ["0", "0", "0", "0", "0"];
    print("---presetList--${presetList.toString()}-------");
    for (int i = 0; i < 5; i++) {
      PresetModel? model;
      if (presetList.isNotEmpty && presetList[i] == "1") {
        print("---presetList[$i]--${presetList[i]}-------");
        String path = "${dir.path}/$did/preset/$i.jpg";
        File fi = File(path);
        if (fi.existsSync()) {
          model = PresetModel(path, i, fi, true);
        } else {
          path = "icons/preset_pic.png";
          model = PresetModel(path, i, fi, false);
        }
      }
      presetModels.add(model);
    }
    state!.presetData.clear();
    state!.presetData.addAll(presetModels);
  }

  //删除预置位快照
  void deletePresetSnapshot(int index) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String did = DeviceManager.getInstance().mDevice!.id;

    File file = File("${dir.path}/$did/preset/$index.jpg");
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .motorCommand
            ?.deletePresetLocation(index) ??
        false;
    if (bl) {
      DeviceManager.getInstance().deviceModel?.presetPositionList[index] = "0";

      ///删除看守卫
      if (state!.guardIndex.value == index) {
        setGuard(-1);
      }
      try {
        //删除文件
        file.deleteSync();
        File file2 = File("${dir.path}/$did/preset/$index.jpg_smail");
        if (file2.existsSync()) {
          file2.deleteSync();
        }
      } catch (e) {
        print("删除文件出错了：$e");
      }

      //更新 preset model
      // List<PresetModel?> files = [];
      // for (int i = 0; i < 5; i++) {
      //   String path = "${dir.path}/$did/preset/$i.jpg";
      //   File file = File(path);
      //   PresetModel? model;
      //   if (file.existsSync()) {
      //     model = PresetModel(path, i, file, true);
      //   }
      //   files.add(model);
      // }
      // state!.presetData.clear();
      // state!.presetData.addAll(files);

      //更新数据
      List<PresetModel?> tempList = List<PresetModel?>.from(state!.presetData);
      tempList[index] = null;
      state!.presetData.clear();
      state!.presetData.addAll(tempList);
    } else {
      print("删除预置位失败！");
    }
  }

  void getKanShou() async {
    List array = DeviceManager.getInstance()
            .deviceModel
            ?.currentSystemVer
            .value
            .split(".") ??
        [];
    if (array.length < 4) {
      array = ['0', '0', '0', '0'];
    }
    int second = int.tryParse(array[1]) ?? 0;
    if (second == 5 ||
        second == 65 ||
        second == 66 ||
        second == 68 ||
        second == 84 ||
        second == 91 ||
        second == 94 ||
        second == 95 ||
        second == 96 ||
        (DeviceManager.getInstance().deviceModel!.support_ptz_guard.value >
            0)) {
      ///支持看守卫设置
      state!.isSupportGuard.value = true;
      int index = await DeviceManager.getInstance()
          .getGuardIndex(DeviceManager.getInstance().mDevice!.id);
      state!.guardIndex(index);
    }
  }

  void setGuardEdit(bool isEdit) {
    bool isNull = true;
    state!.presetData.value.forEach((element) {
      if (element != null) {
        isNull = false;
      }
    });
    if (isNull) {
      EasyLoading.showToast("请先设置常看位！");
      return;
    }
    state!.isGuardEdit(isEdit);
  }

  ///设置看守卫，看守卫对应参数是1-16
  void setGuard(int index) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .motorCommand
            ?.configCameraSensorGuard(index + 1) ??
        false;
    if (bl) {
      state!.guardIndex(index);
      DeviceManager.getInstance()
          .setGuardIndex(index, DeviceManager.getInstance().mDevice!.id);
      if (index == -1) {
        EasyLoading.showToast("该看守卫已删除！");
      } else {
        EasyLoading.showToast("看守卫设置成功！");
      }
    }
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
