import 'package:vsdk/app_player.dart';
import 'package:vsdk_example/play/app_extension.dart';
import 'package:vsdk_example/utils/device_manager.dart';
import 'package:vsdk_example/utils/super_put_controller.dart';

import '../model/cloud_info_model.dart';
import '../model/cloud_video_model.dart';
import '../utils/app_web_api.dart';
import '../utils/device_info.dart';
import 'cloud_play_state.dart';

class CloudPlayLogic extends SuperPutController<CloudPlayState> {
  late AppPlayerController controller;
  late NetworkVideoSource videoSource;
  DeviceInfo? deviceInfo;
  String? dataKey;

  ///403 视频地址过期
  List<String> urls = [
    "http://d015-z0.eye4.cn//tmp/HTB0005151PQSU_2023-11-10-18-09-13_01_1?e=1699846634&token=l5gvKghs6BCqoVtQJOkLwykc7JtTnXvUCGgl2AzZ:JKK7WZ26VI-YDDhjVVKFTaPZWWY="
  ];

  CloudPlayLogic() {
    value = CloudPlayState();
  }

  @override
  void onInit() {
    print("-------onInit-------------");
    init();
    initKey(); //今日数据的key
    getCloudData();
    // checkDevicePush();
    super.onInit();
  }

  void initKey() {
    DateTime today = DateTime.now();
    String deviceId = DeviceManager.getInstance().mDevice!.id;
    dataKey = "${today.year}-${today.month}-${today.day - 1}-$deviceId";
  }

  @override
  void onClose() {
    print("-------onClose-------------");
    controller.removeProgressChangeCallback(onProgress);
    controller.dispose();
    super.onClose();
  }

  ///视频播放状态监听回调
  void playChange(userData, VideoStatus videoStatus, VoiceStatus voiceStatus,
      RecordStatus recordStatus, SoundTouchType touchType) {
    state?.playChange.value = state?.playChange.value ?? 0 + 1;
    state?.voiceStatus = voiceStatus;
    state?.videoStatus.value = videoStatus;

    print(
        "CloudPlayLogic --------------videoStatus:$videoStatus voiceStatus:$voiceStatus recordStatus:$recordStatus touchType:$touchType");
  }

  ///视频信息监听回调
  void onProgress(dynamic userData, int totalSec, int playSec, int progress,
      int loadState, int velocity) async {
    print("-------CloudPlayLogic------playSec-$playSec------------");
  }

  void init() async {
    controller = AppPlayerController();
    print("-------urls------${urls.length}-------------");
    videoSource = NetworkVideoSource(urls);
    controller.setStateChangeCallback(playChange);
    controller.addProgressChangeCallback(onProgress);
    controller.setCreatedCallback((data) async {
      await setSubPlayer();
      print("-------setCreatedCallback-------------------");
      await controller.setVideoSource(videoSource);
      await controller.startVoice();
      await controller.start();
    });
  }

  Future<void> getCloudData() async {
    ///1、查询云存储信息
    await getCloudInfoModel();

    ///2、获取云存储licence key
    int? result =
        await getCloudLicensekey(DeviceManager.getInstance().mDevice!.id);
    if (result == null) {
      print(
          "------------------getCloudLicensekey result null------------------");
      // return;
    }
    if (result == 550) {
      print("没有开通云存储  ====");
    } else {
      print("已开通云存储  $result====");
    }

    ///3、获取云存储视频地址
    if (DeviceManager.getInstance().deviceModel?.isSupportLowPower.value ??
        false) {
      print("----获取低功耗云存储数据--------------");
      // getCloudVideoUrl();
      urls = [
        "http://d015-z0.eye4.cn//tmp/VQDG0000729ZSZT_2023-12-09-15-22-46_936_1762331682_8?e=1702110183&token=l5gvKghs6BCqoVtQJOkLwykc7JtTnXvUCGgl2AzZ:w8ST8tXWCCnbLYQ1-zCQdLscgwc=",
        "http://d015-z0.eye4.cn//tmp/VQDG0000729ZSZT_2023-12-09-15-22-49_526_1018818181_9?e=1702110183&token=l5gvKghs6BCqoVtQJOkLwykc7JtTnXvUCGgl2AzZ:rRi2j9raTDcaIpMx_cos99WgRK4="
      ];
      await controller.stop();
      await controller.setVideoSource(NetworkVideoSource(urls));
      await controller.start();
      return;
    } else {
      print("----获取长电云存储数据--------------");
      deviceInfo = DeviceManager.getInstance().getDeviceInfo();
      if (deviceInfo == null ||
          deviceInfo?.cloudUrl == null ||
          deviceInfo?.cloudLicenseKey == null ||
          deviceInfo!.cloudUrl!.isEmpty ||
          deviceInfo!.cloudLicenseKey!.isEmpty) {
        return;
      }

      ///获取长电的云存储视频地址，demo 只查询当天的，可根据需求查询指定日期的
      await requestCloudVideoOneDay(
          deviceInfo!.id, DateTime.now(), deviceInfo!);

      ///获取某个视频url
      if (cloudDataMap.isEmpty) return;
      await getVideoUrl(deviceInfo!);
    }
  }

