import 'dart:math';
import 'package:get/get.dart';

enum PlanType {
  none,
  motion,
  human,
  pir,
  whiteLight,
  privacy,
  record,
  recordMotion,
  presetCruisePlan,
  areaIntrusion,
  personStay,
  illegalParking,
  crossBorder,
  offPostMonitor,
  carRetrograde,
  packageDetect,
  fire,
}

class PlanModel {
  String? devId;
  String? startTime;
  String? endTime;
  String? weekData;
  String? weeksStr;
  int sum = 0;

  PlanModel.fromCgi(int num) {
    if (num != 0 && num != -1 && num != 1) {
      int i = 0;
      int j;
      if (num < 0) {
        j = num.abs();
      } else {
        j = num;
      }
      List<int> tmp = List.generate(32, (index) => 0);
      while (j != 0) {
        tmp[i] = j % 2;
        i++;
        j = j ~/ 2;
      }
      for (; i < 31; i++) {
        tmp[i] = 0;
      }

      if (num < 0) {
        tmp[31] = 1;
      } else {
        tmp[31] = 0;
      }

      int start = 0;
      int end = 0;
      String? week;
      int ll = 0;
      for (int m = 0; m < 12; m++) {
        ll = (tmp[m] * pow(2, m)) as int;
        start += ll;
      }

      for (int m = 12, n = 0; m < 24; m++, n++) {
        ll = (tmp[m] * pow(2, n)) as int;
        end += ll;
      }
      bool sunday = false;
      print(tmp);
      for (int m = 24, n = 0; m < 31; m++, n++) {
        if (tmp[m] != 0) {
          if (n == 0) {
            sunday = true;
          } else {
            week = week == null ? '$n' : ('$week' + ',$n');
          }
        }
      }
      if (sunday) {
        week = week == null ? '7' : ('$week' + ',7');
      }
      startTime = _minutesToHours(start);
      endTime = _minutesToHours(end);
      weeksStr = _weeksStr(week);
      weekData = week;
      sum = num;
      print(
          '=>cig:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum');
    }
  }

  ///分钟转小时
  String _minutesToHours(int m) {
    String time;
    int mm = m;
    int rem = 0;
    if (mm < 60) {
      time = '00:${twoDigits(m)}';
    } else {
      mm = mm ~/ 60;
      rem = m % 60;
      time = '${twoDigits(mm)}:${twoDigits(rem)}';
    }
    return time;
  }

  ///返回需要的week
  String _weeksStr(String? week) {
    if (week == null || week == '') return '';

    List weeks = week.split(',').toList();
    print(weeks);
    String w = '';
    if (weeks.length == 7) {
      w = '每天'.tr;
    } else {
      for (int i = 0; i < weeks.length; i++) {
        String? weekStr;
        switch (int.parse(weeks[i])) {
          case 7:
            weekStr = "周日".tr;
            break;
          case 6:
            weekStr = "周六".tr;
            break;
          case 5:
            weekStr = "周五".tr;
            break;
          case 4:
            weekStr = "周四".tr;
            break;
          case 3:
            weekStr = "周三".tr;
            break;
          case 2:
            weekStr = "周二".tr;
            break;
          case 1:
            weekStr = "周一".tr;
            break;
          default:
            break;
        }
        if (weekStr == null) {
          continue;
        }
        String tmp = ' ' + '$weekStr';
        w = '$w' + tmp;
      }
    }
    return w;
  }

  ///获取
  List tmps = [];

  PlanModel.fromPlans(int start, int end, List weeks, String id) {
    devId = id;
    startTime = _minutesToHours(start);
    endTime = _minutesToHours(end);
    String week = '';
    for (int i = 0; i < weeks.length; i++) {
      if (i == weeks.length - 1) {
        week = '$week' + '${weeks[i]}';
      } else {
        week = '$week' + '${weeks[i]},';
      }
    }
    weeksStr = _weeksStr(week);
    weekData = week;
    tmps = List.generate(32, (index) => 0);
    _tenAndTwo(start, 0);
    _tenAndTwo(end, 12);
    _weekAndTwo(week, 24);
    sum = _twoAndTenSum();

    print(
        '=>pan:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum');
  }

  void _tenAndTwo(int num, int index) {
    int jj = index;
    int j;
    if (num < 0) {
      j = (num + 1).abs();
    } else {
      j = num;
    }

    while (j != 0) {
      tmps[index] = j % 2;
      index++;
      j = j ~/ 2;
    }
    for (; index < jj + 12; index++) {
      tmps[index] = 0;
    }
  }

