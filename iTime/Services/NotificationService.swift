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
    
    // 安排定时提醒
    func scheduleReminder(for eventName: String, at fireDate: Date, interval: TimeInterval) async {
        // 取消之前的提醒
        await cancelReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "时间提醒"
        content.body = "「\(eventName)」已经进行了\(formatDuration(interval))"
        content.sound = .default
        
        let timeInterval = fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Constants.Notification.timerReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("安排通知失败: \(error)")
        }
    }
    
    // 格式化时间间隔显示 - 简单直接
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) 小时"
            } else {
                return "\(hours) 小时 \(remainingMinutes) 分钟"
            }
        }
    }
    
    // 取消定时提醒
    func cancelReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Constants.Notification.timerReminderIdentifier]
        )
    }
}

