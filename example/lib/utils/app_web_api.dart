library app_web_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:http_parser/http_parser.dart';

typedef AuthErrorCallback = void Function(
    String clientName, String clientUUID, String lastTime);

class AppWebApi {
  String _baseUrl = "https://open.eye4.cn";

  /// 默认连接超时时间(ms)
  final int defaultConnectTimeout = 30000;

  /// 默认读取超时时间(ms)
  final int defaultReceiveTimeout = 30000;

  /// 单例
  static AppWebApi? _instance;

  /// 将构造函数指向单例
  factory AppWebApi() => getInstance();

  /// 将构造函数指向单例

  ///获取单例
  static AppWebApi getInstance() {
    //如果单例为空则创建单例
    if (_instance == null) {
      _instance = new AppWebApi._internal();
    }
    return _instance!;
  }

  int _cacheMaxAge = 9999999999999;
  late Dio _dio;
  late DioCacheManager _cacheManager;
  late BaseOptions _baseOptions;

  List _listeners = [];

  void addListener<T>(T listener) {
    _listeners.add(listener);
  }

  void removeListener<T>(T listener) {
    _listeners.remove(listener);
  }

  void notifyListeners<T>(void Function(T listener) callback) {
    _listeners.forEach((func) {
      if (func is T) {
        callback(func);
      }
    });
  }

  void cleanListener() {
    _listeners.clear();
  }

  AppWebApi._internal() {
    _baseOptions = BaseOptions(
        baseUrl: _baseUrl,
        sendTimeout: defaultReceiveTimeout,
        connectTimeout: defaultConnectTimeout,
        receiveTimeout: defaultReceiveTimeout);
    this._dio = Dio(_baseOptions);
    this._cacheManager = DioCacheManager(CacheConfig(baseUrl: _baseUrl));
    _dio.interceptors.add(_cacheManager.interceptor);
  }

  Future<void> reInit() async {
    _instance = new AppWebApi._internal();
  }

  Future<bool> clearCache() {
    return _cacheManager.clearAll();
  }

  ///转换错误信息.
  ///正常情况下返回服务器响应的错误信息
  ///如果是调用[CancelToken]取消请求,那么[Response]中[statusCode]为0
  ///如果是其他连接错误 [Response]中[statusCode]为 -1
  Response _errorResponse(DioError error, {bool checkAuthError = true}) {
    if (error.response != null) {
      return error.response!;
    } else {
      if (error.type == DioErrorType.cancel) {
        return Response(statusCode: 0, requestOptions: error.requestOptions);
      } else {
        return Response(
            data: error.message,
            statusCode: -1,
            requestOptions: error.requestOptions);
      }
    }
  }

  Future<Options> _requestOptions({Options? options}) async {
    options = options ?? Options(headers: {}, extra: {});
    if (Platform.isIOS) {
      DeviceInfoPlugin infoPlugin = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await infoPlugin.iosInfo;
      String userAgent =
          'Dart (${iosInfo.model}; ${iosInfo.systemName} ${iosInfo.systemVersion})';
      options.headers!["user-agent"] = userAgent;
    }
    options.headers!["client_version"] = "1.0.0";
    options.headers!["client_mark"] = 1;
    options.headers!["client_number"] = 1;

    ///请使用自己的AccessKey
    options.headers!["AccessKey"] = "6pCrDUjkDscEGlPV";

    /// ///请使用自己的SecretKey
    options.headers!["SecretKey"] = "P1fyTVZU1yaDc9K9";

    return options;
  }

  Future<BaseOptions> _requestBaseOptions() async {
    return BaseOptions(
        baseUrl: _baseUrl,
        sendTimeout: defaultReceiveTimeout * 2,
        connectTimeout: defaultConnectTimeout * 2,
        receiveTimeout: defaultReceiveTimeout * 2);
  }

