import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:vsdk_example/model/plan_model.dart';

enum NightVisionMode {
  NightVisionHeiBai, //黑白夜视
  NightVisionQuanCai, //全彩夜视
  NightVisionZhiNeng, //智能夜视
  NightVisionAuto, //自动夜视
  NightVisionOpen,
  NightVisionClose,
  NightVisionNone,
  NightVisionQuanCai_suiguangxian, //全彩夜视-随光线
  NightVisionQuanCai_changliang, //全彩夜视-常亮
  NightVisionQuanCai_dinshi, //全彩夜视-定时
  NightVisionXingGuang, //星光夜视
}

enum DeviceOnLineState {
  offline,
  deepSleep,
  sleep,
  online,
  poweroff,
  microPower,
  lowPowerOff,
  none
}

enum DeviceConnectState {
  connecting, //连接中
  logging, //登录中
  connected, //在线
  timeout, //连接超时
  disconnect, //连接中断
  password, //密码错误
  maxUser, //观看人数过多
  offline, //离线
  illegal, //非法
  none,
}

enum LowMode {
  none,
  low,
  veryLow,
  smart,
}

enum CameraVideoDirection {
  none,
  mirror,
  flip,
  mirrorAndFlip,
}

///云台控制
enum MotorVerticalDirection {
  up,
  down,
  stopUp,
  stopDown,
  vertical,
}

enum MotorHorizontalDirection {
  left,
  right,
  stopLeft,
  stopRight,
  horizontal,
}

enum MotorDirection {
  startUp,
  startDown,
  stopUp,
  stopDown,
  vertical,
  stopVertical,
  startLeft,
  startRight,
  stopLeft,
  stopRight,
  horizontal,
  stopHorizontal,
  circleLoop,
  verticalLoop,
  polylineLoop,
  startPresetCruise,
  stopPresetCruise,
}

enum AiType {
  areaIntrusion, //区域入侵 ==0
  personStay, //人员逗留 ==1
  illegalParking, //车违停 ==2
  crossBorder, //越线报警==3
  offPostMonitor, //离岗检测==4
  carRetrograde, //车辆逆行==5
  packageDetect, //包裹出现 == 6
  fireSmokeDetect, //烟火 == 7 ???
  none
}

class PresetModel {
  final String filePath;
  final int index;
  final File file;
  final bool isExist;

  PresetModel(this.filePath, this.index, this.file, this.isExist);
}

class DeviceModel {
  DeviceModel(this.id, this.data);

  final String id;

  /// 数据源
  /// [DeviceInfo]
  dynamic data;

  ///设备名字
  var name = 'IP Camera'.obs;

  //设备的添加时间 毫秒
  var addTime = 0.obs;

  var connectState = Rx<DeviceConnectState>(DeviceConnectState.none);
  var onLineStatus = Rx<DeviceOnLineState>(DeviceOnLineState.none);

  var cameraDirection = Rx<CameraVideoDirection>(CameraVideoDirection.none);

  ///大图缩略图
  var backgroundImage = Rx<File?>(null);
  var backgroundImageSub = Rx<File?>(null);

  var isLocalDevice = RxBool(false);

  var isSetTopDevice = RxBool(false);
  var isRestrictedDevice = RxBool(false);
  var isSharedDevice = RxBool(false);
  var isSupportCloud = RxBool(false); //是否支持云存储
  var isCloudStorageState = RxBool(false); //当前设备的云云存储否开通正常
  var isSupportSIMCard = RxBool(false);
  var isSupportBattery = RxBool(false);
  var isSupportWifi = RxBool(false);
  var isUnknownSimCard = false.obs;

  var isSupportLowPower = RxBool(false);
  var supportLowPower = RxInt(0);

  var isSupportDVmode = RxBool(false);

  ///是否支持超低功能
  var isSupportDeepLowPower = RxBool(false);

  ///自动唤醒
  var isAutoWakeUp = RxBool(false);

  ///定制自动唤醒
  var cWakeUp = RxBool(false);

  /// 唤醒用户设置标签 -1没有设置  0设置关    1设置开
  var wakeUpbyUserid = RxString("-1");

  ///led灯
  var ledLight = RxBool(false);

  ///led灯
  var isSupportledLight = RxBool(false);

