import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk_example/linkable_revise/widgets/ImageClipper.dart';
import 'package:vsdk_example/linkable_revise/widgets/camera_one/camera_one_logic.dart';
import 'package:vsdk_example/linkable_revise/widgets/camera_two/camera_two_logic.dart';
import 'package:vsdk_example/linkable_revise/widgets/reset_button/reset_button_logic.dart';
import 'package:vsdk_example/linkable_revise/widgets/sure_button/sure_button_logic.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../model/device_model.dart';
import '../utils/super_put_controller.dart';
import 'linkable_revise_state.dart';

class LinkableReviseLogic extends SuperPutController<LinkableReviseState>
    with CameraOneLogic, CameraTwoLogic, ResetButtonLogic, SureButtonLogic {
  LinkableReviseLogic() {
    value = LinkableReviseState();
    initPut();
  }

  Timer? _checkTimer;
  Timer? timeOutTimer;
  var timeout = 5;

  @override
  void onInit() {
    setPTZRevise();
    super.onInit();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  @override
  void onClose() {
    if (_checkTimer != null) {
      _checkTimer!.cancel();
      _checkTimer = null;
    }
    if (timeOutTimer != null) {
      timeOutTimer!.cancel();
      timeOutTimer = null;
    }
    super.onClose();
  }

  void setPTZRevise() async {
    if (DeviceManager.getInstance().deviceModel!.isSupportLowPower.value &&
        DeviceManager.getInstance().deviceModel!.batteryRate.value < 20) {
      EasyLoading.showToast("电量不足，云台无法使用");
      return;
    }
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    print('result setPTZSet start');
    bool result = await device.qiangQiuCommand?.qiangqiuPTZReset() ?? false;
    print('result setPTZSet $result');
    if (result == true) {
      state!.isLinkableRevising.value = true;
      _checkTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        bool bl = await device.qiangQiuCommand?.qiangqiuPTZCheck() ?? false;
        if (bl == true) {
          if (device.qiangQiuCommand?.picconrection_status == 2) {
            print('------------setPTZRevise  done-----------');
            _checkTimer?.cancel();
            _checkTimer = null;
            state!.isLinkableRevising.value = false;
            state!.linkableReviseDone.value = true;
            getTwoSnot();
            setTipsTimeOut();
          }
        }
      });
    }
  }

  void setTipsTimeOut() {
    timeOutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      timeout = timeout - 1;
      if (timeout < 0) {
        state!.moveBtip.value = false;
        timeOutTimer?.cancel();
        timeOutTimer = null;
      }
    });
  }

  void getTwoSnot() async {
    DeviceModel model = DeviceManager.getInstance().deviceModel!;
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    if (model.pinInPicSensor.value == 1) {
      File? file1 = await device.qiangQiuCommand?.getSnapshot("1");
      if (file1 != null) {
        state!.backgroundImageB.value = file1;
        state!.backgroundImageB.refresh();
        clipB();
      }
      Future.delayed(Duration(milliseconds: 500), () async {
        File? file2 = await device.qiangQiuCommand?.getSnapshot("0");
        if (file2 != null) {
          state!.backgroundImageA.value = file2;
          state!.backgroundImageA.refresh();
          clipA();
          state!.mImageClipper.refresh();
        }
      });
    } else {
      if (model.supportMutilSensorStream.value == 1) {
        File? file1 = await device.qiangQiuCommand?.getSnapshot("1");
        if (file1 != null) {
          state!.backgroundImageA.value = file1;
          state!.backgroundImageA.refresh();
          clipA();
          state!.mImageClipper.refresh();
        }
        Future.delayed(Duration(milliseconds: 500), () async {
          File? file2 = await device.qiangQiuCommand?.getSnapshot("0");
          if (file2 != null) {
            state!.backgroundImageB.value = file2;
            state!.backgroundImageB.refresh();
            clipB();
          }
        });
      } else if (model.pinInPicSensor.value == 0) {
        File? file1 = await device.qiangQiuCommand?.getSnapshot("0");
        if (file1 != null) {
          state!.backgroundImageA.value = file1;
          state!.backgroundImageA.refresh();
          clipA();
          state!.mImageClipper.refresh();
        }
        Future.delayed(Duration(milliseconds: 500), () async {
          File? file2 = await device.qiangQiuCommand?.getSnapshot("1");
          if (file2 != null) {
            state!.backgroundImageB.value = file2;
            state!.backgroundImageB.refresh();
            clipB();
          }
        });
      }
    }
  }

  clipB() async {
    ui.Image? uiImage;
    _loadImageB().then((image) {
      uiImage = image;
    }).whenComplete(() {
      state!.uiImageB.value = uiImage;
    });
  }

  Future<ui.Image> _loadImageB() async {
    ImageStream imageStream = FileImage(
      (state!.backgroundImageB.value!),
    ).resolve(ImageConfiguration());
    Completer<ui.Image> completer = Completer<ui.Image>();
    void imageListener(ImageInfo info, bool synchronousCall) {
      ui.Image image = info.image;
      completer.complete(image);
      imageStream.removeListener(ImageStreamListener(imageListener));
    }

    imageStream.addListener(ImageStreamListener(imageListener));
    return completer.future;
  }

  Future<ui.Image> _loadImage() async {
    ImageStream imageStream = FileImage(
      (state!.backgroundImageA.value!),
    ).resolve(ImageConfiguration());
    Completer<ui.Image> completer = Completer<ui.Image>();
    void imageListener(ImageInfo info, bool synchronousCall) {
      ui.Image image = info.image;
      completer.complete(image);
      imageStream.removeListener(ImageStreamListener(imageListener));
    }

    imageStream.addListener(ImageStreamListener(imageListener));
    return completer.future;
  }

  clipA() async {
    late ui.Image uiImage;
    _loadImage().then((image) {
      uiImage = image;
    }).whenComplete(() {
      state!.mImageClipper.value = ImageClipper(uiImage);
    });
  }
}
