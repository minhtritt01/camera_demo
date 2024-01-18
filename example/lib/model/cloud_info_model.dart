import 'package:get/get.dart';

class CloudInfoModel {
  final String did;
  bool isOpen = false;
  bool isExpiration = false;
  String expirationTime = "";
  bool isTryout = false;
  int diffDay = 0;
  String cycleDays = "";
  DateTime? tryoutExpirationTime;

  CloudInfoModel(this.did);
}
