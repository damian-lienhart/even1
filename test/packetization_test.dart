import 'package:flutter_test/flutter_test.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'dart:convert';

void main() {
  group('PacketizationTest', () {
    test('Splits long notification into multiple packets', () {
      final longText = 'A' * 1000;
      final notification = {
        'title': longText,
        'body': longText,
        'userInfo': {'long': longText}
      };
      final notifyId = 1;
      final data = utf8.encode(jsonEncode({'ncs_notification': notification}));
      final packets = Proto._getNotifyPackList(0x4B, notifyId, data);
      expect(packets.length > 1, true);
    });

    test('Each packet is correctly prefixed (command, notifyId, etc.)', () {
      final notification = {
        'title': 'Test',
        'body': 'Test',
        'userInfo': {}
      };
      final notifyId = 2;
      final data = utf8.encode(jsonEncode({'ncs_notification': notification}));
      final packets = Proto._getNotifyPackList(0x4B, notifyId, data);
      for (int i = 0; i < packets.length; i++) {
        expect(packets[i][0], 0x4B); // Command
        expect(packets[i][1], notifyId); // notifyId
        expect(packets[i][2], packets.length); // maxSeq
        expect(packets[i][3], i); // seq
      }
    });

    test('Correct number of packets for large payloads', () {
      final longText = 'B' * 2000;
      final notification = {
        'title': longText,
        'body': longText,
        'userInfo': {'long': longText}
      };
      final notifyId = 3;
      final data = utf8.encode(jsonEncode({'ncs_notification': notification}));
      final packets = Proto._getNotifyPackList(0x4B, notifyId, data);
      // Each packet (except last) should be 180 bytes (4 header + 176 data)
      for (int i = 0; i < packets.length - 1; i++) {
        expect(packets[i].length, 180);
      }
      // Last packet can be shorter
      expect(packets.last.length <= 180, true);
    });

    test('Edge case: payload exactly at the packet size limit', () {
      // 176 bytes data per packet, 4 bytes header
      final dataLen = 176;
      final data = List<int>.filled(dataLen, 65); // 'A' * 176
      final packets = Proto._getNotifyPackList(0x4B, 4, data);
      expect(packets.length, 1);
      expect(packets[0].length, 180);
    });

    test('Edge case: payload just over the packet size limit', () {
      final dataLen = 177;
      final data = List<int>.filled(dataLen, 66); // 'B' * 177
      final packets = Proto._getNotifyPackList(0x4B, 5, data);
      expect(packets.length, 2);
      expect(packets[0].length, 180);
      expect(packets[1].length, 5); // 4 header + 1 data
    });
  });
}
