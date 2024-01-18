import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'permission_handler/permission_handler_platform_interface.dart';
import 'permission_handler/permission_handler.dart';

///相机权限
Future<bool> checkCameraPermission() async {
  var status = await Permission.camera.status;
  //print("检查相机权限:$status");
  if (Platform.isIOS) {
    switch (status) {
      case PermissionStatus.denied: //拒绝，不再提示
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        var map = await [Permission.camera].request();
        var status = map[Permission.camera];
        return status == PermissionStatus.granted;
    }
  } else {
    var status = await Permission.camera.status;
    //print("检查相机权限:$status");
    switch (status) {
      case PermissionStatus.permanentlyDenied: //永久拒绝
        return false;
      case PermissionStatus.undetermined: //尚未请求许可
        return false;
      case PermissionStatus.denied: //拒绝，不再提示
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        var map = await [Permission.camera].request();
        var status = map[Permission.camera];
        return status == PermissionStatus.granted;
    }
  }
}

///麦克风权限
Future<bool> checkMicroPhonePermission() async {
  if (Platform.isIOS) {
    var status = await Permission.microphone.status;
    print("检查麦克风权限:$status");
    switch (status) {
      case PermissionStatus.permanentlyDenied: //永久拒绝
        return false;
      case PermissionStatus.undetermined: //尚未请求许可
        return false;
      case PermissionStatus.denied: //拒绝，不再提示
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        var map = await [Permission.microphone].request();
        var status = map[Permission.microphone];
        return status == PermissionStatus.granted;
    }
  } else {
    var status = await Permission.microphone.status;
    print("检查麦克风权限:$status");
    switch (status) {
      case PermissionStatus.permanentlyDenied: //永久拒绝
        return false;
      case PermissionStatus.undetermined: //尚未请求许可
        return false;
      case PermissionStatus.denied: //拒绝，不再提示
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        var map = await [Permission.microphone].request();
        var status = map[Permission.microphone];
        print("default 检查麦克风权限:$status");
        return status == PermissionStatus.granted;
    }
  }
}

///相册限
Future<bool> checkPhotoAlbumPermission() async {
  if (Platform.isIOS) {
    var status = await Permission.photos.status;
    switch (status) {
      case PermissionStatus.permanentlyDenied: //拒绝，不再提示
        return false;
      case PermissionStatus.denied: //拒绝
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        var map = await [Permission.photos].request();
        var status = map[Permission.photos];
        return status == PermissionStatus.granted;
    }
  } else {
    ///Android
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String? version = androidInfo.version.release;
    print("android version:${version}");
    int ver = int.tryParse(version ?? '1') ?? 0;
    var status;
    if (ver > 13) {
      status = await Permission.videos.status;
    } else {
      status = await Permission.storage.status;
    }

    print("检查相册权限:$status");
    switch (status) {
      case PermissionStatus.permanentlyDenied: //永久拒绝
        return false;
      // case PermissionStatus.undetermined: //尚未请求许可
      //   return false;
      case PermissionStatus.denied: //拒绝，不再提示
        return false;
      case PermissionStatus.granted: //允许
        return true;
      default:
        if (ver >= 13) {
          var map = await [Permission.videos].request();
          var status = map[Permission.videos];
          print("检查相册权限:ver >= 13 videos $status");
          return status == PermissionStatus.granted;
        }
        var map = await [Permission.photos].request();
        var status = map[Permission.photos];
        print("检查相册权限:ver < 13 $status");
        return status == PermissionStatus.granted;
    }
  }
}

///相册权限
Future<bool> checkPhotoPermissionGranted() async {
  var bl = await checkPhotoAlbumPermission();
  if (bl == false) {
    jumpNativeAppSetting();
    return false;
  } else {
    return true;
  }
}

void jumpNativeAppSetting() async {
  if (Platform.isIOS) {
    if (await canLaunch("app-settings:")) {
      await launch("app-settings:");
    }
  } else if (Platform.isAndroid) {
    AndroidIntent intent = AndroidIntent(
      action: 'action_application_details_settings',
      data:
          "package:com.example.vsdk_example", //app_ui调试的时候用这个 com.veepai.cloud
    );
    await intent.launch();
  }
}
