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
    
    // 批量安排定时提醒（一次性预约多个通知）
    // startTime: 计时器开始时间
    // interval: 通知间隔
    func scheduleReminders(for eventName: String, startTime: Date, interval: TimeInterval) async {
        // 取消之前的提醒
        await cancelReminder()
        
        let center = UNUserNotificationCenter.current()
        
        // 计算通知数量：5 小时内的通知次数，最多 64 个（iOS 限制）
        let fiveHoursInSeconds: TimeInterval = 5 * 60 * 60
        let calculatedCount = Int(fiveHoursInSeconds / interval)
        let count = min(calculatedCount, 64)
        
        // 批量创建通知
        for i in 1...count {
            let fireTime = startTime.addingTimeInterval(interval * Double(i))
            let elapsedTime = fireTime.timeIntervalSince(startTime)
            
            // 只安排未来的通知
            guard fireTime > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "时间提醒"
            content.body = "「\(eventName)」已经进行了\(formatDuration(elapsedTime))"
            content.sound = .default
            
            let timeInterval = fireTime.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            
            // 使用序号作为标识符，便于管理
            let identifier = "\(Constants.Notification.timerReminderIdentifier)_\(i)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("安排通知 #\(i) 失败: \(error)")
            }
        }
        
        let totalDuration = Double(count) * interval
        print("✅ 已安排 \(count) 个定时提醒，间隔 \(formatDuration(interval))，覆盖 \(formatDuration(totalDuration))")
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
    
    // 取消所有定时提醒
    func cancelReminder() async {
        let center = UNUserNotificationCenter.current()
        
        // 获取所有待发送的通知
        let pendingRequests = await center.pendingNotificationRequests()
        
        // 找出所有计时器提醒的标识符
        let timerIdentifiers = pendingRequests
            .map { $0.identifier }
            .filter { $0.hasPrefix(Constants.Notification.timerReminderIdentifier) }
        
        // 批量取消
        center.removePendingNotificationRequests(withIdentifiers: timerIdentifiers)
        
        if !timerIdentifiers.isEmpty {
            print("🗑️ 已取消 \(timerIdentifiers.count) 个定时提醒")
        }
    }
}