  ///TF卡状态
  var tfCardStatus = RxString("");

  ///SIM信号强度
  var simCardSignalStrength = RxInt(0);

  ///SIM运营商
  var simCardOperator = RxString("");

  ///SIM 内部组织
  // var simCardOrganization = Rx<SimCardOrganization>(SimCardOrganization.none);

  ///SIM卡号
  var simCardCcid = RxString("");

  ///SIM剩余流量
  var simCardFlowRemaining = RxDouble(0);

  ///SIM 流量卡状态 到期断网 达量断网
  var simCardStatus = RxString("");

  ///SIM code
  var simCardCode = RxInt(0);

  ///SIM 未知卡
  var simCardUnknown = RxBool(false);

  ///SIM invDate
  var simInvDate = RxString("");

  ///SIM 距离到期的天数
  var simCardDiffDate = RxInt(0);

  ///SIM 距离到期的秒数
  var simCardDiffSeconds = RxInt(0);

  ///是否已过弹窗
  var isSimCardDialog = RxBool(false);

  ///电池电量
  var batteryRate = RxInt(0);

  ///设备充电
  var isCharge = RxBool(false);

  ///device Mac
  var mac = RxString("");

  ///device 激活时间
  var activation = RxString("");

  ///设备当前固件
  var currentSystemVer = RxString("");

  ///服务器最新固件
  var seviceSystemVer = RxString("");

  ///录像声音开关
  var recordSound = RxBool(false);

  var nightMode = RxBool(false);

  var vertical = RxBool(false);

  var horizontal = RxBool(false);

  var hzmode = RxBool(false);

  var timeOSD = RxBool(false);

  var bright = RxDouble(0);

  var contrast = RxDouble(0);

  //解码模式
  var videoDecode = RxBool(false);

  ///dV 模式
  var dvMode = RxBool(false);

  ///功耗模式M
  var lowMode = Rx<LowMode?>(null);

  ///报警类型
  var alarmType = RxInt(0);

  ///报警开关
  var alarmStatus = RxBool(false);

  ///报警灵敏度
  var alarmLevel = RxInt(0);

  ///录像时长 自动
  var autoRecordMode = RxInt(0);

  ///推送video/image
  var alarmVideoType = RxBool(false);

  ///视频时长
  var alarmTime = RxInt(0);

  ///推送push 服务器开关
  var push = RxBool(false);

  ///离线推送服务器开关
  var offlinePush = RxBool(false);

  var shareCode = RxString("");

  var deviceType = RxString("");

  var sdtotal = RxString("");
  var sdfree = RxString("");

  var wifissid = RxString("");

  // var wifiList = RxList<WifiMode>();

  ///wifi 本地信号 ==保存的缓存
  var wifiSign = RxString("");

  // var currentWifiMode = Rx<WifiMode>(null);

  // var deviceServiceInfo = Rx<DeviceverServiceinfo>(null);

  var inVolume = RxInt(0);

  var outVolume = RxInt(0);

  ///是否支持云台
  var haveMotor = RxBool(false);

  // var shareuserList = RxList<ShareuserModel>();

  ///设备型号 门铃 BPW4
  var modelType = RxString("");

  ///是否为门铃 1:有门铃按键 0:没有门铃按键
  var haveDoorBell = RxString("");

  ///对讲
  var haveHorn = true.obs;

  ///监听
  var haveMic = true.obs;

  ///是否支持H264和H265切换
  var support_h264_h265_shift = RxString("");

  ///是否支持200w和300w切换
  var support_pixel_shift = RxString("");

  ///当前是200 还是300w
  var videoPix = RxInt(0);

  ///是否支持双向对讲
  var isSupportEchoCancellationVer = RxBool(false);

  ///是否支持警笛
  var haveSiren = false.obs;

  ///是否支持白光
  var haveWhiteLight = false.obs;

  ///是否支持红蓝光
  var haveRedBlueLight = false.obs;

  ///警笛开关 警笛是否开启
  var alarmSiren = RxBool(false);

  var alarmSirenMode = RxBool(false);

  ///白光模式
  var whiteLightMode = RxInt(0);

  ///实时预览页面 白光是否开启
  var lightSwitch = RxBool(false);

  ///实时预览页面 红蓝灯是否开启
  var redBlueSwitch = RxBool(false);

