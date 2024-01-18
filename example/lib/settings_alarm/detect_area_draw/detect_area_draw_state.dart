import 'package:get/get.dart';

class DetectAreaDrawState {
  Rx<List<List<int>>> gridState =
      Rx<List<List<int>>>(List.generate(18, (index) => List.filled(22, 1)));
}
