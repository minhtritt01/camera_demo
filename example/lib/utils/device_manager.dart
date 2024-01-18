import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk_example/model/device_model.dart';

import 'device_info.dart';

class DeviceManager {
  /// 单例
  static DeviceManager? _instance;

  /// 将构造函数指向单例
  factory DeviceManager() => getInstance();

  ///获取单例
  static DeviceManager getInstance() {
    if (_instance == null) {
      _instance = new DeviceManager._internal();
    }
    return _instance!;
  }

  DeviceManager._internal() {
    mDevice = null;
    controller = null;
    deviceModel = null;
    deviceInfo = null;
  }

  CameraDevice? mDevice;
  AppPlayerController? controller;
  DeviceModel? deviceModel;
  DeviceInfo? deviceInfo;

  void setDevice(CameraDevice device) {
    mDevice = device;
    setDeviceInfo(device.id, device.password);
  }

  void setController(AppPlayerController contro) {
    controller = contro;
  }

  void setDeviceModel(DeviceModel deModel) {
    deviceModel = deModel;
    is4GDataFlowBindDevice(deviceModel!.id);
  }

  CameraDevice? getDevice() {
    return mDevice;
  }

  void setDeviceInfo(String id, String psw) {
    deviceInfo =
        DeviceInfo(id, psw, "0", "", DateTime.now(), "", null, name: '测试设备');
  }

  DeviceInfo? getDeviceInfo() {
    return deviceInfo;
  }

  AppPlayerController? getController() {
    return controller;
  }

  DeviceModel? getDeviceModel() {
    return deviceModel;
  }

