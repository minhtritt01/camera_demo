import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

abstract class GetWidgetView<T, S> extends GetView<T> {
  GetWidgetView({Key? key}) : super(key: key);

  @override
  String get tag {
    return S.toString();
  }
}

enum SystemOrientations {
  all,
  landscape,
  portrait,
}

abstract class GetPageView<T> extends GetView<T> {
  GetPageView({Key? key, this.canBack = true, this.canBlank = true})
      : super(key: key);

  /// 是否允许返回
  /// 不允许返回的界面按返回键将弹出退出提示
  final bool canBack;
  final bool canBlank;

  Widget buildLayout(BuildContext context);

  void onBlankTap(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 点击空白区域自动隐藏键盘
    Widget child;
    if (canBlank == true)
      child = GestureDetector(
        onTap: () => onBlankTap(context),
        child: buildLayout(context),
      );
    else
      child = buildLayout(context);
    return child;
  }
}
