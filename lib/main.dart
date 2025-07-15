
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationBridge.initialize((notification) {
    BLEManager.sendNotificationToGoggles(notification);
    // Forward notification to BLE manager
    // Example: BLEManager.sendNotificationToGoggles(notification);
    print('Received notification: $notification');
    // TODO: Implement BLE sending logic here
  });

  BleManager.get();
  Get.put(EvenaiModelController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Even AI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(), 
    );
  }
}

class NotificationBridge {
  static const MethodChannel _channel = MethodChannel('even_notifications');

  static void initialize(Function(Map<String, dynamic>) onNotification) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotification') {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        onNotification(payload);
      }
    });
  }
}
