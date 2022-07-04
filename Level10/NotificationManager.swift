//
//  NotificationManager.swift
//  Level10
//
//  Created by Dennis Beatty on 6/26/22.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    var deviceToken: String?
    
    private init() {}
    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func setDeviceToken(_ token: String) {
        deviceToken = token
        NotificationCenter.default.post(name: .didRegisterDeviceToken, object: nil)
    }
}
