import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'device_connect_bind.dart';
import 'device_connect_page.dart';

class DeviceConnectConf {
  static final GetPage getPage = GetPage(
      name: AppRoutes.deviceConnect,
      page: () => DeviceConnectPage(),
      binding: DeviceConnectBind());

  static GetPageRoute? _pageRoute;

  /// 用于代码进行页面导航
  /// `Get.to()`
  static Widget getWidget(BuildContext context) {
    if (_pageRoute == null) {
      _pageRoute = getPage.createRoute(context) as GetPageRoute?;
    }
    return _pageRoute?.buildPage(context, _pageRoute!.createAnimation(),
            _pageRoute!.createAnimation()) ??
        Container();
  }

  static void dispose() {
    // _pageRoute?.dispose();
    _pageRoute = null;
  }
}
