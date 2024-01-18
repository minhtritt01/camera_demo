import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:vsdk_example/tf_play/tf_play_bind.dart';
import 'package:vsdk_example/tf_play/tf_play_page.dart';

import '../app_routes.dart';

class TFPlayConf {
  static final GetPage getPage = GetPage(
      name: AppRoutes.tfPlay, page: () => TFPlayPage(), binding: TFPlayBind());

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
