import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:open_settings/open_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsdk/camera_device/commands/camera_command.dart';
import 'package:vsdk_example/utils/permission_handler/permission_handler.dart';
import '../app_routes.dart';
import '../utils/app_web_api.dart';
import '../utils/blue_name_utils.dart';
import '../utils/blue_package.dart';
import '../utils/permission_handler/permission_handler_platform_interface.dart';
import '../utils/super_put_controller.dart';
import '../utils/vuid_prefix_helper.dart';
import 'bluetooth_connect_state.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BlueToothConnectLogic extends SuperPutController<BlueToothConnectState> {
  TextEditingController textController = TextEditingController();
  Timer? thisTimer;

  BlueToothConnectLogic() {
    value = BlueToothConnectState();
  }

  @override
  void onInit() {
    getWifiInfo();
    requestBlue();
    helloConfirmDevice();
    super.onInit();
  }

  @override
  void onClose() {
    print("-------onClose-----------");
    stopSearchBlue();
    super.onClose();
  }

  @override
  InternalFinalCallback<void> get onDelete {
    print("--------onDelete-------");
    return super.onDelete;
  }

  void requestBlue() async {
    var blue = await Permission.bluetooth.status;
    if (blue != PermissionStatus.granted) {
      if (Platform.isIOS) {
        await [Permission.bluetooth].request();
      }
    } else {
      if (Platform.isIOS) {
        searchBlue();
      }
    }

    if (Platform.isAndroid) {
      var bluetoothScan = await Permission.bluetoothScan.status;
      print("${Get.currentRoute} 权限 bluetooth ：$blue");
      print("${Get.currentRoute} 权限 bluetoothScan ：$bluetoothScan");
      if (blue != PermissionStatus.granted ||
          bluetoothScan != PermissionStatus.granted) {
        await [
          Permission.bluetooth, //相机
          Permission.bluetoothScan, //写入相册
          Permission.bluetoothAdvertise, //读取相册
          Permission.locationWhenInUse, //使用应用期间获取定位
          Permission.bluetoothConnect, //获取蓝牙
        ].request();
      } else {
        searchBlue();
      }
    }

    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        print("${Get.currentRoute} blue :BluetoothState.on");
      } else if (state == BluetoothAdapterState.off) {
        print("${Get.currentRoute} blue :BluetoothState.off");
        jumpBlueSetting();
      }
    });

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  void jumpBlueSetting() async {
    if (Platform.isIOS) {
      if (await canLaunch("app-settings:")) {
        await launch("app-settings:");
      }
    } else if (Platform.isAndroid) {
      OpenSettings.openBluetoothSetting();
    }
  }

  void searchBlue() async {
    await stopSearchBlue();
    state!.blueDevices.clear();
    var list = FlutterBluePlus.connectedDevices;

    ///print("蓝牙 size${list.length}");
    for (var item in list) {
      ///print("蓝牙 ${item?.name}");
      await item.disconnect();
    }
    print("blue: ${Get.currentRoute}  蓝牙 全部 断开========");
    await Future.delayed(Duration(milliseconds: 300));
    var tempTime = DateTime.now().millisecondsSinceEpoch;

    FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName.isNotEmpty &&
            isBlueDev(r.device.platformName)) {
          var currentTime = DateTime.now().millisecondsSinceEpoch - tempTime;
          print("---scanResults----${r.device.platformName}--------");
          if ((currentTime) > 500) {
            addList(r);
            state!.isBlueSearching.value = false;
          }
        }
      }
    });
    state!.isBlueSearching.value = true;
    await FlutterBluePlus.startScan(
            timeout: Duration(seconds: 4), androidUsesFineLocation: true)
        .onError((error, stackTrace) {
      print("blue: ${Get.currentRoute}    blue 蓝牙搜索出错了");
    });
  }

  void addList(ScanResult result) {
    if (state!.blueDevices.length == 0) {
      state!.blueDevices.add(result);
    }
    for (ScanResult r in state!.blueDevices) {
      if (result.device.remoteId == r.device.remoteId) {
        //已存在
        return;
      }
    }
    state!.blueDevices.add(result);
  }

  Future<void> stopSearchBlue() async {
    state!.isBlueSearching.value = false;
    if (state!.blueDevices.length > 0) {
      state!.blueDevices.clear();
    }
    await FlutterBluePlus.stopScan();
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

  void clickToConnect() async {
    if (textController.text.length == 0) {
      EasyLoading.showToast("密码不能为空！");
      return;
    }
    state!.wifiPsw = textController.text;
    if (state!.blueDevices.length == 0) return;
    BluetoothDevice cameraDevice = await connectBlueDevice();
    var deviceState = await cameraDevice.connectionState.firstWhere((element) =>
        element == BluetoothConnectionState.connected ||
        element == BluetoothConnectionState.disconnected);
    if (deviceState == BluetoothConnectionState.connected) {
      FlutterBluePlus.stopScan();
      print('wifi----name: ${state!.wifiName.value} psw:${state!.wifiPsw}');

      ///把wifi信息转为发送数据类型
      state!.wifiData = BluePackage.toData(
              "15463733-OEM", state!.wifiName.value, state!.wifiPsw, 1)
          .buffer
          .asUint8List();

      String cameraId = "";
      if (cameraDevice.platformName.startsWith("IPC-")) {
        //长电
        cameraId = cameraDevice.platformName.replaceAll("IPC-", "");
      }
      if (cameraDevice.platformName.startsWith("MC-")) {
        //低功耗
        cameraId = cameraDevice.platformName.replaceAll("MC-", "");
      }
      if (cameraId.length != 0) {
        checkBlueStatus(cameraDevice);
      }
    } else {
      print("设备${cameraDevice.platformName}蓝牙连接断开，请重试！");
    }
  }

  Future<BluetoothDevice> connectBlueDevice() async {
    BluetoothDevice cameraDevice = state!.blueDevices[0].device;
    print(
        "---cameraDevice-platformName---${cameraDevice.platformName}--------");
    await cameraDevice
        .connect(mtu: null, autoConnect: true)
        .timeout(Duration(seconds: 15), onTimeout: () async {
      await cameraDevice.disconnect();
    }).onError((error, stackTrace) {
      print('蓝牙连接出错 error ${Get.currentRoute}');
    });
    return cameraDevice;
  }

  void getBlueWifiList() async {
    if (state!.blueDevices.length == 0) return;
    BluetoothDevice cameraDevice = await connectBlueDevice();
    BluetoothConnectionState deviceState =
        await reconectIfDisconnect(cameraDevice);
    if (deviceState == BluetoothConnectionState.connected) {
      BluetoothCharacteristic? chars = await getCharacteristic(cameraDevice);
      if (chars == null) {
        print('configBuleWifi 连接  chars == null-00805F9B3');
        await cameraDevice.disconnect();
      } else {
        ///发送获取wifi列表的协议信息
        await chars.setNotifyValue(true);
        setCharWifiListener(chars);
        await chars.write([0xAA, 0xAA]).timeout(Duration(seconds: 3),
            onTimeout: () {
          print("write 0xAA写 timeout");
        }).onError((error, stackTrace) {
          print("write 0xAA写 error：：：：error$error  stacktrace $stackTrace");
        });
      }
    } else {
      print("----蓝牙连接断开-----------");
    }
  }

  ///监听wifi列表的回复
  void setCharWifiListener(BluetoothCharacteristic characteristic) async {
    final List<int> data = [];
    characteristic.onValueReceived.listen((event) {
      print("listen===== $event");
      if (event.isNotEmpty) {
        if (event[0] == 0xAA && event[1] == 0xAA) {
          characteristic.write([
            0xFF,
            0xFF,
          ]).timeout(Duration(seconds: 10), onTimeout: () {
            print("write 写 ：：：：onTimeout");
          }).onError((error, stackTrace) {
            print("write 写 ：onError：：：error stacktrace ");
          });
          return;
        }
        if (data.isEmpty && event[0] == 0xF0 && event[1] == 0xF3) {
          data.addAll(event);
        } else {
          if (data.isNotEmpty) {
            data.addAll(event);
          }
        }

        ///data.addAll(event);
        if (data.length >= state!.wifiPgkLen) {
          print(
              '一包数据：getBule event:$data   length :${data.length}  0:${data[0]} 1:${data[1]}');
          if (data[0] == 0xF0 && data[1] == 0xF3) {
            print(
                '一包数据：getBule eventevent[0] == 0xF0:${data[2]}  0xF0:${data[3]}  ');
            final pData = Uint8List.fromList(data);
            BluePackage? package = BluePackage.fromData(
                ByteData.sublistView(pData, 0, state!.wifiPgkLen),
                state!.wifiPgkLen);
            if (package == null) return;
            print("收到完整一个wifi 信息，回复：package.ap_index:${package.apIndex}");
            if (package.apIndex != 10000) {
              try {
                Future.delayed(Duration(milliseconds: 100), () {
                  characteristic.write([
                    0xFF,
                    package.apIndex,
                  ]).timeout(Duration(seconds: 10), onTimeout: () {
                    print("write 写 ：：：：onTimeout");
                  }).onError((error, stackTrace) {
                    print("write 写 ：onError：：：error  stacktrace ");
                  });
                });
              } catch (e) {
                print("取wifi 列表 回复oxff  异常了。。。。。");
              }
            }
            WiFiInfo info = WiFiInfo();
            info.ssid = package.apSsid;
            // info.ssid = package.ap_ssid;
            if (package.apIndex != 10000 && !(state!.wifiList.contains(info))) {
              print("wifi 名称---${package.apSsid}--");
              state!.wifiList.add(info);
            }
            data.removeRange(0, state!.wifiPgkLen);
            if (package.apIndex == 10000) {
              characteristic.setNotifyValue(false);
            }
          }
        }
      }
    });
  }

  void checkBlueStatus(BluetoothDevice cameraDevice) async {
    // BluetoothConnectionState deviceState =
    //     await reconectIfDisconnect(cameraDevice);
    BluetoothCharacteristic? chars = await getCharacteristic(cameraDevice);
    if (chars == null) {
      print('configBuleWifi 连接  chars == null-00805F9B3');
      await cameraDevice.disconnect();
    } else {
      EasyLoading.showToast("正在连接，请勿离开。。。");
      await chars.setNotifyValue(true);
      if (Platform.isAndroid) {
        await _requestMtu(cameraDevice);
      }
      setCharListener(chars, cameraDevice);
      configBlueWifi(chars);
    }
  }

  Future<BluetoothConnectionState> reconectIfDisconnect(
      BluetoothDevice cameraDevice) async {
    var deviceState = await cameraDevice.connectionState.firstWhere((element) =>
        element == BluetoothConnectionState.connected ||
        element == BluetoothConnectionState.disconnected);
    if (deviceState == BluetoothConnectionState.disconnected) {
      print('configBuleWifi  获取蓝牙列表 断开了=====');
      await cameraDevice.connect(mtu: null, autoConnect: true);
      deviceState = await cameraDevice.connectionState.firstWhere((element) =>
          element == BluetoothConnectionState.connected ||
          element == BluetoothConnectionState.disconnected);
    }
    return deviceState;
  }

  Future<BluetoothCharacteristic?> getCharacteristic(
      BluetoothDevice cameraDevice) async {
    var services =
        await cameraDevice.discoverServices().timeout(Duration(seconds: 10));
    if (services.length == 0) {
      print('configBuleWifi 连接设备状态成功  services 为null====');
      await cameraDevice.disconnect();
    }
    services.forEach((service) {
      print(
          'configBuleWifi 连接设备状态成功  services uuid ${service.uuid.toString().toUpperCase()}');
    });

    var service = services.firstWhereOrNull(
        (item) => item.uuid.toString().toUpperCase() == "FFF0");
    if (service == null) {
      print('configBuleWifi   services 为null==-00805F9B3');
      await cameraDevice.disconnect();
    }
    var chars = service?.characteristics.firstWhereOrNull(
        (item) => item.uuid.toString().toUpperCase() == "FFF1");
    return chars;
  }

  Future<void> _requestMtu(BluetoothDevice device) async {
    // final mtu = await device.mtu.first;
    // print('连接设备状态成功  mtu 前$mtu');
    await device.requestMtu(240);
    // final mtu2 = await device.mtu.first;
    // print('连接设备状态成功  mtu 后$mtu2');
  }

  ///发送数据包进行蓝牙联网
  void configBlueWifi(BluetoothCharacteristic characteristic) async {
    List<int> first = [0xF0, 0xF0];
    first.addAll(state!.wifiData.sublist(0, 118));
    print("send:配网第一个数据包  data :$first");
    characteristic.write(first);
    Timer.periodic(Duration(seconds: 3), (timer) async {
      if (state!.steps >= 2) {
        timer.cancel();
        return;
      } else if (state!.steps == 1) {
        List<int> second = [0xF0, 0xF1];
        second.addAll(state!.wifiData.sublist(118, state!.wifiData.length));
        print("配网每2个数据包  data :$second");
        characteristic.write(second);
      } else if (state!.steps == 0) {
        List<int> first = [0xF0, 0xF0];
        first.addAll(state!.wifiData.sublist(0, 118));
        print("配网每一个数据包  data :$first");
        characteristic.write(first);
      }
    });
  }

  ///监听联网状态
  void setCharListener(BluetoothCharacteristic characteristic,
      BluetoothDevice cameraDevice) async {
    characteristic.onValueReceived.listen((event) {
      if (event.isNotEmpty) {
        print(
            '根数据 listen 1::${event[0]}  2::${event[1]}  3::${event.sublist(2)}');
        if (event[0] == 240 && event[1] == 240) {
          ///配网第一包设备回复
          state!.steps = 1;
          List<int> second = [0xF0, 0xF1];
          second.addAll(state!.wifiData.sublist(118, state!.wifiData.length));
          characteristic.write(second);
          print("-------配网第一包 ，设备回复---------");
        } else if (event[0] == 240 && event[1] == 241) {
          ///配网第2包 ，设备回复
          state!.steps = 2;
          startTimer();
          print("-------配网第二包设备回复---------");
        } else if (event[0] == 240 && event[1] == 242) {
          state!.steps = 3;

          ///配网第3包 ，设备回复//1-->联网成功；2-->密码错误；3-->连接超时；4-->dhcp失败；5-->网关配置失 6-->dns配置
          if (event[2] == 1) {
            print("-------连网成功---------");
            state!.blueStatus.value = 3;
            state!.oneStatus.value = 1; //开始第一步
            characteristic.setNotifyValue(false);
            cameraDevice.disconnect();
          } else {
            print("-------密码错误,请重新输入---------");
          }
        }
      }
    });
  }

  void startTimer() {
    thisTimer?.cancel();
    thisTimer = null;
    thisTimer = Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) {
        if (Get.currentRoute != AppRoutes.bluetoothConnect) {
          timer.cancel();
          return;
        }
        _counter();
      },
    );
  }

  void _counter() async {
    // if (state!.oneStatus.value == 1) {
    //   state!.oneStatus.value = 2;
    //   state!.oneErrorCode.value = 2001;
    //   state!.fail_step.value = 1;
    //   state!.fail_code.value = 2001;
    //   helloConfirmDevice();
    // } else if (state!.twoStatus.value == 1) {
    //   state!.oneStatus.value = 3;
    //   state!.twoErrorCode.value = 2002;
    //   state!.twoStatus.value = 2;
    //   state!.fail_step.value = 2;
    //   state!.fail_code.value = 2002;
    //   helloConfirmDevice();
    // } else if (state!.threeStatus.value == 1) {
    //   state!.oneStatus.value = 3;
    //   state!.twoStatus.value = 3;
    //   state!.threeStatus.value = 2;
    //   state!.fail_step.value = 3;
    //   state!.threeErrorCode.value = 2003;
    //   state!.fail_code.value = 2003;
    //   helloConfirmDevice();
    // }
    startSearchHelloBindDevice();
  }

  void dealContent(String content) async {
    if (json.decode(content)["C2Net"] != null) {
      print("----C2Net-----${json.decode(content)["C2Net"]}");
      Map map = json.decode(content)["C2Net"];
      state!.steps = 3;
      var statusC2Net = map["Status"];
      print("第一步：map$map statusC2Net $statusC2Net");
      //第一步：map{TStep: 1, CStep: 1, FCode: 4097, Status: 1, Ecode: 0} statusC2Net 1
      if (statusC2Net == 1) {
        state!.oneStatus.value = 3;
        state!.twoStatus.value = 1;
        state!.blueStatus.value = 3;
        print("--------已搜索到摄像机---------------");
        helloConfirmDevice();
        String uid = json.decode(content)["vuid"];
        Get.back(result: uid);
      } else if (statusC2Net == 0) {
        state!.oneStatus.value = 2;
        state!.oneErrorCode.value = map["Ecode"];
        state!.fail_step.value = 1;
        state!.fail_code.value = map["Ecode"];
        helloConfirmDevice();
        print(
            "statusC2Net 第一步结果失败.oneStatus:${state!.oneStatus.value}  oneErrorCode:${state!.fail_code.value}");
      }
    } else if (json.decode(content)["R2SVR"] != null) {
      Map map = json.decode(content)["R2SVR"];
      state!.steps = 3;
      var statusR2SVR = map["Status"];
      print(
          "第二步：map$map statusR2SVR int:${statusR2SVR == 1} string:${statusR2SVR == '1'}");
//map{TStep: 3, CStep: 3, FCode: 8195, Status: 1, Ecode: 0} statusR2SVR int:true string:false
      if (statusR2SVR == 1) {
        // startP2PBinding();
        state!.blueStatus.value = 3;
        state!.oneStatus.value = 3;
        state!.twoStatus.value = 3;
        state!.threeStatus.value = 1;
        print("--------已注册到云服务---------------");
        helloConfirmDevice();
        String uid = json.decode(content)["vuid"];
        Get.back(result: uid);
      } else if (statusR2SVR == 0) {
        state!.oneStatus.value = 3;
        state!.twoStatus.value = 2;
        state!.twoErrorCode.value = map["Ecode"];
        state!.fail_step.value = 2;
        state!.fail_code.value = map["Ecode"];
        helloConfirmDevice();
      }
    } else if (json.decode(content)["B2SVR"] != null) {
      Map map = json.decode(content)["B2SVR"];
      state!.steps = 3;
      var statusB2SVR = map["Status"];
      print("第三步：map$map statusB2SVR $statusB2SVR");
      if (statusB2SVR == 1) {
        ///整个过程sud
        thisTimer?.cancel();
        state!.threeStatus.value = 3;
        state!.twoStatus.value = 3;
        state!.oneStatus.value = 3;
        state!.blueStatus.value = 3;
        print("-------bluetooth----success------------");
        helloConfirmDevice();
      } else if (statusB2SVR == 0) {
        state!.twoStatus.value = 3;
        state!.threeStatus.value = 2;
        state!.threeErrorCode.value = map["Ecode"];
        state!.fail_step.value = 3;
        state!.fail_code.value = map["Ecode"];
        helloConfirmDevice();
        print(
            "statusB2SVR 第3步结果.oneStatus:${state!.threeStatus.value}  oneErrorCode:${state!.threeErrorCode.value}");
      }
    } else {
      state!.oneStatus.value = 1;
    }
  }

  void helloConfirmDevice() async {
    await AppWebApi().requestHelloConfirm("15463733-OEM_binding");
  }

  void startSearchHelloBindDevice() async {
    var content = await queryDeviceNew("15463733-OEM_binding");
    if (content == null) {
      return;
    }
    dealContent(content);
  }

  Future<String?> queryDeviceNew(String key) async {
    var response = await AppWebApi().requestHelloQuery(key);
    print("--queryDevice--response----$response-----------");
    //{"value":"%7B%22vuid%22%3A%22VE0005622QHOW%22%2C%22timestamp%22%3A1703725%3974%2C%22userid%22%3A%2215463733-OEM%22%2C%22R2SVR%22%3A%7B%22TStep%22%3A3%2C%22CStep%22%3A3%2C%22FCode%22%3A81%395%2C%22Status%22%3A1%2C%22Ecode%22%3A0%7D%7D"}
    if (response.statusCode == 200) {
      String tempDate = response.data["value"];
      String data = Uri.decodeComponent(tempDate);
      print("data-----------$data----");
      //{"vuid":"VE0005622QHOW","timestamp":1703728593,"userid":"15463733-OEM","C2Net":{"TStep":1,"CStep":1,"FCode":4097,"Status":1,"Ecode":0}}
      String did = json.decode(data)["vuid"];
      if (SupportVuidPrefix.supportVuidPrefix(did) == false) {
        return null;
      }
      return data;
    }
    return null;
  }
}
