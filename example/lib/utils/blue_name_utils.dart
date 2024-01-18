import 'package:flutter/material.dart';

bool isBlueDev(String name) {
  ///print('是否蓝牙设备:${name} ');
  if (name.startsWith("IPC-")) {
    name = name.replaceAll('IPC-', '');
  } else if (name.startsWith("MC-")) {
    name = name.replaceAll('MC-', '');
  } else if (name.startsWith("VP-")) {
    name = name.replaceAll('VP-', '');
  } else {
    return false;
  }
  RegExp exp = RegExp(r'^[a-zA-Z]{1,}\d{7,}.*[a-zA-Z]$');
  bool isVirtualId = exp.hasMatch(name);

  ///print('是否蓝牙设备:${name}  isBlueDev : ${isVirtualId}');
  return isVirtualId;
}