  Future<void> getVideoUrl(DeviceInfo device) async {
    state?.keyList.value = cloudDataMap[dataKey] ?? [];
    String videoKey = cloudDataMap[dataKey]![0].original.first.segmenKey.value;
    await getUrlAndPlay(videoKey);
  }

  Future<void> getUrlAndPlay(String videoKey) async {
    if (deviceInfo == null) return;
    var response = await AppWebApi().requestCloudVideo(
        deviceInfo!.cloudUrl!,
        deviceInfo!.cloudLicenseKey!,
        [videoKey],
        deviceInfo!.id,
        null,
        null,
        true);
    print("---某视频url--response--${response.toString()}--------");
    //---某视频url--response--[{name: VE0005622QHOW_2023-11-29:03_50_29_06, url: http://d004-vstc.eye4.cn/VE0005622QHOW_2023-11-29:03_50_29_06?e=1701264785&token=l5gvKghs6BCqoVtQJOkLwykc7JtTnXvUCGgl2AzZ:3QHpPvjYp2LZrQ0tpCjG1AqzYmk=}]--------
    if (response.data is List) {
      List array = response.data;
      if (array.length > 0) {
        String url = array[0]["url"];
        print("-cloud---video--url---$url-----------");
        await resetVideoAndPlay(url);
      }
    }
  }

  Future<void> resetVideoAndPlay(String url) async {
    if (url.isNotEmpty) {
      await controller.stop();
      videoSource = NetworkVideoSource([url]);
      await controller.setVideoSource(videoSource);
      // await controller.startVoice();
      await controller.start();
    }
  }

  //存储某个设备某天的云存储GroupList数据
  static Map<String, List> cloudDataMap = {};
  static DateTime todayDate = DateTime.now();

  ///获取低功耗云存储视频地址
  ///[d009]从消息中获取该参数
  Future<List<String>> getCloudVideoUrl() async {
    // var response = await AppWebApi().requestCouldUrl(
    //     d009Id, "D009",
    //     cancelToken: cancelToken, useCache: false);
    // if (response.statusCode == 200) {
    //   List? array = response.data;
    //   if (array == null || array.isEmpty) {
    //     return [];
    //   }
    //   List<String> urls = [];
    //   for (Map item in array) {
    //     String fileUrl = item["file_name"];
    //     String fileType = item["file_Type"];
    //     if (fileType == "video") {
    //       if (!urls.contains(fileUrl)) urls.add(fileUrl);
    //     }
    //   }
    //   return urls;
    // }
    return [];
  }

