import '../../../utils/super_put_controller.dart';
import '../../linkable_revise_state.dart';

/// ResetButton 控制器
mixin ResetButtonLogic on SuperPutController<LinkableReviseState> {
  @override
  void initPut() {
    lazyPut<ResetButtonLogic>(this);
    super.initPut();
  }

  void retRevise() async {
    state?.isRet.value = true;
    state?.isRet.refresh();
    print("state.isRet.value refresh${state?.isRet.value}");
    Future.delayed(Duration(milliseconds: 100), () {
      state?.isRet.value = false;
      state?.isRet.refresh();
      print("state.isRet.value refresh${state?.isRet.value}");
    });
  }
}
