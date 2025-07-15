import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'proto.dart';

class BleReceive {
  String lr = "";
  Uint8List data = Uint8List(0);
  String type = "";
  bool isTimeout = false;
 
  int getCmd() {
    return data[0].toInt();
  }

  BleReceive();
  static BleReceive fromMap(Map map) {
    var ret = BleReceive();
    ret.lr = map["lr"];
    ret.data = map["data"];
    ret.type = map["type"];
    return ret;
  }

  String hexStringData() {
    return data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}

class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  static BLEManager get instance => _instance;

  BLEManager._internal();

  /// Send notification to goggles using BLE protocol
  static void sendNotificationToGoggles(Map<String, dynamic> notification) {
    // Use Proto.sendNotify to send notification as per protocol
    // Use a unique notifyId (timestamp)
    final int notifyId = DateTime.now().millisecondsSinceEpoch & 0xFF;
    Proto.sendNotify(notification, notifyId);
  }

  void sendData(String message) {
    // Your BLE sending implementation here
  }
}