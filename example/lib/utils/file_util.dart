import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> getDirectory() async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  }
  return dir?.path ?? "";
}