  ///报警设置
  var redBlueMode = RxBool(false);

  ///推送受限开关
  var pushLimit = false.obs;

  ///是否显示控制云台圆盘
  var isShowPTZPan = false.obs;

  ///预置位数据
  var presetData = <PresetModel>[].obs;

  ///垂直巡航
  var isVertical = false.obs;

  ///水平巡航
  var isHorizontal = false.obs;

  ///运动侦测计划,运动侦测模式
  var actionMotionPlans = <PlanModel>[].obs;

  ///隐私位计划
  // var actionPrivacyPlans = <PlanModel>[].obs;

  ///烟火相机火侦测计划
  // var actionFirePlans = <PlanModel>[].obs;

  ///烟火相机烟侦测计划
  // var actionSmokePlans = <PlanModel>[].obs;

  ///区域入侵侦测计划
  // var actionPlansAreaIntrusion = <PlanModel>[].obs;

  ///人员逗留侦测计划
  // var actionPlansPersonStay = <PlanModel>[].obs;

  ///车辆违停侦测计划
  // var actionPlansIllegalParking = <PlanModel>[].obs;

  ///越线报警侦测计划
  // var actionPlansCrossBorder = <PlanModel>[].obs;

  ///离岗检测侦测计划
  // var actionPlansOffPostMonitor = <PlanModel>[].obs;

  ///车辆逆行侦测计划
  // var actionPlansCarRetrograde = <PlanModel>[].obs;

  // var actionPlansPackageDetect = <PlanModel>[].obs;

  var motion_push_enable = RxInt(0);

  /// 移动侦测：1 6，人形侦测：5 关闭：0
  var motionPushEnable = RxInt(0);

  ///隐私位计划开关
  var privacy_plan_enable = 0.obs;

  ///烟火相机火计划开关
  var fire_plan_enable = 0.obs;

  ///烟火相机烟计划开关
  var smoke_plan_enable = 0.obs;

  ///区域入侵计划开关
  var areaIntrusionPlanEnable = 0.obs;

  ///人员逗留计划开关
  var personStayPlanEnable = 0.obs;

  ///车辆违停计划开关
  var illegalParkingPlanEnable = 0.obs;

  ///越线报警计划开关
  var crossBorderPlanEnable = 0.obs;

  ///离岗检测计划开关
  var offPostMonitorPlanEnable = 0.obs;

  ///车辆逆行计划开关
  var carRetrogradePlanEnable = 0.obs;

  var packageDetectPlanEnable = 0.obs;

  ///是否支持侦测范围调节
  var supportPirDistanceAdjust = RxInt(0);

  ///侦测范围
  var detectionRange = RxInt(0);

  ///1-->支持 PIR 唤醒后人形侦测双鉴定 2-->支持 PIR 唤醒后移动侦测双鉴定
  var suportWakeupCorrection = RxInt(0);

  ///人形侦测是否打开
  var humanSwitch = RxBool(false);

  /// 获取设备的云储存授权
  var cloudloading = false.obs;

  /// 当前是否ap
  var isAP = false.obs;

  /// 固件升级的等级 默认0级不提醒 分为:1,2,3,4四个等级 10->开始升级  20->升级成功
  var firmwareLevel = 0.obs;

  ///升级进度
  var firmwareProgress = 0.obs;

  ///升级定时器
  Timer? updateTimer;

  ///重启进度
  var restartProgress = 0.obs;

  Timer? restartTimer;

  ///需要升级相关消息
  // var firmwareInfo = Rx<FirmwareInfo>(null);

  ///充电不休眠
  var chargingNoSleep = RxString("");

  ///人形检测
  var supportPeopleDetection = RxInt(0);

  ///（双重认证返回）双重认证明文开关 0 是关闭 1 是打开
  var ExUserSwitch = RxString("");

  ///support_Plaintext_Pwd: 0,不支持明文密码
  var support_Plaintext_Pwd = RxString("");

  ///明文密码
  var plainTextPassword = ''.obs;

  var DualAuthentication = RxString("");

  ///AI+功能
  var supportAI = RxInt(0);

  ///哭声侦测
  var supportCryDetect = RxInt(0);

  ///侦测区域
  var supportMotionArea = RxInt(0);

  ///离岗侦测
  var supportDepartDetect = RxInt(0);

