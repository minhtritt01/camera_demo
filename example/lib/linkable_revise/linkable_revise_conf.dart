import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../app_routes.dart';
import 'linkable_revise_bind.dart';
import 'linkable_revise_page.dart';

class LinkableReviseConf {
  static final GetPage getPage = GetPage(
      name: AppRoutes.linkable,
      page: () => LinkableRevisePage(),
      binding: LinkableReviseBind());

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
    _pageRoute?.dispose();
    _pageRoute = null;
  }
}
