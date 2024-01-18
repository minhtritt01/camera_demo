import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:vsdk/camera_device/commands/camera_command.dart';

class BlueToothConnectState {
  var isGetBlueDevices = false.obs;
  var isBlueSearching = false.obs;

  List<ScanResult> blueDevices = [];
  RxString wifiName = "".obs;
  String wifiBssid = "";
  String wifiPsw = "";

  List<int> wifiData = [];

  int steps = 0;

  ///连接状态  0== 没状态   1=== 连接中  2=== 连接失败 3 ===连接成功
  var blueStatus = 0.obs;
  var blueErrorCode = 0.obs;

  ///连接状态  0== 没状态   1=== 连接中  2=== 连接失败 3 ===连接成功
  var oneStatus = 0.obs;
  var oneErrorCode = 0.obs;

  ///连接状态  0== 没状态   1=== 连接中  2=== 连接失败 3 ===连接成功
  var twoStatus = 0.obs;
  var twoErrorCode = 0.obs;

  ///连接状态  0== 没状态   1=== 连接中  2=== 连接失败 3 ===连接成功
  var threeStatus = 0.obs;
  var threeErrorCode = 0.obs;

  ///失败步骤
  var fail_step = 0.obs;

  ///失败步骤的错误码
  var fail_code = 0.obs;

  List<WiFiInfo> wifiList = [];

  var wifiPgkLen = 40;
}
