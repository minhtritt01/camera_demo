import 'dart:convert';
import 'dart:typed_data';

class BluePackage {
  ///final int wifi_status; //1-->wifi模块初始化成功，2-->wifi模块初始化失败
  final int apIndex; //路由器列表序号，当序号为10000时为结束，忽略附带信息（可能未搜索到直接返回10000）
  final String apSsid; //路由器名称 64
/*  final String ap_mac; //路由器名称 20
  final int ap_dbm0; //路由器信号强度
  final int ap_security;*/

  BluePackage(this.apIndex, this.apSsid);

  static BluePackage? fromData(ByteData? data, int len) {
    if (data == null || data.lengthInBytes < len) return null;
    print(data.buffer.asUint8List());

    final int apIndex = data.getInt16(2, Endian.little);

    ///final int ap_index = data.getInt32(0, Endian.little);

    ///print("==>>获取到的ap_index: ${ap_index}");
    final ssidList = data.buffer.asUint8List(4, 36).toList();

    ssidList.removeWhere((element) {
      return element == 0;
    });
    var apSsid;
    try {
      apSsid = utf8.decode(ssidList).toString();
    } catch (e) {
      apSsid = String.fromCharCodes(ssidList);
    }
    print("ap_ssid: $apSsid");
    /*   final ap_mac = String.fromCharCodes(data.buffer.asUint8List(8 + 64, 12));
    print("ap_mac ${ap_mac}");
    final int ap_dbm0 = data.getInt32(8 + 64 + 16, Endian.little);
    print("ap_dbm0 ${ap_dbm0}");
    final int ap_security = data.getInt32(8 + 64 + 16 + 4, Endian.little);
    print("ap_security ${ap_security}");*/
    BluePackage package = BluePackage(apIndex, apSsid);
    return package;
  }

  static ByteData toData(String userid, String ssid, String pwd, int region) {
    final idList = List<int>.filled(32, 0);
    final ssidList = List<int>.filled(36, 0);

    ///final mac_list = List<int>.filled(16, 0);
    final pwd_list = List<int>.filled(64, 0);
    var data = utf8.encode(userid);
    idList.setRange(0, data.length >= 32 ? 32 : data.length, data);

    data = utf8.encode(ssid);
    ssidList.setRange(0, data.length >= 36 ? 36 : data.length, data);

/*    data = utf8.encode(mac);
    mac_list.setRange(0, data.length >= 16 ? 16 : data.length, data);*/
    data = utf8.encode(pwd);
    pwd_list.setRange(0, data.length >= 64 ? 64 : data.length, data);

    ByteData buffer = ByteData(32 + 36 + 64 + 4);
    int offset = 0;
    for (int i = 0; i < idList.length; i++) {
      buffer.setInt8(offset, idList[i]);
      offset += 1;
    }
    for (int i = 0; i < ssidList.length; i++) {
      buffer.setInt8(offset, ssidList[i]);
      offset += 1;
    }
    /*   for (int i = 0; i < mac_list.length; i++) {
      buffer.setInt8(offset, mac_list[i]);
      offset += 1;
    }*/
    for (int i = 0; i < pwd_list.length; i++) {
      buffer.setInt8(offset, pwd_list[i]);
      offset += 1;
    }

    ///buffer.setInt32(offset, security, Endian.little);
    buffer.setInt32(offset, region, Endian.little);

    return buffer;
  }

  @override
  String toString() {
    return "ssid:$apSsid index:$apIndex";
  }
}