  ///人形侦测
  var supportHumanDetect = RxInt(0);

  ///人形框定
  var supportHumanoidFrame = RxInt(0);

  ///人脸识别
  var supportFaceRecognition = RxInt(0);

  ///自定义声音
  var supportVoiceTypedef = RxInt(0);

  ///烟感侦测
  var supportSmokeDetect = RxInt(0);

  ///人形追踪开关
  var humanTrack = RxInt(0);

  ///人形追踪状态
  var humanTrackStatus = RxInt(0);

  ///人形框定
  var humanFrame = RxInt(0);

  ///人形侦测等级
  var humanSensitLevel = RxInt(0);

  ///多倍变焦
  ///支持最大的变焦
  var MaxZoomMultiple = RxInt(0);

  /// 当前的变焦倍数
  var CurZoomMultiple = RxInt(1);

  ///聚焦功能
  //support_focus=1，表示支持聚焦功能
  //support_focus=2，表示支持聚焦功能，且支持定点变倍
  var support_focus = RxInt(0);

  //隐私位
  var support_privacy_pos = 0.obs;
  var privacyFlag = false.obs;

  ///实时录像
  var recordPlanEnable = RxInt(0);

  ///侦测录像
  var motionRecordPlanEnable = RxInt(0);

  ///24录像或者不录像
  var recordTimeEnable = RxInt(0);

  ///自定义时间计划，在demo，为简化流程，智能侦测定时的自定义时间段和tf计划录像共用
  var actionCustomPlans = <PlanModel>[].obs;

  ///全彩夜视
  var support_full_color_night_vision_mode = 0.obs;
  var night_vision_mode = 0.obs;
  var full_color_mode = 2.obs; //全彩子项为定时
  var full_color_show = 7.obs; //全彩子项全显示
  var full_color_default = 2.obs; //全彩定时  是否勾选默认  0 使用自定义  1 使用默认
  var full_color_start_hw = 19.obs; //全彩定时 产测配置开始时间
  var full_color_end_hw = 8.obs; //全彩定时 产测配置结束时间
  var full_color_start = 20.obs; //全彩定时 APP自定义开始时间
  var full_color_end = 8.obs; //全彩定时 APP自定义结束时间

  ///夜视模式状态
  var night_vision_Auto = RxInt(0); //1为自动夜视，0为关闭，2为开启

  ///电量图标闪烁
  var isBatteryIconFlash = false.obs;

  var doubleCheck = RxInt(0);

  var support_Remote_PowerOnOff_Switch = 0.obs;

  ///0 --> 关闭一键远程关机   1--> 打开一键远程关机
  var powerSwitch = 0.obs;

  ///wifi穿墙模式
  var support_WiFi_Enhanced_Mode = 0.obs;

  ///0-->当前wifi穿墙模式关闭   1-->当前wifi穿墙模式已经打开
  var wifiEnhancedMode = 0.obs;

  ///设备push消息免打扰的deadline值 毫秒
  var deadline = 0.obs;
  var pushPauseTotal = 0.obs; //毫秒

  ///白光灯/红外灯控制
  var support_WhiteLed_Ctrl = 0.obs; //是否支持白光灯/红外灯控制参数

  var whiteLed = 0.obs; //表示白光强度

  var ledTimes = 5.obs; //表示led持续时长

  var whiteLedMode = 0.obs; // 0:手动关 1:手动开 2：智能模式/报警模式 （可暂不处理）

  var whiteLedState = 0.obs; //是否亮灯

  // var actionWhiteLedPlan = <WhiteLightPlanModel>[].obs;

  ///预置位巡航计划
  // var actionPresetCruisePlans = <PlanModel>[].obs;

  var presetCruisePlanEnable = 0.obs;

  ///预置位巡航线路
  var actionPresetCruiseLine = <PresetCruiseLineModel>[].obs;

  ///预置位设置巡航线
  var presetCruisePoints = <int>[0, 0, 0, 0, 0].obs;

  /// 是否设置了隐私位  隐私位计划 ,计划列表null === false ,,计划列表有 ===ture
  var has_privacy_plan = RxBool(false);

  /// 是否设置了报警计划  报警计划 ,计划列表null === false ,,计划列表有 ===ture
  var has_Alarm_plan = RxBool(false);

