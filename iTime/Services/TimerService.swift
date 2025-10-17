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
    private var appIconManager = AppIconManager.shared
    
    // UserDefaults keys for persistence
    private let activeRecordIdKey = "activeRecordId"
    private let lastUpdateTimeKey = "lastUpdateTime"
    
    private init() {}
    
    // 配置ModelContext并恢复状态
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        restoreActiveTimer()
    }
    
    // 恢复活动的计时器
    private func restoreActiveTimer() {
        guard let modelContext = modelContext else { return }
        
        // 如果已经有活动计时器，不要重复恢复
        if currentRecord != nil {
            print("⚠️ 已有活动计时器，跳过恢复")
            return
        }
        
        // 从 UserDefaults 读取活动记录ID
        guard let savedRecordIdString = UserDefaults.standard.string(forKey: activeRecordIdKey),
              let savedRecordId = UUID(uuidString: savedRecordIdString) else {
            return
        }
        
        // 查询该记录
        let predicate = #Predicate<TimeRecord> { record in
            record.id == savedRecordId && record.endTime == nil
        }
        let descriptor = FetchDescriptor<TimeRecord>(predicate: predicate)
        
        guard let records = try? modelContext.fetch(descriptor),
              let record = records.first else {
            // 记录不存在或已结束，清理状态
            clearPersistedState()
            return
        }
        
        // 恢复计时器状态
        currentRecord = record
        
        // 基于startTime计算已过时间，而不是使用lastUpdateTime
        elapsedTime = Date().timeIntervalSince(record.startTime)
        
        // 确保先停止旧Timer，再启动新的
        stopInternalTimer()
        startInternalTimer()
        
        // 重新安排通知
        scheduleNextNotification()
        
        // 切换到记录中图标
        appIconManager.setRecordingIcon()
        
        print("✅ 恢复计时器: \(record.eventType?.name ?? "未知"), 已运行 \(Int(elapsedTime))秒")
    }
    
    // 保存活动状态
    private func persistActiveState() {
        if let recordId = currentRecord?.id {
            UserDefaults.standard.set(recordId.uuidString, forKey: activeRecordIdKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateTimeKey)
        } else {
            clearPersistedState()
        }
    }
    
    // 清理持久化状态
    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: activeRecordIdKey)
        UserDefaults.standard.removeObject(forKey: lastUpdateTimeKey)
    }
    
    // 开始计时
    func startTimer(for eventType: EventType) {
        // 如果已有活动记录，先停止
        if currentRecord != nil {
            stopTimer()
        }
        
        // 确保先停止旧的Timer
        stopInternalTimer()
        
        // 创建新记录
        let record = TimeRecord(startTime: Date(), eventType: eventType)
        modelContext?.insert(record)
        try? modelContext?.save()
        
        currentRecord = record
        elapsedTime = 0
        
        // 持久化状态
        persistActiveState()
        
        // 启动计时器
        startInternalTimer()
        
        // 安排1小时后的第一次提醒
        scheduleNextNotification()
        
        // 切换到记录中图标
        appIconManager.setRecordingIcon()
        
        print("▶️ 开始计时: \(eventType.name)")
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
        
        print("⏹️ 停止计时: \(record.eventType?.name ?? "未知"), 时长: \(record.formattedDuration), 有效: \(record.isValid)")
        
        // 清理状态
        currentRecord = nil
        elapsedTime = 0
        lastNotificationTime = nil
        
        // 清理持久化状态
        clearPersistedState()
        
        // 取消通知
        Task {
            await notificationService.cancelHourlyReminder()
        }
        
        // 切换回默认图标
        appIconManager.setDefaultIcon()
    }
    
    // 切换事件类型
    func switchEventType(to eventType: EventType, minValidDuration: TimeInterval = Constants.Settings.defaultMinDuration, calendarSyncEnabled: Bool = false, selectedCalendarId: String? = nil) {
        stopTimer(minValidDuration: minValidDuration, calendarSyncEnabled: calendarSyncEnabled, selectedCalendarId: selectedCalendarId)
        startTimer(for: eventType)
    }
    
    // 内部计时器
    private func startInternalTimer() {
        // 确保先停止旧的Timer，避免累积
        stopInternalTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // 基于startTime实时计算，而不是累加（避免误差累积）
                if let startTime = self.currentRecord?.startTime {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
                
                // 每10秒更新一次持久化时间戳
                if Int(self.elapsedTime) % 10 == 0 {
                    self.persistActiveState()
                }
                
                // 检查是否需要发送通知（每小时一次）
                self.checkHourlyNotification()
            }
        }
        
        print("⏱️ 计时器已启动")
    }
    
    private func stopInternalTimer() {
        if timer != nil {
            print("⏹️ 停止旧计时器")
        }
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

