import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension Inst on GetInterface {
  S tryFind<S>({required String tag}) {
    late S value;
    try {
      value = GetInstance().find<S>(tag: tag);
    } catch (e) {
      printError(info: e.toString());
    }
    return value;
  }
}

abstract class SuperPutController<T> extends SuperController<T> {
  void initPut() {}

  @override
  void onInit() {
    super.onInit();
  }

  var putKeys = [];

  String _getKey(Type type, String name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  void lazyPut<S>(S value) {
    Get.lazyPut<S>(() => value, tag: T.toString());
    putKeys.add(_getKey(S, T.toString()));
  }

  @override
  void onClose() {
    // putKeys.forEach((element) {
    //   GetInstance().delete(key: element);
    // });
    // putKeys.clear();
    super.onClose();
  }

  @override
  void onResumed() {}

  @override
  void onPaused() {}

  @override
  void onInactive() {}

  @override
  void onDetached() {}
}