  void _weekAndTwo(String week, int index) {
    if (week == '') {
      tmps[24] = 0;
      tmps[25] = 0;
      tmps[26] = 0;
      tmps[27] = 0;
      tmps[28] = 0;
      tmps[29] = 0;
      tmps[30] = 0;
      tmps[31] = 0;
      return;
    }

    List weeks = week.split(',').toList();
    List temp = List.generate(7, (index) => 0);
    for (int j = 0; j < weeks.length; j++) {
      temp[j] = int.parse(weeks[j]);
    }
    for (int j = 0; j < 7; j++) {
      int m = 0, num = 0;
      if (j == 0) {
        num = 7;
      } else {
        num = j;
      }
      for (; m < weeks.length; m++) {
        if (num == temp[m]) {
          tmps[index] = 1;
          break;
        }
      }
      if (m == weeks.length) {
        tmps[index] = 0;
      }
      index++;
    }
    tmps[31] = 0;
  }

  int _twoAndTenSum() {
    int ll = 0;
    int sum = 0;
    for (int m = 0; m < 31; m++) {
      ll = tmps[m] * pow(2, m);
      sum += ll;
    }
    return sum;
  }

  String twoDigits(int? n) {
    if (n == null) {
      return "";
    }
    if (n >= 10) return "$n";
    return "0$n";
  }
}

class WhiteLightPlanModel {
  String? devId;
  String? startTime;
  String? endTime;
  String? weekData;
  String? weeksStr;
  int sum = 0;

  var mark = ''.obs;
  var enable = false.obs; //计划是否执行
  var onOff = false.obs; //开灯 或者 关灯

  WhiteLightPlanModel.fromCgi(int num, bool enableValue, bool onOffValue) {
    if (num != 0 && num != -1 && num != 1) {
      int i = 0;
      int j;
      if (num < 0) {
        j = num.abs();
      } else {
        j = num;
      }
      List<int> tmp = List.generate(32, (index) => 0);
      while (j != 0) {
        tmp[i] = j % 2;
        i++;
        j = j ~/ 2;
      }
      for (; i < 31; i++) {
        tmp[i] = 0;
      }

      if (num < 0) {
        tmp[31] = 1;
      } else {
        tmp[31] = 0;
      }

      int start = 0;
      int end = 0;
      String? week;
      int ll = 0;
      for (int m = 0; m < 12; m++) {
        ll = (tmp[m] * pow(2, m)) as int;
        start += ll;
      }

      for (int m = 12, n = 0; m < 24; m++, n++) {
        ll = (tmp[m] * pow(2, n)) as int;
        end += ll;
      }
      bool sunday = false;
      print(tmp);
      for (int m = 24, n = 0; m < 31; m++, n++) {
        if (tmp[m] != 0) {
          if (n == 0) {
            sunday = true;
          } else {
            week = week == null ? '$n' : ('$week' + ',$n');
          }
        }
      }
      if (sunday) {
        week = week == null ? '7' : ('$week' + ',7');
      }
      startTime = _minutesToHours(start);
      endTime = _minutesToHours(end);
      weeksStr = _weeksStr(week!);
      weekData = week;
      sum = num;
      print(
          '==>>WhiteLightPlanModel.fromCgi:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum');
    }
    enable.value = enableValue;
    onOff.value = onOffValue;
  }

  ///分钟转小时
  String _minutesToHours(int m) {
    String time;
    int mm = m;
    int rem = 0;
    if (mm < 60) {
      time = '00:${twoDigits(m)}';
    } else {
      mm = mm ~/ 60;
      rem = m % 60;
      time = '${twoDigits(mm)}:${twoDigits(rem)}';
    }
    return time;
  }

  ///返回需要的week
  String _weeksStr(String week) {
    if (week.isEmpty) {
      return '仅一次'.tr;
    }

    List weeks = week.split(',').toList();
    print(weeks);
    String w = '';

    if (weeks.length == 7) {
      w = '每天'.tr;
    } else {
      for (int i = 0; i < weeks.length; i++) {
        String? weekStr;
        switch (int.parse(weeks[i])) {
          case 7:
            weekStr = "周日".tr;
            break;
          case 6:
            weekStr = "周六".tr;
            break;
          case 5:
            weekStr = "周五".tr;
            break;
          case 4:
            weekStr = "周四".tr;
            break;
          case 3:
            weekStr = "周三".tr;
            break;
          case 2:
            weekStr = "周二".tr;
            break;
          case 1:
            weekStr = "周一".tr;
            break;
          default:
            break;
        }
        if (weekStr == null) {
          continue;
        }
        String tmp = ' ' + '$weekStr';
        w = '$w' + tmp;
      }
    }
    return w.trimLeft();
  }

  ///获取
  List tmps = [];