  /// 获取云储存开通授权
  Future<Response> requestlicensekey(String uid,
      [CancelToken? cancelToken,
      Options? options,
      bool useCache = true]) async {
    options = await _requestOptions(options: options);
    try {
      Response response = await _dio.post("/service/D004/license",
          data: jsonEncode({
            "target": uid,
          }),
          options: options,
          cancelToken: cancelToken);
      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  ///查询低功耗设备云存储信息
  Future<Response> queryDeviceCloudExpirationTime(String did,
      {CancelToken? cancelToken, Options? options}) async {
    options = await _requestOptions(options: options);
    try {
      return await _dio.post("/service/D015/info",
          data: jsonEncode({"target": did}),
          cancelToken: cancelToken,
          options: options);
    } on DioError catch (e) {
      return Future.value(_errorResponse(e, checkAuthError: false));
    }
  }

  ///查询设备是否支持云存储
  Future<Response> queryCloudSupport(String uid,
      {CancelToken? cancelToken, Options? options}) async {
    try {
      return await _dio.post("/D004/isSupport",
          data: {
            "did": uid,
          },
          cancelToken: cancelToken,
          options: options);
    } on DioError catch (e) {
      return Future.value(_errorResponse(e, checkAuthError: false));
    }
  }

  ///获取长电设备的云存储相关信息
  ///[did] 设备id
  Future<Response> getCloudInfo(String did,
      {CancelToken? cancelToken, Options? options}) async {
    options = await _requestOptions(options: options);
    try {
      return await _dio.post("/service/D004/info",
          data: jsonEncode({
            "target": did,
          }),
          cancelToken: cancelToken,
          options: options);
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  ///查询云存储是否试用
  Future<Response> queryCloudTryoutShow(String uid,
      {CancelToken? cancelToken, Options? options}) async {
    try {
      return await _dio.post("/D004/tryout/show",
          data: {
            "did": uid,
          },
          cancelToken: cancelToken,
          options: options);
    } on DioError catch (e) {
      return Future.value(_errorResponse(e, checkAuthError: false));
    }
  }

  ///长电设备 获取云储存某一天的数据
  /// [userId] 用户ID
  /// [authKey] 登录授权码
  Future<Response> requestCloudOneDay(
      String path, String licencekey, String time, String uid,
      [CancelToken? cancelToken,
      Options? options,
      bool useCache = true]) async {
    options = await _requestOptions(options: options);
    options.headers!["api-version"] = '2';
    String zone = await FlutterNativeTimezone.getLocalTimezone();
    Map data = {
      "licenseKey": licencekey,
      "uid": uid,
      "date": time,
      "timeZone": zone,
    };
    print("----param data-${data.toString()}--------");

    var dio = Dio();
    dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);

    try {
      Response response = await dio.post("$path/D004/group/show",
          data: jsonEncode(data),
          options: buildCacheOptions(Duration(days: _cacheMaxAge),
              options: options,
              forceRefresh: !useCache,
              primaryKey: "/D004/group/show",
              subKey: "date=$time and uid=$uid"),
          cancelToken: cancelToken);
      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  /// 低功耗设备获取云存储URL
  ///
  /// [userId] 用户ID
  /// [authKey] 登录授权码
  /// [fileId] 文件ID, Message 中获取
  /// [fileType] D009
  Future<Response> requestCouldUrl(String fileId, String fileType,
      {CancelToken? cancelToken,
      Options? options,
      bool useCache = true}) async {
    options = await _requestOptions(options: options);
    try {
      Response response = await _dio.post("/push/fileid",
          data: jsonEncode({
            "fileid": fileId, //从消息中获取该值
            "type": fileType //"D009"
          }),
          options: buildCacheOptions(Duration(days: _cacheMaxAge),
              options: options,
              forceRefresh: !useCache,
              subKey: "fileId=$fileId and fileType=$fileType"),
          cancelToken: cancelToken);
      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  /// 获取云云储存摘要
  ///
  Future<Response> requestCloudSummary(
      String path, String licenseKey, String uid,
      [CancelToken? cancelToken,
      Options? options,
      bool useCache = true]) async {
    options = await _requestOptions(options: options);
    String zone = await FlutterNativeTimezone.getLocalTimezone();
    Map data = {
      "licenseKey": licenseKey,
      "uid": uid,
      "timeZone": zone,
    };

    var dio = Dio();
    // dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);

    try {
      Response response = await dio.post("$path/D004/summary/show",
          data: data, cancelToken: cancelToken, options: options);

      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  /// 获取设备推送限制
  Future<Response> requestDevicePushLimit(String did,
      {String url = '', CancelToken? cancelToken, Options? options}) async {
    try {
      if (url.isEmpty) {
        url = '/push/motionDetection/show';
      } else if (!url.contains('motionDetection/show')) {
        String spText = '';
        if (!url.endsWith('/')) {
          spText = '/';
        }
        if (url.startsWith('http://') || url.startsWith('https://')) {
          url = '$url${spText}push/motionDetection/show';
        } else {
          url = 'https://$url${spText}push/motionDetection/show';
        }
      }
      return await _dio.post(url,
          data: {"did": did}, cancelToken: cancelToken, options: options);
    } on DioError catch (e) {
      return Future.value(_errorResponse(e, checkAuthError: false));
    }
  }

  /// 获取云储存某视频数据
  /// [userId] 用户ID
  /// [authKey] 登录授权码
  Future<Response> requestCloudVideo(
      String path, String licenseKey, List<String> time, String uid,
      [CancelToken? cancelToken,
      Options? options,
      bool useCache = true]) async {
    options = await _requestOptions(options: options);
    options.headers!["api-version"] = '2';
    Map data = {
      "licenseKey": licenseKey,
      "uid": uid,
      "time": time,
    };

    var dio = Dio();
    dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);

    try {
      Response response = await dio.post("$path/D004/file/url",
          data: data,
          options: buildCacheOptions(Duration(days: _cacheMaxAge),
              options: options,
              forceRefresh: !useCache,
              primaryKey: "/D004/file/url",
              subKey: "date=$time and uid=$uid"),
          cancelToken: cancelToken);
      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  /// 获取云储存某视频封面
  ///
  ///
  /// [userId] 用户ID
  /// [authKey] 登录授权码
  Future<Response> requestCloudCover(
      String path, String licenseKey, String url, String uid,
      [CancelToken? cancelToken,
      Options? options,
      bool useCache = true]) async {
    options = await _requestOptions(options: options);
    options.headers!["api-version"] = '2';
    Map data = {
      "licenseKey": licenseKey,
      "uid": uid,
      "url": url,
    };

    //对url进行处理
    //http://d004-vstc.eye4.cn/VSTJ571609SUUSN_2022-11-03:11_38_34_12?e=1667471306&token=l5gvKghs6BCqoVtQJOkLwykc7JtTnXvUCGgl2AzZ:P7WSnEvRcyEvAIZvlS86L38_gcY=
    var list = url.split("?e");
    var cacheKey = list.first;

    var dio = Dio();
    dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);

    try {
      Response response = await dio.post("$path/D004/cover",
          data: data,
          options: buildCacheOptions(Duration(days: _cacheMaxAge),
              options: options,
              forceRefresh: !useCache,
              primaryKey: "/D004/cover",
              subKey: "$cacheKey"),
          cancelToken: cancelToken);
      return response;
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  //新声波 confirm
  Future<Response> requestHelloConfirm(String key,
      {CancelToken? cancelToken, Options? options}) async {
    try {
      return await _dio
          .post("https://api.eye4.cn/hello/confirm", data: {"key": key});
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }

  //新声波 confirm
  Future<Response> requestHelloQuery(String key,
      {CancelToken? cancelToken, Options? options}) async {
    try {
      return await _dio
          .post("https://api.eye4.cn/hello/query", data: {"key": key});
    } on DioError catch (e) {
      return Future.value(_errorResponse(e));
    }
  }
}
