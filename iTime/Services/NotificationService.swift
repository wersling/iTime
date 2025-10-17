//
//  NotificationService.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // 检查通知权限状态
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    // 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("请求通知权限失败: \(error)")
            return false
        }
    }
    
    // 安排1小时提醒
    func scheduleHourlyReminder(for eventName: String, at fireDate: Date) async {
        // 取消之前的提醒
        await cancelHourlyReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "时间提醒"
        content.body = "「\(eventName)」已经进行了1小时"
        content.sound = .default
        
        let timeInterval = fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Constants.Notification.hourlyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("安排通知失败: \(error)")
        }
    }
    
    // 取消1小时提醒
    func cancelHourlyReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Constants.Notification.hourlyReminderIdentifier]
        )
    }
    
    // 立即发送通知（用于测试或立即提醒）
    func sendImmediateNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("发送通知失败: \(error)")
        }
    }
}