  ///请求指定日期的云存储数据
  Future<bool> requestCloudVideoOneDay(
      String deviceId, DateTime date, DeviceInfo deviceInfo) async {
    var dataList = <CloudVideoGroupModel>[];
    bool isTodayRequest = date.isAtSameMomentAs(DateTime.now());
    if (todayDate.difference(date).inHours > 24) {
      if (cloudDataMap.containsKey(dataKey)) {
        dataList
            .addAll(cloudDataMap[dataKey] as Iterable<CloudVideoGroupModel>);
        return true;
      }
    }

    ///通过URL和licenseKey获取云存储数据
    var response = await AppWebApi().requestCloudOneDay(
        deviceInfo.cloudUrl!,
        deviceInfo.cloudLicenseKey!,
        '${date.year}-${date.month.toStringDigits(2)}-${date.day.toStringDigits(2)}',
        deviceId,
        null,
        null,
        isTodayRequest ? false : true);
    print("---long--requestCloudVideoOneDay----${response.toString()}-------");
    if (response.statusCode == 200) {
      var addDate = DateTime.fromMillisecondsSinceEpoch(
          deviceInfo.time.millisecondsSinceEpoch);
      var addSeconds =
          addDate.hour * 3600 + addDate.minute * 60 + addDate.second;
      bool dealWithGroup = false;
      if (DateTime(date.year, date.month, date.day)
              .compareTo(DateTime(addDate.year, addDate.month, addDate.day)) ==
          0) {
        //添加的同一天
        dealWithGroup = true;
      }
      //[
      //     {
      //         "start": 42629,
      //         "end": 42891,
      //         "duration": 262,
      //         "original": [
      //             {
      //                 "key": "2023-11-29:03_50_29_06",
      //                 "hour": "11",
      //                 "type": "h264",
      //                 "eventMark": "1",
      //                 "start_index": 42629,
      //                 "end_index": 42635
      //             },
      //             {
      //                 "key": "2023-11-29:03_50_35_06",
      //                 "hour": "11",
      //                 "type": "h264",
      //                 "eventMark": "1",
      //                 "start_index": 42635,
      //                 "end_index": 42641
      //             }
      //         ]
      //     },
      //     {
      //         "start": 49584,
      //         "end": 49668,
      //         "duration": 84,
      //         "original": [
      //             {
      //                 "key": "2023-11-29:05_46_24_06",
      //                 "hour": "13",
      //                 "type": "h264",
      //                 "eventMark": "1",
      //                 "start_index": 49584,
      //                 "end_index": 49590
      //             },
      //             {
      //                 "key": "2023-11-29:05_46_30_06",
      //                 "hour": "13",
      //                 "type": "h264",
      //                 "eventMark": "1",
      //                 "start_index": 49590,
      //                 "end_index": 49596
      //             },
      //         ]
      //     },]}]

      ///对取到的数据进行处理
      if (response.data.length > 0) {
        print("------response.data----${response.data[0].toString()}--------");
        //处理某一天的云存储Group数据,demo 只取list的第一个
        for (Map itemMap in response.data) {
          var groupModel = CloudVideoGroupModel(deviceId, itemMap);
          groupModel.groupDate = date; //查询日期
          groupModel.cameraName.value = deviceInfo.name;
          groupModel.startTime.value = itemMap['start'];
          groupModel.endTime.value = itemMap['end'];
          groupModel.duration.value = itemMap['duration'];

          //开始 ------时间转换为时间戳作为24小时实时录像时间轴用------
          DateTime dateTime = date;
          int year = dateTime.year;
          int month = dateTime.month;
          int day = dateTime.day;
          var time = DateTime(year, month, day, 0, 0, 0, 0, 0)
                  .millisecondsSinceEpoch ~/
              1000;
          int startTime = time + groupModel.startTime.value;
          int endTime = time + groupModel.endTime.value;
          groupModel.start = "$startTime";
          groupModel.end = "$endTime";
          groupModel.isRealTimeCloud = false;
          //结束------时间转换为时间戳作为24小时实时录像时间轴用------

          if (itemMap['original'] is List) {
            for (Map item in itemMap['original']) {
              var segmentModel = VideoSegment();
              segmentModel.segmenKey.value = item['key'].toString();
              segmentModel.hour.value =
                  int.tryParse(item['hour'].toString()) ?? 0;
              segmentModel.type.value = item['type'];
              segmentModel.eventMark.value = item['eventMark'].toString();
              segmentModel.start_index.value = item['start_index'];
              segmentModel.end_index.value = item['end_index'];
              segmentModel.start = time + segmentModel.start_index.value;
              segmentModel.end = time + segmentModel.end_index.value;

              //将视频片段添加至group
              groupModel.original.add(segmentModel);
            }
          }
          // if (dealWithGroup == true) {
          //   if (groupModel.startTime.value < addSeconds) {
          //     continue;
          //   } else {
          //     dataList.insert(0, groupModel);
          //   }
          // } else {
          //   dataList.insert(0, groupModel);
          // }
          //将视频Group添加至list
          dataList.add(groupModel);
        }
        print("----long-cloud-dataList-${dataList.length}---------------");
        if (dataKey == null) {
          initKey();
        }
        cloudDataMap[dataKey!] = dataList;
        requestCloudVideoGroupListCover(dataList);
        return true;
      }
    }
    return false;
  }

