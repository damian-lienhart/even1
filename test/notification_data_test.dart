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

  group('NotificationDataTest', () {
    test('Handles normal notification (title, body, userInfo)', () async {
      final notification = {
        'title': 'Test Title',
        'body': 'Test Body',
        'userInfo': {'key': 'value'}
      };
      final notifyId = 1;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      expect(utf8.decode(packets[0].sublist(4)).contains('Test Title'), true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles empty fields (title, body, userInfo)', () async {
      final notification = {
        'title': '',
        'body': '',
        'userInfo': {}
      };
      final notifyId = 2;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles very long title/body/userInfo (packet splitting)', () async {
      final longText = 'A' * 1000;
      final notification = {
        'title': longText,
        'body': longText,
        'userInfo': {'long': longText}
      };
      final notifyId = 3;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.length > 1, true); // Should be split into multiple packets
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles special characters, Unicode, emoji', () async {
      final notification = {
        'title': 'Üñîçødë 🚀!@#',
        'body': '测试中文, русский текст, عربى',
        'userInfo': {'emoji': '😃', 'symbols': "<>&%'"}
      };
      final notifyId = 4;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles large userInfo maps (many keys/values)', () async {
      final userInfo = Map.fromIterable(List.generate(100, (i) => i), key: (i) => 'key$i', value: (i) => 'value$i');
      final notification = {
        'title': 'Bulk',
        'body': 'Bulk',
        'userInfo': userInfo
      };
      final notifyId = 5;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.length > 1, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles null fields (title, body, userInfo)', () async {
      final notification = {
        'title': null,
        'body': null,
        'userInfo': null
      };
      final notifyId = 6;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles notification with only title present', () async {
      final notification = {
        'title': 'Title Only',
        'body': '',
        'userInfo': {}
      };
      final notifyId = 7;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles notification with only body present', () async {
      final notification = {
        'title': '',
        'body': 'Body Only',
        'userInfo': {}
      };
      final notifyId = 8;
      final packets = Proto._getNotifyPackList(0x4B, notifyId, utf8.encode(jsonEncode({'ncs_notification': notification})));
      expect(packets.isNotEmpty, true);
      await Proto.sendNotify(notification, notifyId);
    });

    test('Handles invalid notification data (non-serializable)', () async {
      final notification = {
        'title': 'Test',
        'body': 'Test',
        'userInfo': {'bad': BLEManager} // BLEManager is not serializable
      };
      final notifyId = 9;
      try {
        utf8.encode(jsonEncode({'ncs_notification': notification}));
        fail('Should throw error for non-serializable data');
      } catch (e) {
        expect(e, isA<Error>());
      }
    });
  });
}
