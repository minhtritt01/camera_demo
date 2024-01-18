import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../tf_play/tf_play_state.dart';
import '../../utils/super_put_controller.dart';
import '../tf_time_slider/tf_time_slider_logic.dart';

mixin TFScrollLogic on SuperPutController<TFPlayState> {
  @override
  void initPut() {
    lazyPut<TFScrollLogic>(this);
    super.initPut();
  }
}
