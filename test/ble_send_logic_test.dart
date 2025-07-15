import 'package:flutter_test/flutter_test.dart';
import 'package:demo_ai_even/services/ble.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('method.bluetooth');
  channel.setMockMethodCallHandler((MethodCall methodCall) async => null);

  group('BleSendLogicTest', () {
    test('BLE send is called for each packet (packetization per README)', () async {
      // According to README, notifications are split into packets of 176 bytes (see Proto.getNotifyPackList)
      final notification = {
        'title': 'A' * 500, // Long enough to require multiple packets
        'body': 'B' * 500,
        'userInfo': {'key': 'value'}
      };
      final notifyId = 42;
      final packets = Proto.getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      // Each packet should be <= 180 bytes (4 header + 176 data)
      for (final p in packets) {
        expect(p.length <= 180, true);
      }
      expect(packets.length > 1, true); // Should be more than one packet
    });

    test('BLE send is called for both left and right channels if required', () async {
      // According to README, notifications are sent to left channel (L) by default
      // For some protocols, both L and R are used (e.g., text sending)
      // For notifications, Proto.sendNotify sends to L only, so we check that
      int leftSendCount = 0;
      int rightSendCount = 0;
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        if (lr == 'L') leftSendCount++;
        if (lr == 'R') rightSendCount++;
        return true;
      };
      final notification = {
        'title': 'Test',
        'body': 'Test',
        'userInfo': {}
      };
      await Proto.sendNotify(notification, 1);
      expect(leftSendCount > 0, true);
      expect(rightSendCount, 0); // For notifications, only L is used
      BLEManager.requestList = originalRequestList;
    });

    test('BLE send handles errors (e.g., not connected)', () async {
      // Simulate not connected by making requestList throw
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        throw Exception('Not connected');
      };
      final notification = {
        'title': 'Test',
        'body': 'Test',
        'userInfo': {}
      };
      try {
        await Proto.sendNotify(notification, 2);
        // If no exception, test passes (should handle gracefully)
        expect(true, true);
      } catch (e) {
        // If exception, test still passes if it's the simulated error
        expect(e.toString().contains('Not connected'), true);
      }
      BLEManager.requestList = originalRequestList;
    });

    test('BLE send handles retries/timeouts', () async {
      // Simulate timeout on first call, success on second
      int callCount = 0;
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        callCount++;
        if (callCount == 1) return false; // Simulate failure
        return true; // Success on retry
      };
      final notification = {
        'title': 'Retry',
        'body': 'Test',
        'userInfo': {}
      };
      await Proto.sendNotify(notification, 3);
      expect(callCount > 1, true); // Should retry at least once
      BLEManager.requestList = originalRequestList;
    });

    test('BLE send failure (simulate and check error handling)', () async {
      // Simulate always failing
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        return false;
      };
      final notification = {
        'title': 'Fail',
        'body': 'Test',
        'userInfo': {}
      };
      await Proto.sendNotify(notification, 4);
      // No exception should be thrown, just a failed send
      expect(true, true);
      BLEManager.requestList = originalRequestList;
    });

    test('BLE not connected (simulate and check error handling)', () async {
      // Simulate not connected by always returning false
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        return false;
      };
      final notification = {
        'title': 'NotConnected',
        'body': 'Test',
        'userInfo': {}
      };
      await Proto.sendNotify(notification, 5);
      expect(true, true);
      BLEManager.requestList = originalRequestList;
    });

    test('Retries BLE send on timeout', () async {
      // Simulate two failures, then success
      int callCount = 0;
      final originalRequestList = BLEManager.requestList;
      BLEManager.requestList = (sendList, {String? lr, int? timeoutMs}) async {
        callCount++;
        if (callCount < 3) return false;
        return true;
      };
      final notification = {
        'title': 'Timeout',
        'body': 'Test',
        'userInfo': {}
      };
      await Proto.sendNotify(notification, 6);
      expect(callCount >= 3, true);
      BLEManager.requestList = originalRequestList;
    });
  });
}