  ///是否静音
  Future<bool> getMonitorState() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getBool('device_monitor') ?? false;
  }

  ///保存静音状态
  Future<bool> setMonitorState(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (value == null) {
      return sp.remove('device_monitor');
    } else {
      return sp.setBool('device_monitor', value);
    }
  }

  ///获取单目设备的警笛开关状态
  Future<bool> getSirenState() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getBool('device_siren') ?? false;
  }

  ///保存单目设备的警笛状态
  Future<bool> setSirenState(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (value == null) {
      return sp.remove('device_siren');
    } else {
      return sp.setBool('device_siren', value);
    }
  }

  ///获取单目设备是否支持人形检测
  Future<bool> getIsSupportDetect(String id) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getBool('${id}_device_is_support_people_detect') ?? false;
  }

  ///保存单目设备是否支持人形检测结果
  Future<bool> setIsSupportDetect(bool value, String id) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setBool('${id}_device_is_support_people_detect', value);
  }

  ///获取电量
  Future<String> getBatteryRate() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('battery_rate') ?? "100";
  }

  ///电量存储
  Future<bool> setBatteryRate(String value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setString('battery_rate', value);
  }

  ///报警开关
  Future<bool> getAlarmStatus() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getBool('alarm_status') ?? false;
  }

  ///报警开关
  Future<bool> setAlarmStatus(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setBool('alarm_status', value);
  }

  //hardwareTestFunc
  Future<String?> getHardwareTestFunc(String did) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String key = await updateDeviceData('${did}_HardwareTestFunc', sp);
    return sp.getString(key);
  }

  Future<bool> setHardwareTestFunc(String did, String value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String key = await updateDeviceData('${did}_HardwareTestFunc', sp);
    if (value == null) {
      return sp.remove(key);
    } else {
      return sp.setString(key, value);
    }
  }

  Future<String> updateDeviceData(String key, SharedPreferences sp) async {
    // UserInfo user = await UserManager().currentUser();
    // String newKey = '${user.id}_$key';
    String newKey = 'admin_$key';
    if (sp.containsKey(newKey)) {
      if (sp.containsKey(key)) {
        await sp.remove(key);
      }
      return newKey;
    }
    if (sp.containsKey(key)) {
      var data = sp.get(key);
      var result = false;
      if (data is int) {
        result = await sp.setInt(newKey, data);
      } else if (data is String) {
        result = await sp.setString(newKey, data);
      } else if (data is bool) {
        result = await sp.setBool(newKey, data);
      } else if (data is List<String>) {
        result = await sp.setStringList(newKey, data);
      } else if (data is double) {
        result = await sp.setDouble(newKey, data);
      }
      if (result == true) {
        await sp.remove(key);
        return newKey;
      }
    }
    return key;
  }

  ///画质
  Future<int> getResolutionValue(String deviceId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getInt('${deviceId}_resolution_value') ?? 0;
  }

  ///画质
  Future<bool> setResolutionValue(int value, String deviceId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setInt('${deviceId}_resolution_value', value);
  }

  ///云存储使用过期时间
  Future<String?> getCloudTryTime(String did) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('${did}_cloud_try_time');
  }

  ///云存储使用过期时间
  Future<bool> setCloudTryTime(String did, String time) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setString('${did}_cloud_try_time', time);
  }

  /*
  低功耗的设备，不是
  长电，能在系统上查到流量的，不显示云存储

  所谓流量捆绑：只能用配的sim卡，无法使用其他卡。所谓流量不捆绑：可以使用其他sim卡。
  */
  Future<bool> is4GDataFlowBindDevice(String did) async {
    if (deviceModel == null) return false;
    //首先判断设备ID
    var list = did.split(RegExp(r'[0-9]+'));
    String head = '';
    if (list.length == 2) {
      head = list.first;
      if (head.toUpperCase().endsWith('LX')) {
        //设备ID的前缀以LX结尾的 都认为是流量绑定的设备
        deviceModel!.is4GDataFlowBind.value = true;
        print("-----is4GDataFlowBind---true-----------");
        return true;
      }
    }

    if (!deviceModel!.isSupportSIMCard.value) {
      //不支持SIM卡
      deviceModel!.is4GDataFlowBind.value = false;
      return false;
    }

    if (deviceModel!.isSupportLowPower.value) {
      deviceModel!.is4GDataFlowBind.value = false;
      return false;
    }
    return false;

    // var is4Gbind = await DeviceManager().get4GDataBind(did);
    // if (is4Gbind != null) {
    //   model.is4GDataFlowBind.value = is4Gbind == "1";
    //   return is4Gbind == "1";
    // }
    //
    // String ccid = model.simCardCcid.value;
    // String cardOperator = model.simCardOperator.value;
    //
    // if (ccid == null || ccid.isEmpty) return false;
    //
    // Response response;
    //
    // ///是LWLX前缀的VUID
    // bool isLWLX = did.toUpperCase().startsWith("LWLX");
    // bool isBWLX = did.toUpperCase().startsWith("BWLX");
    //
    // if (isLWLX == true) {
    //   response = await AppWebApi().requestQueryLWLX4GCard(ccid);
    // } else if (isBWLX == true) {
    //   response = await AppWebApi().requestQueryBWLX4GCard(ccid);
    // } else {
    //   if (cardOperator == null) {
    //     cardOperator = "0";
    //   }
    //   String cardOpe = "0";
    //   if (cardOperator == "1") {
    //     cardOpe = "CMCC";
    //   } else if (cardOperator == "2") {
    //     cardOpe = "CUCC";
    //   } else if (cardOperator == "3") {
    //     cardOpe = "CTCC";
    //   }
    //
    //   var list = did.split(RegExp(r'[0-9]+'));
    //   String head = '';
    //   if (list.length == 2) {
    //     head = list.first;
    //   }
    //
    //   var user = await UserManager().currentUser();
    //   if (did.toUpperCase().startsWith('ZY') ||
    //       did.toUpperCase().startsWith('LWO') ||
    //       did.toUpperCase().startsWith('XTLX') ||
    //       head.toUpperCase().endsWith('LX')) {
    //     //中亿、博冠 讯互通
    //     response = await AppWebApi()
    //         .requestQuery4GCardOther(user.id, user.authKey, ccid);
    //   } else {
    //     response = await AppWebApi()
    //         .requestAdd4GCard(user.id, user.authKey, ccid, cardOpe);
    //   }
    // }
    //
    // if (isBWLX == true) {
    //   if (response.statusCode == 200) {
    //     Map data = response.data;
    //     String code = data['respStatus']['code'].toString();
    //     if (code == '0000' && data['respBody'] != null) {
    //       await DeviceManager().set4GDataBind(model.id, "1");
    //       model.is4GDataFlowBind.value = true;
    //       return true;
    //     } else {
    //       if (code == "2005" || code == "2008") {
    //         //未知卡
    //         await DeviceManager().set4GDataBind(model.id, "0");
    //         model.is4GDataFlowBind.value = false;
    //         return false;
    //       }
    //     }
    //   }
    //   return false;
    // }
    //
    // if (response.statusCode == 200) {
    //   if (response.data.toString().isNotEmpty) {
    //     Map data = response.data;
    //     if (data.isNotEmpty && data.keys.length > 0) {
    //       await DeviceManager().set4GDataBind(model.id, "1");
    //       model.is4GDataFlowBind.value = true;
    //       return true;
    //     }
    //   }
    // } else if (response.statusCode == 404) {
    //   //未知卡
    //   await DeviceManager().set4GDataBind(model.id, "0");
    //   model.is4GDataFlowBind.value = false;
    //   return false;
    // }
    //
    // return false;
  }

  ///看守卫位置
  Future<int> getGuardIndex(String deviceId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getInt('${deviceId}_guard_index') ?? -1;
  }

  ///看守卫位置
  Future<bool> setGuardIndex(int index, String deviceId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.setInt('${deviceId}_guard_index', index);
  }
}
