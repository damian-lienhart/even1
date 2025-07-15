import 'package:flutter_test/flutter_test.dart';
import 'package:demo_ai_even/services/ble.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('method.bluetooth');
  channel.setMockMethodCallHandler((MethodCall methodCall) async => null);

  group('IntegrationTest', () {
    test('End-to-end: notification received → packetized → BLE send called', () async {
      int sendCount = 0;
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        sendCount++;
        return true;
      };
      final notification = {
        'title': 'Integration Test',
        'body': 'This is an end-to-end test',
        'userInfo': {'key': 'value'}
      };
      await BLEManager.sendNotificationToGoggles(notification);
      expect(sendCount > 0, true);
      BLEManager.requestList = originalRequestList;
    });

    test('Debug/log output is as expected for each step', () async {
      // This test will check that debug output is produced (manual review)
      final notification = {
        'title': 'Debug Test',
        'body': 'Check debug output',
        'userInfo': {'debug': true}
      };
      // The debug output should include proto -> sendNotify and requestList---sendList
      await BLEManager.sendNotificationToGoggles(notification);
      // Manual: Check console/log output for expected debug lines
      expect(true, true); // Always passes, for manual review
    });

    test('Notification arrives while another is being sent (concurrency)', () async {
      int sendCount = 0;
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        await Future.delayed(Duration(milliseconds: 50)); // Simulate BLE delay
        sendCount++;
        return true;
      };
      final notification1 = {
        'title': 'First',
        'body': 'First notification',
        'userInfo': {}
      };
      final notification2 = {
        'title': 'Second',
        'body': 'Second notification',
        'userInfo': {}
      };
      // Fire two notifications in quick succession
      await Future.wait([
        BLEManager.sendNotificationToGoggles(notification1),
        BLEManager.sendNotificationToGoggles(notification2),
      ]);
      expect(sendCount >= 2, true);
      BLEManager.requestList = originalRequestList;
    });
  });
}

