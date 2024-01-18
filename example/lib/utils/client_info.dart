import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ClientInfo {
  /// 单例
  static ClientInfo? _instance;

  /// 将构造函数指向单例
  factory ClientInfo() => getInstance();

  ///获取单例
  static ClientInfo getInstance() {
    if (_instance == null) {
      _instance = new ClientInfo._internal();
    }
    return _instance!;
  }

  ClientInfo._internal();

  String? _clientUUID;

  Future<String?> getClientUUID() async {
    if (_clientUUID != null) {
      return _clientUUID;
    }
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey("client_uuid")) {
      _clientUUID = sharedPreferences.getString("client_uuid")!;
    } else {
      _clientUUID = Uuid().v4();
      await sharedPreferences.setString('client_uuid', _clientUUID!);
    }
    return _clientUUID;
  }

  int getClientType() {
    if (Platform.isIOS) {
      return 0;
    }
    if (Platform.isAndroid) {
      return 1;
    }
    return -1;
  }

  String? _clientModel;

  Future<String?> getClientModel() async {
    if (_clientModel != null) {
      return _clientModel;
    }
    DeviceInfoPlugin infoPlugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo deviceInfo = await infoPlugin.iosInfo;
      _clientModel = deviceInfo.model!;
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo deviceInfo = await infoPlugin.androidInfo;
      _clientModel = deviceInfo.model;
    } else {
      _clientModel = Platform.operatingSystem;
    }
    return _clientModel;
  }

  String? _clientName;

  Future<String> getClientName() async {
    if (_clientName != null) {
      return _clientName!;
    }
    DeviceInfoPlugin infoPlugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo deviceInfo = await infoPlugin.iosInfo;
      _clientName = deviceInfo.name;
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo deviceInfo = await infoPlugin.androidInfo;
      _clientName = deviceInfo.device;
    } else {
      _clientName = 'Unknown';
    }
    return _clientName!;
  }

  String toString() {
    return '{clientName:$_clientName,clientModel:$_clientModel}';
  }
}
