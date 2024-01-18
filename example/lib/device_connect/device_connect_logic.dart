import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../utils/app_web_api.dart';
import '../utils/super_put_controller.dart';
import '../utils/vuid_prefix_helper.dart';
import 'device_connect_state.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class DeviceConnectLogic extends SuperPutController<DeviceConnectedState> {
  TextEditingController textController = TextEditingController();
  int times = 0;

  DeviceConnectLogic() {
    value = DeviceConnectedState();
  }

  @override
  void onInit() {
    cleanDevice();
    getWifiInfo();
    super.onInit();
  }

  @override
  InternalFinalCallback<void> get onDelete {
    print("--------onDelete-------");
    times = -1;
    return super.onDelete;
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  void getWifiInfo() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) {
      final info = NetworkInfo();
      final wifiName = await info.getWifiName(); // "FooNetwork"
      final wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
      final wifiIP = await info.getWifiIP();
      print('WiFi名称: $wifiName'); //"vstarcam123"
      print('WiFi BSSID: $wifiBSSID'); // e0:d4:62:e6:63:b0
      print('WiFi IP地址: $wifiIP'); //192.168.101.250
      if (wifiName != null && wifiBSSID != null) {
        if (wifiName.contains("\"")) {
          state!.wifiName.value = wifiName.replaceAll("\"", "");
        } else {
          state!.wifiName.value = wifiName;
        }
        if (wifiBSSID.contains(":")) {
          state!.wifiBssid = wifiBSSID.replaceAll(":", "");
        } else {
          state!.wifiBssid = wifiBSSID;
        }
        print('WiFi BSSID: ${state!.wifiBssid}');
      }
    } else {
      print('设备未连接到WiFi');
    }
  }

  void generateQrCode() async {
    String psw = textController.text;
    if (psw.isEmpty) {
      EasyLoading.showToast("密码不能为空！");
      return;
    }
    state!.wifiPsw = psw;
    state!.qrContent =
        '{"BS":"${state!.wifiBssid}","P":"${state!.wifiPsw}","U":"15463733-OEM","RS":"${state!.wifiName.value}"}';
    print("-------qrContent-----------${state!.qrContent}");
    state!.isShowQR(true);
    times = 0;
    queryRepeat();
  }

  //每间隔2秒查询一次，最多查询30次
  void queryRepeat() {
    times++;
    if (times < 1) {
      return;
    }
    Future.delayed(Duration(seconds: 2), () async {
      String? did = await queryDevice(times);
      if (did == null && times < 30) {
        queryRepeat();
      } else if (did != null) {
        cleanDevice();
        Get.back(result: did);
      } else {
        EasyLoading.showToast("超时未找到设备！");
      }
    });
  }

  Future<String?> queryDevice(int times) async {
    if (times % 2 == 0) {
      ///老设备
      return await queryDeviceOld("15463733-OEM");
    } else {
      ///新设备
      return await queryDeviceNew("15463733-OEM_binding");
    }
  }

  Future<String?> queryDeviceOld(String key) async {
    var response = await AppWebApi().requestHelloQuery("15463733-OEM");
    print("--queryDevice--response----$response-----------");
    //I/flutter (26631): --queryDevice--response----{"msg":"未搜索到","code":404}-----------
    // I/flutter (26631): --queryDevice--response----{"value":"VE0005622QHOW"}-----------
    if (response.statusCode == 200) {
      String did = response.data["value"];
      if (SupportVuidPrefix.supportVuidPrefix(did) == false) {
        return null;
      }
      return did;
    }
    return null;
  }

  Future<String?> queryDeviceNew(String key) async {
    var response = await AppWebApi().requestHelloQuery("15463733-OEM_binding");
    print("--queryDevice--response----$response-----------");
    if (response.statusCode == 200) {
      String tempDate = response.data["value"];
      String data = Uri.decodeComponent(tempDate);
      String did = json.decode(data)["vuid"];
      if (SupportVuidPrefix.supportVuidPrefix(did) == false) {
        return null;
      }
      return did;
    }
    return null;
  }

  void cleanDevice() async {
    var response = await AppWebApi().requestHelloConfirm("15463733-OEM");
    print("--cleanDevice--response----$response-----------");
  }
}