  WhiteLightPlanModel.fromPlans(int start, int end, List weeks, String id,
      bool enableValue, bool onOffValue, String markString) {
    devId = id;
    startTime = _minutesToHours(start);
    endTime = _minutesToHours(end);
    String week = '';
    for (int i = 0; i < weeks.length; i++) {
      if (i == weeks.length - 1) {
        week = '$week' + '${weeks[i]}';
      } else {
        week = '$week' + '${weeks[i]},';
      }
    }
    weeksStr = _weeksStr(week);
    weekData = week;
    tmps = List.generate(32, (index) => 0);
    _tenAndTwo(start, 0);
    _tenAndTwo(end, 12);
    _weekAndTwo(week, 24);
    sum = _twoAndTenSum();

    mark.value = markString;
    enable.value = enableValue;
    onOff.value = onOffValue;

    print(
        '==>>WhiteLightPlanModel.fromPlans:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum\n enable:$enable\n onOff:${onOff}');
  }

  void _tenAndTwo(int num, int index) {
    int jj = index;
    int j;
    if (num < 0) {
      j = (num + 1).abs();
    } else {
      j = num;
    }

    while (j != 0) {
      tmps[index] = j % 2;
      index++;
      j = j ~/ 2;
    }
    for (; index < jj + 12; index++) {
      tmps[index] = 0;
    }
  }

  void _weekAndTwo(String week, int index) {
    List weeks = week.split(',').toList();
    List temp = List.generate(7, (index) => 0);
    for (int j = 0; j < weeks.length; j++) {
      temp[j] = int.parse(weeks[j]);
    }
    for (int j = 0; j < 7; j++) {
      int m = 0, num = 0;
      if (j == 0) {
        num = 7;
      } else {
        num = j;
      }
      for (; m < weeks.length; m++) {
        if (num == temp[m]) {
          tmps[index] = 1;
          break;
        }
      }
      if (m == weeks.length) {
        tmps[index] = 0;
      }
      index++;
    }
    tmps[31] = 0;
  }

  int _twoAndTenSum() {
    int ll = 0;
    int sum = 0;
    for (int m = 0; m < 31; m++) {
      ll = tmps[m] * pow(2, m);
      sum += ll;
    }
    return sum;
  }

  String twoDigits(int? n) {
    if (n == null) {
      return "";
    }
    if (n >= 10) return "$n";
    return "0$n";
  }
}

class PresetCruiseLineModel {
  final int num;
  var speed = 10.obs;
  var time = 10.obs; //stoptime
  var index = 0.obs;

  PresetCruiseLineModel(this.num);
}

