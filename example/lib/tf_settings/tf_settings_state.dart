import '../model/device_model.dart';
import 'package:get/get.dart';

class TFSettingsState {
  ///TF录像分辨率, 0 超高清，录像最短；1 高清，录像短；2 标清，录像长
  var tfResolution = 2.obs;

  ///录像模式，0：24小时录像，1：计划录像，2:运动侦测录像，3:不录像
  var recordModel = 0.obs;

  ///录制声音开关
  var audioSwitch = false.obs;

  ///正在格式化
  var isFormating = false.obs;

  var times = 0.obs; //查询TF状态次数，最多30次
}