  ///获取低功耗和长电的云存储信息，是否开通，开通时间，是否过期等信息
  getCloudInfoModel() async {
    String id = DeviceManager.getInstance().mDevice!.id;
    bool isLowPower =
        DeviceManager.getInstance().deviceModel!.isSupportLowPower.value;
    CloudInfoModel model = CloudInfoModel(id);
    if (isLowPower) {
      ///低功耗低云存储信息
      return await getLowPowerCloudInfoModel(model, id);
    } else {
      ///长电云存储信息
      return await getLongPowerCloudInfoModel(id, model);
    }
  }

  Future<CloudInfoModel> getLongPowerCloudInfoModel(
      String id, CloudInfoModel model) async {
    var info = await getDeviceCloudInfo(id);
    //----getLongPowerCloudInfo--{isOpen: true, key: 7_qiniu_hd, activation: 1, expirationTime: 2023-12-29}-----
    print("----getLongPowerCloudInfo--${info.toString()}-----");
    if (info == null) {
      return model;
    }
    if (info["isOpen"] == true) {
      model.isOpen = true;
      var key = info["key"];
      if (key != null) {
        if (key.toString().substring(0, 1) == "7") {
          model.cycleDays = "7";
        } else {
          model.cycleDays = "30";
        }
      }
      var expirationTime = info["expirationTime"];
      if (expirationTime != null) {
        model.expirationTime = expirationTime.toString();
        var times = expirationTime.split("-").toList();
        int year = int.tryParse(times[0]) ?? 0;
        int month = int.tryParse(times[1]) ?? 0;
        int day = int.tryParse(times[2]) ?? 0;
        DateTime now = _getDateOnly(DateTime.now());
        int diffDay = DateTime(year, month, day).difference(now).inDays;
        model.diffDay = diffDay;
        if (diffDay <= 0) {
          model.isExpiration = true;
        } else {
          model.isExpiration = false;
        }
      }
      model.isTryout = true;
    } else {
      model.isOpen = false;
      //是否试用过期
      model.isTryout = await getCloudTryout(id);
      String? tryOutExpirationTime =
          await DeviceManager.getInstance().getCloudTryTime(id);
      if (tryOutExpirationTime != null) {
        model.tryoutExpirationTime = DateTime.tryParse(tryOutExpirationTime);
      }
      print(
          "----getLongPowerCloudInfoModel--isTryout---${model.isTryout}-----");
    }
    print("----getLongPowerCloudInfoModel--${model.toString()}-----");
    return model;
  }

  Future<bool> getCloudTryout(String did) async {
    // bool isSupport = await getCloudSupport(did);
    // if (isSupport == false) {
    //   return true;
    // }
    var response = await AppWebApi().queryCloudTryoutShow(did);
    bool? tryout;
    if (response.statusCode == 200) {
      tryout = response.data["tryout"];
      if (tryout != null) {
        String? expirationTime = response.data["expirationTime"];
        if (expirationTime != null) {
          await DeviceManager.getInstance()
              .setCloudTryTime(did, expirationTime);
        }
      }
      if (tryout == null) {
        return true;
      }
      return tryout == true;
    }
    return true;
  }

