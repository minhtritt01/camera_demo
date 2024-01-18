import 'dart:ui' as ui;
import 'dart:io';
import 'package:get/get.dart';
import 'package:vsdk_example/linkable_revise/widgets/ImageClipper.dart';

class LinkableReviseState {
  ///是否正在联动校正
  var isLinkableRevising = RxBool(false);

  ///联动校正完成
  var linkableReviseDone = RxBool(false);

  ///大图缩略图
  var backgroundImageA = Rx<File?>(null);

  ///大图缩略图
  var backgroundImageB = Rx<File?>(null);

  var xPercent = RxInt(50);

  var yPercent = RxInt(50);

  Rx<ImageClipper?> mImageClipper = Rx<ImageClipper?>(null);

  Rx<ui.Image?> uiImageB = Rx<ui.Image?>(null);

  var centerX = RxInt(50);

  var isRet = Rx<bool>(false);

  var moveBtip = Rx<bool>(true);
}
