//
//  TimerService.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import Combine
import UIKit
import ActivityKit

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
    
    // Live Activity
    @available(iOS 16.1, *)
    private var currentActivity: Activity<TimerActivityAttributes>?
    
    // 触觉反馈生成器
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    
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
        // 触觉反馈：中等震动
        mediumImpact.impactOccurred()
        
        // 如果已有活动记录，先停止（不触发震动）
        if currentRecord != nil {
            stopTimer(triggerHaptic: false)
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
        
        // 启动 Live Activity
        startLiveActivity(for: eventType, startTime: record.startTime)
        
        print("▶️ 开始计时: \(eventType.name)")
    }
    
    // 停止计时
    func stopTimer(minValidDuration: TimeInterval = Constants.Settings.defaultMinDuration, calendarSyncEnabled: Bool = false, selectedCalendarId: String? = nil, triggerHaptic: Bool = true) {
        guard let record = currentRecord else { return }
        
        // 触觉反馈：重震动（双震）
        if triggerHaptic {
            heavyImpact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.heavyImpact.impactOccurred()
            }
        }
        
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
        
        // 停止 Live Activity
        stopLiveActivity()
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
    
    // 检查并发送通知
    private func checkHourlyNotification() {
        // 获取用户设置的通知间隔
        let intervalRawValue = UserDefaults.standard.integer(forKey: Constants.Settings.notificationInterval)
        let interval = NotificationInterval(rawValue: intervalRawValue) ?? .minutes60
        
        // 如果设置为「从不」，则不发送通知
        guard let reminderInterval = interval.timeInterval else { return }
        
        // 检查是否到达提醒时间
        if let lastNotification = lastNotificationTime {
            let timeSinceLastNotification = Date().timeIntervalSince(lastNotification)
            if timeSinceLastNotification >= reminderInterval {
                sendNotification(interval: interval)
            }
        } else {
            // 第一次检查：是否已经过了提醒间隔
            if elapsedTime >= reminderInterval {
                sendNotification(interval: interval)
            }
        }
    }
    
    private func sendNotification(interval: NotificationInterval) {
        guard let eventType = currentRecord?.eventType else { return }
        
        lastNotificationTime = Date()
        
        // 计算已用时间的友好显示
        let minutes = Int(elapsedTime / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        var timeString = ""
        if hours > 0 {
            timeString = "\(hours)小时"
            if remainingMinutes > 0 {
                timeString += "\(remainingMinutes)分钟"
            }
        } else {
            timeString = "\(minutes)分钟"
        }
        
        Task {
            await notificationService.sendImmediateNotification(
                title: "时间提醒",
                body: "「\(eventType.name)」已经进行了\(timeString)"
            )
        }
    }
    
    private func scheduleNextNotification() {
        guard let eventType = currentRecord?.eventType else { return }
        
        // 获取用户设置的通知间隔
        let intervalRawValue = UserDefaults.standard.integer(forKey: Constants.Settings.notificationInterval)
        let interval = NotificationInterval(rawValue: intervalRawValue) ?? .minutes60
        
        // 如果设置为「从不」，则不安排通知
        guard let reminderInterval = interval.timeInterval else { return }
        
        let nextNotificationDate = Date().addingTimeInterval(reminderInterval)
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
    
    // MARK: - Live Activity 管理
    
    @available(iOS 16.1, *)
    private func startLiveActivity(for eventType: EventType, startTime: Date) {
        print("🚀 启动 Live Activity...")
        
        // 检查系统支持
        let authInfo = ActivityAuthorizationInfo()
        print("📊 Live Activity 授权状态: \(authInfo.areActivitiesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("⚠️ Live Activity 未授权")
            return
        }
        
        // 先停止已有的 Activity
        stopLiveActivity()
        
        // 获取分类信息
        let categoryName = eventType.category?.name ?? "未分类"
        let categoryIcon = eventType.category?.icon ?? "circle.fill"
        let categoryColor = eventType.category?.colorHex ?? "#3B82F6"
        
        print("📝 事件信息: \(eventType.name) (\(categoryName))")
        
        // 创建 Activity 属性
        let attributes = TimerActivityAttributes(eventTypeID: eventType.id.uuidString)
        let contentState = TimerActivityAttributes.ContentState(
            startTime: startTime,
            eventName: eventType.name,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColor: categoryColor
        )
        
        do {
            // 启动 Live Activity
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity 已启动成功!")
            print("   - Activity ID: \(activity.id)")
            print("   - 事件: \(eventType.name)")
        } catch {
            print("❌ 启动 Live Activity 失败: \(error.localizedDescription)")
        }
    }
    
    private func stopLiveActivity() {
        if #available(iOS 16.1, *) {
            guard let activity = currentActivity else { return }
            
            Task {
                await activity.end(dismissalPolicy: .immediate)
                currentActivity = nil
                print("🛑 Live Activity 已停止")
            }
        }
    }
}

