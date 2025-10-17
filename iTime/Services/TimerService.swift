//
//  TimerService.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import Combine

@MainActor
class TimerService: ObservableObject {
    static let shared = TimerService()
    
    @Published var currentRecord: TimeRecord?
    @Published var elapsedTime: TimeInterval = 0
    @Published var lastNotificationTime: Date?
    
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var notificationService = NotificationService.shared
    private var calendarService = CalendarService.shared
    
    private init() {}
    
    // 配置ModelContext
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 开始计时
    func startTimer(for eventType: EventType) {
        // 如果已有活动记录，先停止
        if let current = currentRecord {
            stopTimer()
        }
        
        // 创建新记录
        let record = TimeRecord(startTime: Date(), eventType: eventType)
        modelContext?.insert(record)
        currentRecord = record
        elapsedTime = 0
        
        // 启动计时器
        startInternalTimer()
        
        // 安排1小时后的第一次提醒
        scheduleNextNotification()
    }
    
    // 停止计时
    func stopTimer(minValidDuration: TimeInterval = Constants.Settings.defaultMinDuration, calendarSyncEnabled: Bool = false, selectedCalendarId: String? = nil) {
        guard let record = currentRecord else { return }
        
        stopInternalTimer()
        
        // 完成记录
        record.complete(at: Date(), minValidDuration: minValidDuration)
        
        // 如果是有效记录且启用了日历同步，同步到日历
        if record.isValid && calendarSyncEnabled,
           let eventType = record.eventType {
            if let calendarEventId = calendarService.createEvent(
                title: eventType.name,
                startDate: record.startTime,
                endDate: record.endTime ?? Date(),
                calendarId: selectedCalendarId
            ) {
                record.calendarEventId = calendarEventId
            }
        }
        
        // 保存到数据库
        try? modelContext?.save()
        
        // 清理状态
        currentRecord = nil
        elapsedTime = 0
        lastNotificationTime = nil
        
        // 取消通知
        Task {
            await notificationService.cancelHourlyReminder()
        }
    }
    
    // 切换事件类型
    func switchEventType(to eventType: EventType, minValidDuration: TimeInterval = Constants.Settings.defaultMinDuration, calendarSyncEnabled: Bool = false, selectedCalendarId: String? = nil) {
        stopTimer(minValidDuration: minValidDuration, calendarSyncEnabled: calendarSyncEnabled, selectedCalendarId: selectedCalendarId)
        startTimer(for: eventType)
    }
    
    // 内部计时器
    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.elapsedTime += 1
                
                // 检查是否需要发送通知（每小时一次）
                self.checkHourlyNotification()
            }
        }
    }
    
    private func stopInternalTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // 检查并发送每小时通知
    private func checkHourlyNotification() {
        let hoursPassed = Int(elapsedTime / 3600)
        
        // 如果超过1小时，且距离上次通知已过1小时
        if hoursPassed > 0 {
            if let lastNotification = lastNotificationTime {
                let timeSinceLastNotification = Date().timeIntervalSince(lastNotification)
                if timeSinceLastNotification >= Constants.Notification.reminderInterval {
                    sendNotification()
                }
            } else {
                // 第一次到达1小时
                if elapsedTime >= Constants.Notification.reminderInterval {
                    sendNotification()
                }
            }
        }
    }
    
    private func sendNotification() {
        guard let eventType = currentRecord?.eventType else { return }
        
        lastNotificationTime = Date()
        Task {
            await notificationService.sendImmediateNotification(
                title: "时间提醒",
                body: "「\(eventType.name)」已经进行了\(Int(elapsedTime / 3600))小时"
            )
        }
    }
    
    private func scheduleNextNotification() {
        guard let eventType = currentRecord?.eventType else { return }
        
        let nextNotificationDate = Date().addingTimeInterval(Constants.Notification.reminderInterval)
        Task {
            await notificationService.scheduleHourlyReminder(for: eventType.name, at: nextNotificationDate)
        }
    }
    
    // 获取当前计时器的格式化时间
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

