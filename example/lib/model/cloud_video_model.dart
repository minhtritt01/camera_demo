import 'package:get/get.dart';

class VideoSegment {
  VideoSegment();

  var segmenKey = ''.obs;

  var hour = 0.obs;

  var type = ''.obs;

  var eventMark = ''.obs;

  var start_index = 0.obs;

  var end_index = 0.obs;

  //视频段的起始时间
  int start = 0;

  //视频段的结束时间
  int end = 0;
}

enum DownLoadSateType { none, start, success, error, delete, timeout }

class CloudVideoGroupModel {
  CloudVideoGroupModel(this.deviceId, this.data);

  /// 设备ID
  final String deviceId;

  /// 数据源
  final dynamic data;

  var cameraName = ''.obs;

  DateTime? groupDate;

  //视频段的起始时间
  var startTime = 0.obs;

  //视频段的结束时间
  var endTime = 0.obs;

  //持续时间
  var duration = 0.obs;

  var original = RxList<VideoSegment>();

  //视频文件地址列表
  final Rx<List<String>> videoUrls = Rx<List<String>>([]);

  //视频段的封面地址 根据视频列表地址
  var coverUrl = RxString("");

  ///下载
  var downLoadSelected = false.obs;

  ///下载进度
  var downLoadProgress = 0.0.obs;

  ///下载状态
  var downLoadState = Rx<DownLoadSateType>(DownLoadSateType.none);

  ///下载取消
  dynamic cancelToken;

  ///下载 取消
  var cancelSelected = false.obs;

  /// 视频加载进度
  /// 为空表示正在等待下载
  /// 不为空则表示当前下载进度
  final RxDouble videoProgress = RxDouble(0);

  /// 视频加载错误状态
  /// false 没有错误
  /// true 有错误
  final RxBool videoError = false.obs;

  ///>>>>>>>>>>>>>>>>>>>>>>上面是报警云存储数据旧版本的<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  ///24小时实时云存储
  String? url;
  String? start;
  String? end;
  String? durationRT;
  String? format;
  String? snap;
  String? file;
  String? type;
  bool? isRealTimeCloud;

  CloudVideoGroupModel.fromJson(Map json, {required this.deviceId, this.data})
      : this.url = json["url"].toString(),
        this.start = json["start"].toString(),
        this.end = json["end"].toString(),
        this.durationRT = json["duration"].toString(),
        this.format = json["format"].toString(),
        this.snap = json["snap"].toString(),
        this.file = json["file"].toString(),
        this.type = json["type"].toString(),
        this.isRealTimeCloud = true;

  Map toJson() {
    return {
      if (url != null) 'url': url,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (durationRT != null) 'duration': durationRT,
      if (format != null) 'format': format,
      if (snap != null) 'snap': snap,
      if (file != null) 'file': file,
      if (type != null) 'type': type,
      if (isRealTimeCloud != null) 'isRealTimeCloud': isRealTimeCloud,
    };
  }
}