  ///查询是否支持云存储
  Future<bool> getCloudSupport(String did) async {
    var response = await AppWebApi().queryCloudSupport(did);
    if (response.statusCode == 200) {
      bool? isSupport = response.data["isSupport"];
      // area = response?.data["area"];
      if (isSupport == null) {
        return true;
      }
      return isSupport == true;
    }
    return true;
  }

  Future<CloudInfoModel> getLowPowerCloudInfoModel(
      CloudInfoModel model, String id) async {
    var info = await getLowPowerCloudInfo(id);
    print("----getLowPowerCloudInfo--${info.toString()}-----");
    if (info == null) {
      return model;
    }
    if (info["isOpen"] == true) {
      model.isOpen = true;
      model.cycleDays = "30";
      info = info["info"];
      var expirationTime = info!["expirationTime"];
      if (expirationTime != null) {
        model.expirationTime = expirationTime.toString();
        var times = expirationTime.split("-").toList();
        int year = int.tryParse(times[0]) ?? 0;
        int month = int.tryParse(times[1]) ?? 0;
        int day = int.tryParse(times[2]) ?? 0;
        DateTime now = _getDateOnly(DateTime.now());
        int diffDay = DateTime(year, month, day).difference(now).inDays;
        model.diffDay = diffDay - 1;
        if (diffDay <= 0) {
          model.isExpiration = true;
        } else {
          model.isExpiration = false;
        }
      }
    } else {
      model.isOpen = false;
    }
    print("----getLowPowerCloudInfoModel--${model.isExpiration}-----");
    return model;
  }

  DateTime _getDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  ///did 设备id
  Future<Map?> getLowPowerCloudInfo(String did) async {
    var response = await AppWebApi().queryDeviceCloudExpirationTime(did);
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }

  Future<int?> getCloudLicensekey(String id) async {
    DeviceInfo? device = DeviceManager.getInstance().getDeviceInfo();
    if (device == null) {
      print("-------deviceInfo--null---------");
      return null;
    }
    device.cloudUrl = '';
    device.cloudLicenseKey = '';
    //----getLongPowerCloudInfo--{code: 0, msg: success, data: {license: Wq3wZG7EsWido+p8DoqKxpnUPTaGkCNQKIw34iKoXkZjHyiLMsnecCf+w88IvnA2LklN15SEQsbSG+SatDSwNg==, url: http://115.29.253.108:3300}}-----
    var response = await AppWebApi().requestlicensekey(id);
    print('id $id 云存储cloudUrl response ${response.toString()}');
    if (response.statusCode == 200) {
      Map? data = response.data["data"];
      if (data == null) return null;
      print("-yuncunchu--data-$data--------------");
      device.cloudUrl = data["url"];
      device.cloudLicenseKey = data["license"];
      print('id$id cloudUrl ${device.cloudUrl}');
      return response.statusCode;
    }
    return response.statusCode;
  }

  ///查询长电设备的云存储信息
  Future<Map?> getDeviceCloudInfo(String did) async {
    var response = await AppWebApi().getCloudInfo(did);
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }

  Future<bool> checkDevicePush() async {
    var response = await AppWebApi()
        .requestDevicePushLimit(DeviceManager.getInstance().mDevice!.id);
    if (response.statusCode == 200) {
      print("--------push-limit-false---------");
    } else if (response.statusCode == 403) {
      print("--------push-limit-true---------");
    } else if (response.statusCode == 301) {
      print("--------push-limit-301---------");
    }
    return true;
  }

  void startVideo() async {
    if (state!.videoStatus.value == VideoStatus.PLAY) {
      await controller.stop();
    }
    await controller.start();
  }

  void stopVideo() {
    controller.stop();
  }

  void pauseVideo() {
    controller.pause();
  }