  ///有没有 定时录像计划 ,计划列表null === false ,,计划列表有 ===ture
  var has_record_plan = RxBool(false);

  var has_fire_plan = RxBool(false);

  var has_smoke_plan = RxBool(false);

  var hasAreaIntrusionPlan = false.obs;

  var hasPersonStayPlan = false.obs;

  var hasIllegalParkingPlan = false.obs;

  var hasCrossBorderPlan = false.obs;

  var hasOffPostMonitorPlan = false.obs;

  var hasCarRetrogradePlan = false.obs;

  var hasPackageDetectPlan = false.obs;

  ///智能电量 1:支持
  var supportSmartElectricitySleep = RxInt(0);

  ///智能电量的开关
  var smartElectricitySleepSwitch = false.obs;

  ///智能电量的设置值[1-99]
  var smartElectricityThreshold = RxInt(0);

  ///MCU单片机
  var scmVersion = RxString("");

  var pushConfig = [];

  var externwifi = RxString("");

  ///支持OSD 调整
  var support_osd_adjustment = RxInt(0);

  ///像素 200w 300w 400w 500w
  var pixel = RxInt(0);

  ///是否支持 10挡距离调节
  var support_pir_level = RxInt(0);

  ///检测间隔
  var supportSleepCheckInterval = RxInt(0);

  var sleepCheckIntervalSwitch = false.obs;

  ///徘徊检测
  var supportLingerCheck = RxInt(0);

  var lingerCheckIntervalSwitch = false.obs;

  var sleepCheckDuration = RxInt(0);

  var lingerCheckDuration = RxInt(0);

  ///警笛倒计时
  var sirenCount = 10.obs;

  //支持看守位
  var support_ptz_guard = RxInt(0);

  var presetValue = RxInt(0);

  var watchPreset = RxInt(0);

  var presetPositionList = <String>["0", "0", "0", "0", "0"].obs;

  ///防拆报警
  var supportTamperSetting = RxInt(0);
  var dismantleAlarm = RxBool(false);

  ///未读消息
  var messagesCount = 0.obs;

  ///起始时间
  // Rx<DateTime> msgStartDate = Rx<DateTime>(null);

  ///云存储消息
  // Rx<CloudInfoModel> cloudInfo = Rx<CloudInfoModel>(null);

  ///4G流量绑定
  var is4GDataFlowBind = false.obs;

  //远程开关机 是否正在加载
  var isRemoteControlLoading = false.obs;

  ///是否支持tf卡录像分辨率切换
  var supportRecordResolution = RxInt(0);

  ///tf卡录像分辨率
  var recordResolution = RxInt(0);

  ///是否隐藏白光灯
  var support_manual_light = RxString("");

  //关闭录像模式选择 1为打开  0为关闭
  var recordmod = RxString("");

  //关闭智能侦测定时选择   1为打开  0为关闭
  var smartdetecttime = RxString("0");

  //是否支持预置位自动巡航
  var isSupportPresetAuto = false.obs;

  //是否支持预置位定时计划和巡航线
  var isSupportPresetCruise = false.obs;

  //是否支持智能语音
  var supportAlexa = false.obs;

  //ap模式是否弹框了
  var isAPHint = RxBool(false);

  ///定时管理
  //var timePlanModels = <TimePlanModel>[].obs;

  //扫描二维码字段
  var DT = RxString("");

  //扫描二维码字段
  var PT = RxString("");

  ///support_binocular binocular_zoom binocular_value
  ///是否支持双目
  var supportBinocular = RxBool(false);

  ///长焦倍数
  var binocularZoom = RxDouble(0);

  ///当前的镜头 28：默认 120：长焦
  var binocularValue = RxInt(0);

  ///微功耗
  var supportMicroPower = RxInt(0);

  ///TF时间轴
  var supportTimeLine = RxInt(0);

  ///焦点
  var binoculars = <int>[];

  /// 短焦偏移值
  var binocularsOffsetX = 0;
  var binocularsOffsetY = 0;

  ///是否正在远程关机
  var isRemoteClosing = false.obs;

  var remoteCloseCount = 0.obs;

  var remoteOpenCount = 0.obs;

  var supportNewLowPower = RxInt(-1);

  ///直播双击放大
  var support_presetRoi = RxBool(false);

