import 'package:get/get.dart';

class RecordTimeFrameModel {
  /// 关键帧时间戳
  final DateTime timestamp;

  /// 关键帧序号
  final int frameNo;

  /// 帧间隔
  final int frameGop;

  RecordTimeFrameModel(this.timestamp, this.frameNo, this.frameGop);

  String toString() {
    return ("timestamp:$timestamp "
        "frameNo:$frameNo "
        "frameGop:$frameGop");
  }
}

class RecordTimeLineModel {
  final String recordName;

  final int recordTime;

  /// 0 实时录像
  /// 1 报警录像
  /// 2 人形报警
  final int recordAlarm;

  /// 录像开始时间
  final DateTime recordStart;

  /// 录像结束时间
  final DateTime recordEnd;

  ///录像时长
  final int recordDuration;

  final int frameLen;

  final int frameInterval;

  final int startTime;

  final int endTime;

  final List<RecordTimeFrameModel> frames = [];

  static int _getUtcTime(DateTime time) {
    if (time == null || time.toString().length < 19) {
      return 0;
    }
    String timeStr = time.toString().substring(0, 19);
    var dateTime = DateTime.parse(timeStr);
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  RecordTimeLineModel(
      this.recordName,
      this.recordTime,
      this.recordAlarm,
      this.recordStart,
      this.recordEnd,
      this.recordDuration,
      this.frameLen,
      this.frameInterval)
      : this.startTime = _getUtcTime(recordStart),
        this.endTime = _getUtcTime(recordEnd);

  List<int> getFrameNo(int sec) {
    if (frames.length == 0) return [];
    int timestamp = recordStart.millisecondsSinceEpoch + sec * 1000;
    var model = frames.lastWhere(
        (element) => element.timestamp.millisecondsSinceEpoch <= timestamp,
        orElse: () => frames.first);
    int modelTimestamp = model.timestamp.millisecondsSinceEpoch;
    int frameNo = model.frameNo;

    /// 修正错误的frameNo数值
    if (model == frames.first) frameNo = 0;
    while ((modelTimestamp + (frameInterval * 1000)) <= timestamp) {
      modelTimestamp += (frameInterval * 1000);
      frameNo += model.frameGop;
    }
    // print("frameNo:$frameNo timestamp:${timestamp ~/
    //     1000} modelTimestamp:${modelTimestamp ~/
    //     1000} frameNo:${model.frameNo} frameGop:${model.frameGop} "
    //     "frameInterval:$frameInterval sec:$sec diff:${((modelTimestamp -
    //     recordStart.millisecondsSinceEpoch) ~/ 1000)}");
    return [
      frameNo,
      ((modelTimestamp - recordStart.millisecondsSinceEpoch) ~/ 1000)
    ];
  }

  String toString() {
    return ("recordName:$recordName "
        "recordTime:$recordTime "
        "recordAlarm:$recordAlarm "
        "recordStart:$recordStart "
        "recordEnd:$recordEnd "
        "recordDuration:$recordDuration "
        "frameLen:$frameLen "
        "frameInterval:$frameInterval "
        "frames:$frames ");
  }
}

class RecordFileModel {
  RecordFileModel(this.recordName, this.recordAlarm, this.recordTime,
      this.recordSize, this.recordHead,
      {this.timeLine});

  /// 录像文件名
  String recordName;

  // 0 实时录像
  // 1 报警录像
  // 2 人形侦测
  int recordAlarm;

  /// 报警时间
  DateTime recordTime;

  ///文件大小
  int recordSize;

  int loadSize = 0;

  bool recordHead;

  RecordTimeLineModel? timeLine;

  /// 文件是否选中
  final RxBool selected = false.obs;

  /// 视频加载错误状态
  /// false 没有错误
  /// true 有错误
  final RxBool videoError = false.obs;

  /// 视频加载进度
  /// 为空表示正在等待下载
  /// 不为空则表示当前下载进度
  final RxDouble videoProgress = RxDouble(0);

  String toString() {
    return ("recordName:$recordName "
        "recordAlarm:$recordAlarm "
        "recordTime:$recordTime "
        "recordSize:$recordSize "
        "recordSize:$recordSize ");
  }

  @override
  bool operator ==(Object other) {
    if (super == other) {
      return true;
    }
    if (other is RecordFileModel) {
      return other.recordName == this.recordName;
    }
    return false;
  }
}
