import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      GetMaterialApp(
        initialRoute: AppRoutes.main,
        getPages: AppPages.pages,
        builder: EasyLoading.init()
      )
  );
}
