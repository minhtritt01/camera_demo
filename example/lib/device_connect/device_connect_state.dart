import 'package:get/get.dart';

class DeviceConnectedState {
  var isShowQR = false.obs;
  Rx<String> wifiName = "".obs;
  String wifiBssid = "";
  String wifiPsw = "";
  String qrContent = "";
}
