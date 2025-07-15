//
//  BluetoothManager.swift
//  Runner
//
//  Created by Hawk on 2024/10/23.
//

import UIKit
import Flutter
import UserNotifications
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    private var blueInstance = BluetoothManager.shared
    private let eventStore = EKEventStore()
    private var notificationChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        notificationChannel = FlutterMethodChannel(name: "even_notifications", binaryMessenger: controller.binaryMessenger)

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Handle permission granted or error
        }
        UNUserNotificationCenter.current().delegate = self

        // Request calendar access
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                // Optionally fetch events here or on demand
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Listen for notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let title = content.title
        let body = content.body
        let userInfo = content.userInfo

        // Send notification data to Flutter
        sendNotificationToFlutter(title: title, body: body, userInfo: userInfo)

        completionHandler([.banner, .sound])
    }

    // Listen for notifications when user interacts with them
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        let title = content.title
        let body = content.body
        let userInfo = content.userInfo

        // Send notification data to Flutter
        sendNotificationToFlutter(title: title, body: body, userInfo: userInfo)

        completionHandler()
    }

    // Helper to send notification data to Flutter
    private func sendNotificationToFlutter(title: String, body: String, userInfo: [AnyHashable: Any]) {
        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "userInfo": userInfo
        ]
        notificationChannel?.invokeMethod("onNotification", arguments: payload)
    }

    // Fetch upcoming calendar events (example: next 10 events)
    func fetchUpcomingEvents(completion: @escaping ([EKEvent]) -> Void) {
        let calendars = eventStore.calendars(for: .event)
        let oneMonthAgo = Date()
        let oneMonthAfter = Calendar.current.date(byAdding: .month, value: 1, to: oneMonthAgo)!
        let predicate = eventStore.predicateForEvents(withStart: oneMonthAgo, end: oneMonthAfter, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        completion(Array(events.prefix(10)))
    }
}

// MARK: - FlutterStreamHandler
extension AppDelegate : FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    
       if (arguments as? String == "eventBleStatus"){
            //self.blueInstance.blueStatusSink = events
        } else if (arguments as? String == "eventBleReceive") {
            self.blueInstance.blueInfoSink = events
        } else if (arguments as? String == "eventSpeechRecognize") {
            BluetoothManager.shared.blueSpeechSink = events
        } else {
            // TODO
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

