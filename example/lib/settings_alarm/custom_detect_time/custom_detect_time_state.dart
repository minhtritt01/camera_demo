import 'package:get/get.dart';

class CustomDetectTimeState {
  ///小时列表
  var hours = <int>[].obs;

  ///分钟列表
  var minutes = <int>[].obs;

  ///开始hour
  var startHour = 0.obs;

  ///开始miute
  var startMinute = 0.obs;

  ///结束hour
  var endHour = 23.obs;

  ///结束miute
  var endMinute = 59.obs;

  ///日期列表
  var days = <int>[].obs;
}