  void resumeVideo() {
    controller.resume();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  ///设置多目播放器
  Future<bool> setSubPlayer() async {
    bool bl = false;

    ///创建多目设备的播放控制器
    int sensor = DeviceManager.getInstance()
            .deviceModel
            ?.supportMutilSensorStream
            .value ??
        0;

    int splitScreen =
        DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;

    ///splitScreen=1 代表二目分屏为三目，为假三目。只有splitScreen !=1 时才是真三目
    if (sensor == 3 && splitScreen != 1) {
      bl = await enableCloudSubPlayer(sub2Player: true);
      print("-----------3-------enableSubPlayer---$bl---------------");
    } else if (sensor == 1 || (sensor == 3 && splitScreen == 1)) {
      ///二目或者假三目
      bl = await enableCloudSubPlayer();
      print("-----------2-------enableSubPlayer---$bl---------------");
    }
    return bl;
  }

  ///创建多目播放器
  Future<bool> enableCloudSubPlayer({bool sub2Player = false}) async {
    if (controller.sub_controller != null) return true;
    var subController = AppPlayerController();

    var result = await subController.create();
    if (result != true) {
      print("-------------subController.create---false---------------");
      return false;
    }
    result = await subController.setVideoSource(SubPlayerSource());
    if (result != true) {
      print("-------------subController.setVideoSource---false---------------");
      return false;
    }
    await subController.start();
    result = await controller.enableSubPlayer(subController);
    if (result != true) {
      print("-------------enableSubPlayer---false---------------");
      return false;
    }
    state?.cloudPlayer2Controller = subController;

    //sub2Player
    if (sub2Player == true) {
      if (controller.sub2_controller != null) return true;
      var sub2Controller = AppPlayerController();
      var result = await sub2Controller.create();
      if (result != true) {
        print("-------------sub2Controller.create---false---------------");
        return false;
      }
      result = await sub2Controller.setVideoSource(SubPlayerSource());
      if (result != true) {
        print(
            "-------------sub2Controller.setVideoSource---false---------------");
        return false;
      }
      await sub2Controller.start();
      result = await controller.enableSub2Player(sub2Controller);
      if (result != true) {
        print("-------------enableSub2Player---false---------------");
        return false;
      }
      state?.cloudPlayer3Controller = sub2Controller;
    }
    if (sub2Player) {
      state?.cloudHasSubPlay.value = 2;
    } else {
      state?.cloudHasSubPlay.value = 1;
    }
    return true;
  }

  Future<void> requestCloudVideoGroupListCover(
      List<CloudVideoGroupModel> groupList) async {
    DeviceInfo? device = DeviceManager.getInstance().getDeviceInfo();
    if (device == null) {
      print("-------deviceInfo--null---------");
      return null;
    }
    //获取GroupList中每个item中的cover
    for (CloudVideoGroupModel groupModel in groupList) {
      var deviceId = groupModel.deviceId;
      if (device.cloudLicenseKey == null || device.cloudLicenseKey!.isEmpty) {
        var response = await AppWebApi().requestlicensekey(deviceId);
        if (response.statusCode == 200) {
          Map data = response.data;
          device.cloudUrl = data["url"];
          device.cloudLicenseKey = data["licenseKey"];
        } else if (response.statusCode == 550) {
          return;
        }
      }

      var firstVideoSegmentUrl = '';
      var videoKey;
      if (groupModel.original.length > 1) {
        videoKey = groupModel.original[1].segmenKey.value;
      } else {
        videoKey = groupModel.original.first.segmenKey.value;
      }

      //获取第一个视频片段的视频地址
      var response = await AppWebApi().requestCloudVideo(device.cloudUrl!,
          device.cloudLicenseKey!, [videoKey], device.id, null, null, true);

      if (response.statusCode == 200) {
        List data = response.data;
        if (data.isNotEmpty) {
          firstVideoSegmentUrl = data.first["url"];

          response = await AppWebApi().requestCloudCover(
              device.cloudUrl!,
              device.cloudLicenseKey!,
              firstVideoSegmentUrl,
              device.id,
              null,
              null,
              true);
          if (response.statusCode == 200) {
            groupModel.coverUrl.value = response.data["url"];

            ///更新ui
            state!.keyList(groupList);
          }
        }
      }
      if (firstVideoSegmentUrl.isEmpty) continue;
    }
  }
}