  ///wifi 信号 getstatus获取
  var wifi_signal_quality = RxString("");

  var presetCruiseStatus = RxString("");

  var presetCruiseStatusH = RxString("");

  var presetCruiseStatusV = RxString("");

  var ptzAdjust = RxString("");

  /// 是否支持多镜头
  var supportPinInPic = RxInt(0);

  var pinInPicSensor = RxInt(0);

  /// 1 2 是双, 3是三目
  var supportMutilSensorStream = RxInt(0);

  ///双目转三目
  var splitScreen = RxInt(0);

  ///自动录像模式
  var supportAutoRecordMode = RxInt(0);

  var supportHumanoidZoom = RxInt(0);
  var humanZoomStatus = RxInt(0);

  var supportRecordTypeSeach = RxInt(0);

  ///云存储相关弹框是否弹
  var isCloudInfoDialog = RxBool(false);

  var supportFireSmoke = false.obs;
  var fireSmokeEnable = 1.obs;
  var fireSmokePlace = 0.obs;
  var fireSmokeType = 2.obs;
  var fireSmokeSensitivity = 1.obs;
  var fireSmokeVersion = RxString("");

  var fireSensitivity = 1.obs;
  var smokeSensitivity = 1.obs;

  var isDisplayNameMark = RxBool(true);

  var currentCruisePosition = RxInt(0);
  var linkStatus = RxInt(0); //0 不显示  1 开关开启  2 开关关闭

  ///红外激光
  var haveLaser = false.obs;

  ///激光灯状态
  var laserState = RxInt(0);

  var aiDetectMode = RxInt(0);

  // var areaIntrusionModel = Rx<AreaIntrusionModel>(null);
  //
  // var illegalParkingModel = Rx<IllegalParkingModel>(null);
  //
  // var personStayModel = Rx<PersonStayModel>(null);
  //
  // var offPostMonitorModel = Rx<OffPostMonitorModel>(null);
  //
  // var carRetrogradeModel = Rx<CarRetrogradeModel>(null);
  //
  // var crossBorderModel = Rx<CrossBorderModel>(null);
  //
  // var packageDetectModel = Rx<PackageDetectModel>(null);
  //
  // var fireSmokeDetectModel = Rx<FireSmokeDetectModel>(null);

  var areaIntrusionFunctionStatus = 0.obs; //0 未开通 1 试用中  2已开通  3过期失效

  var illegalParkingFunctionStatus = 0.obs;

  var personStayFunctionStatus = 0.obs;

  var offPostMonitorFunctionStatus = 0.obs;

  var carRetrogradeModelFunctionStatus = 0.obs;

  var crossBorderModelFunctionStatus = 0.obs;

  var packageDetectModelFunctionStatus = 0.obs;

  var fireSmokeDetectModelFunctionStatus = 0.obs;

  var areaIntrusionFunctionDeadline = 0.obs;

  var illegalParkingFunctionDeadline = 0.obs;

  var personStayFunctionDeadline = 0.obs;

  var offPostMonitorFunctionDeadline = 0.obs;

  var carRetrogradeModelFunctionDeadline = 0.obs;

  var crossBorderModelFunctionDeadline = 0.obs;

  var packageDetectModelFunctionDeadline = 0.obs;

  var fireSmokeDetectModelFunctionDeadline = 0.obs;

  var isSupportAreaIntrusion = false.obs;

  var isSupportPersonStay = false.obs;

  var isSupportIllegalParking = false.obs;

  var isSupportCrossBorder = false.obs;

  var isSupportOffPostMonitor = false.obs;

  var isSupportCarRetrograde = false.obs;

  var isSupportPackageDetect = false.obs;

  var isSupportFireSmokeDetect = false.obs;

  ///纯白光模式
  var supportPureWhiteLight = RxInt(0);

  ///固定镜头变倍
  var supportFixSensor = RxInt(0);

  var fixSensor = RxInt(0);

  var startOrStopRecordStatus = RxString("");

  ///当前的镜头 0：默认 1：长焦
  var currentBinocularValue = RxInt(0);

  @override
  bool operator ==(Object other) {
    if (super == other) {
      return true;
    }
    if (other is DeviceModel) {
      return this.id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => this.id.hashCode;
}
