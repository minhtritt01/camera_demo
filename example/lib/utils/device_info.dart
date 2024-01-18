import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:vsdk/basis_device.dart';
import 'package:vsdk/camera_device/camera_device.dart';

class DeviceInfo extends Equatable {
  DeviceInfo(this.id, String password, this.type, this.model, this.time,
      this.mode, this.doubleCheck,
      {required this.name,
      this.user = "admin",
      this.did,
      this.editPassword = true,
      this.connectType = 126}) {
    this.password = password;
  }

  // 设备ID
  final String id;

  final String? did;

  String? cloudUrl;

  String? cloudLicenseKey;

  String supportCloud = '0';

  String role = '0';

  ///设备类型
  /// 0 摄像机
  final String type;

  //设备型号
  final String model;

  //入网模式
  final String mode;

  // SupportModeType get modeType {
  //   return SupportMode.getAddModeType(mode);
  // }

  // 添加时间
  final DateTime time;

  final bool editPassword;

  final int connectType;

  //用户名
  String? user;

  // 设备密码
  String _password = "";

  set password(String value) {
    _password = value;
    if (device is CameraDevice) {
      (device as CameraDevice).password = value;
    }
  }

  String get password => _password;

  // 设备名称
  String name = "";

  /// 是否为置顶设备
  bool topDevice = false;

  int topDeviceTime = 0;

  bool offlinePush = false;

  /// 双重认证用户ID
  int? doubleCheck;

  ///自动唤醒标识
  bool _autoWakeup = false;

  bool get autoWakeup => _autoWakeup;

  set autoWakeup(value) {
    _autoWakeup = value;
  }

  ///本地设备标识
  bool _localDevice = false;

  bool get localDevice => _localDevice;

  set localDevice(bool value) {
    _localDevice = value;
  }

  String? iccId;

  bool push = true;
  String plainTextPassword = '';
  List push_config = [];

  String? DT;
  String? PT;

  Map getInfo() {
    return {
      "topDevice": topDevice ?? false,
      "topDeviceTime": topDeviceTime ?? 0,
      "autoWakeup": autoWakeup ?? false,
      'iccId': iccId,
      'push': push == true ? "1" : "0",
      'password': plainTextPassword,
      'push_config': push_config,
      'DT': DT,
      'PT': PT
      // 'push_config': [
      //   {"app": offlinePush ?? false, "key": "offline"}
      // ]
    };
  }

  void setInfo(Map map) {
    bool? tempwake;
    if (map.containsKey("autoWakeup")) {
      tempwake = map["autoWakeup"];
    } else if (map.containsKey("isAutoWakeUp")) {
      if (map["isAutoWakeUp"] is String) {
        tempwake = map["isAutoWakeUp"] == "true";
      } else if (map["isAutoWakeUp"] is bool) {
        tempwake = map["isAutoWakeUp"];
      } else if (map["isAutoWakeUp"] is num) {
        tempwake = map["isAutoWakeUp"] != 0;
      }
    } else {
      tempwake = (model == 'BMW1' || model == 'BMG1' || model == 'BPW4')
          ? false
          : true;
    }
    autoWakeup = tempwake ?? true;
    if (map["topDevice"] != null && map["topDevice"] is String) {
      topDevice = map["topDevice"] == '1' ? true : false;
    } else {
      topDevice = map["topDevice"] ?? false;
    }

    if (map.containsKey('topDeviceTime')) {
      topDeviceTime = map["topDeviceTime"];
    }

    iccId = map["iccId"];
    push = map["push"] == "1" ?? true;
    plainTextPassword = map["password"] ?? '';
    if (map['push_config'] == null) {
      offlinePush = false;
    } else {
      var pushconfig = map['push_config'];
      push_config = pushconfig;
      for (var config in pushconfig) {
        String key = config["key"];
        if (key == 'offline') {
          offlinePush = config["app"];
          break;
        }
      }
    }

    DT = map["DT"];
    PT = map["PT"];
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, type, model, time];

  IconData? deviceIcon;

  BasisDevice? _device;

  BasisDevice? get device {
    if (_device != null) {
      return _device;
    }
    if (type == "0" || type == "IPC") {
      CameraDevice cameraDevice = CameraDevice(
          id, name, "admin", password, model,
          clientId: this.did,
          editPassword: this.editPassword,
          connectType: this.connectType);
      _device = cameraDevice;
    }
    return _device;
  }
}
