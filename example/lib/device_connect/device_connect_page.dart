import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'device_connect_logic.dart';

class DeviceConnectPage extends GetView<DeviceConnectLogic> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Device connect'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: ObxValue<RxBool>((data) {
          return data.value
              ? Center(
                  child: Column(
                    children: [
                      SizedBox(height: 100),
                      QrImageView(
                        data: controller.state!.qrContent,
                        size: 300.0,
                      ),
                      SizedBox(height: 10),
                      Text("请扫描二维码连接设备后等待设备搜索结果",
                          style: TextStyle(color: Colors.red))
                    ],
                  ),
                )
              : Center(
                  child: ObxValue<Rx<String>>((data) {
                    return data.isNotEmpty
                        ? Column(
                            children: [
                              SizedBox(height: 100),
                              Text("Wifi名称：${data.value}"),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Wifi密码："),
                                  SizedBox(
                                    width: 200,
                                    height: 38,
                                    child: TextField(
                                      controller: controller.textController,
                                      decoration: InputDecoration(
                                        labelText: '请输入密码',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),
                              InkWell(
                                  onTap: () {
                                    controller.generateQrCode();
                                  },
                                  child: Text(
                                    "点击生成二维码",
                                    style: TextStyle(color: Colors.blue),
                                  )),
                              SizedBox(height: 50),
                            ],
                          )
                        : Container(
                            height: 200,
                            alignment: Alignment.center,
                            child:
                                Text("未检测到wifi, 请确保手机连接WI-FI \n (app需打开位置权限)"));
                  }, controller.state!.wifiName),
                );
        }, controller.state!.isShowQR),
      ),
    );
  }
}
