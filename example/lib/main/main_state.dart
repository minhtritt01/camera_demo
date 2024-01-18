import 'package:get/get.dart';
import 'package:vsdk/camera_device/camera_device.dart';

class MainState {
  late CameraDevice mDevice;
  late int clientPtr;
  CameraConnectState connectState = CameraConnectState.none;
  String? uid;
  String psw = "888888";
  RxBool isGetDevice = false.obs;
}