// class PresetCruisePlanModel {
//   String devId;
//   String startTime;
//   String endTime;
//   String weekData;
//   String weeksStr;
//   int sum;
//
//   PresetCruisePlanModel.fromCgi(int num) {
//     if (num != 0 && num != -1 && num != 1) {
//       int i = 0;
//       int j;
//       if (num < 0) {
//         j = num.abs();
//       } else {
//         j = num;
//       }
//       List<int> tmp = List(32);
//       while (j != 0) {
//         tmp[i] = j % 2;
//         i++;
//         j = (j / 2).toInt();
//       }
//       for (; i < 31; i++) {
//         tmp[i] = 0;
//       }
//
//       if (num < 0) {
//         tmp[31] = 1;
//       } else {
//         tmp[31] = 0;
//       }
//
//       int start = 0;
//       int end = 0;
//       String week;
//       int ll = 0;
//       for (int m = 0; m < 12; m++) {
//         ll = tmp[m] * pow(2, m);
//         start += ll;
//       }
//
//       for (int m = 12, n = 0; m < 24; m++, n++) {
//         ll = tmp[m] * pow(2, n);
//         end += ll;
//       }
//       bool sunday = false;
//       print(tmp);
//       for (int m = 24, n = 0; m < 31; m++, n++) {
//         if (tmp[m] != 0) {
//           if (n == 0) {
//             sunday = true;
//           } else {
//             week = week == null ? '$n' : ('${week}' + ',${n}');
//           }
//         }
//       }
//       if (sunday) {
//         week = week == null ? '7' : ('${week}' + ',7');
//       }
//       startTime = _minutesToHours(start);
//       endTime = _minutesToHours(end);
//       weeksStr = _weeksStr(week);
//       weekData = week;
//       sum = num;
//       print(
//           '==>>PresetCruisePlanModel.fromCgi:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum');
//     }
//   }
//
//   ///分钟转小时
//   String _minutesToHours(int m) {
//     String time;
//     int mm = m;
//     int rem = 0;
//     if (mm < 60) {
//       time = '00:${twoDigits(m)}';
//     } else {
//       mm = (mm / 60).toInt();
//       rem = m % 60;
//       time = '${twoDigits(mm)}:${twoDigits(rem)}';
//     }
//     return time;
//   }
//
//   ///返回需要的week
//   String _weeksStr(String week) {
//     if (week == '') return '';
//
//     if (week.isEmpty) {
//       return '仅一次'.tr;
//     }
//
//     List weeks = week.split(',').toList();
//     print(weeks);
//     String w = '';
//
//     if (weeks.length == 7) {
//       w = '每天'.tr;
//     } else {
//       for (int i = 0; i < weeks.length; i++) {
//         String weekStr;
//         switch (int.parse(weeks[i])) {
//           case 7:
//             weekStr = "周日".tr;
//             break;
//           case 6:
//             weekStr = "周六".tr;
//             break;
//           case 5:
//             weekStr = "周五".tr;
//             break;
//           case 4:
//             weekStr = "周四".tr;
//             break;
//           case 3:
//             weekStr = "周三".tr;
//             break;
//           case 2:
//             weekStr = "周二".tr;
//             break;
//           case 1:
//             weekStr = "周一".tr;
//             break;
//           default:
//             break;
//         }
//         if (weekStr == null) {
//           continue;
//         }
//         String tmp = ' ' + '$weekStr';
//         w = '${w}' + tmp;
//       }
//     }
//     return w.trimLeft();
//   }
//
//   ///获取
//   List tmps;
//
//   PresetCruisePlanModel.fromPlans(int start, int end, List weeks, String id){
//     devId = id;
//     startTime = _minutesToHours(start);
//     endTime = _minutesToHours(end);
//     String week = '';
//     for (int i = 0; i < weeks.length; i++) {
//       if (i == weeks.length - 1) {
//         week = '${week}' + '${weeks[i]}';
//       } else {
//         week = '$week' + '${weeks[i]},';
//       }
//     }
//     weeksStr = _weeksStr(week);
//     weekData = week;
//     tmps = List(32);
//     _tenAndTwo(start, 0);
//     _tenAndTwo(end, 12);
//     _weekAndTwo(week, 24);
//     sum = _twoAndTenSum();
//
//     print(
//         '==>>PresetCruisePlanModel.fromPlans:\n start:$startTime\n end:$endTime\n weeksStr:$weeksStr\n weekData:$weekData\n sum:$sum');
//   }
//
//   void _tenAndTwo(int num, int index) {
//     int jj = index;
//     int j;
//     if (num < 0) {
//       j = (num + 1).abs();
//     } else {
//       j = num;
//     }
//
//     while (j != 0) {
//       tmps[index] = j % 2;
//       index++;
//       j = (j / 2).toInt();
//     }
//     for (; index < jj + 12; index++) {
//       tmps[index] = 0;
//     }
//   }
//
//   void _weekAndTwo(String week, int index) {
//     if (week == '') {
//       tmps[24] = 0;
//       tmps[25] = 0;
//       tmps[26] = 0;
//       tmps[27] = 0;
//       tmps[28] = 0;
//       tmps[29] = 0;
//       tmps[30] = 0;
//       tmps[31] = 0;
//       return;
//     }
//
//     List weeks = week.split(',').toList();
//     List temp = List(7);
//     for (int j = 0; j < weeks.length; j++) {
//       temp[j] = int.parse(weeks[j]);
//     }
//     for (int j = 0; j < 7; j++) {
//       int m = 0,
//           num = 0;
//       if (j == 0) {
//         num = 7;
//       } else {
//         num = j;
//       }
//       for (; m < weeks.length; m++) {
//         if (num == temp[m]) {
//           tmps[index] = 1;
//           break;
//         }
//       }
//       if (m == weeks.length) {
//         tmps[index] = 0;
//       }
//       index++;
//     }
//     tmps[31] = 0;
//   }
//
//   int _twoAndTenSum() {
//     int ll = 0;
//     int sum = 0;
//     for (int m = 0; m < 31; m++) {
//       ll = tmps[m] * pow(2, m);
//       sum += ll;
//     }
//     return sum;
//   }
//
//   String twoDigits(int n) {
//     if (n == null) {
//       return "";
//     }
//     if (n >= 10) return "$n";
//     return "0$n";
//   }
//
// }

class PlanManager {
  /// 单例
  static PlanManager? _instance;

  /// 将构造函数指向单例
  factory PlanManager() => getInstance();

  PlanManager._internal();

  ///获取单例
  static PlanManager getInstance() {
    if (_instance == null) {
      _instance = new PlanManager._internal();
    }
    return _instance!;
  }

  ///白光计划
  List<PlanModel> lightPlans = [];
}
