//
//  Constants.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation

// 通知间隔枚举
enum NotificationInterval: Int, CaseIterable, Identifiable {
    case never = 0
    case minutes5 = 300      // 5分钟
    case minutes15 = 900     // 15分钟
    case minutes30 = 1800    // 30分钟
    case minutes45 = 2700    // 45分钟
    case minutes60 = 3600    // 60分钟
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .never: return "从不"
        case .minutes5: return "每 5 分钟"
        case .minutes15: return "每 15 分钟"
        case .minutes30: return "每 30 分钟"
        case .minutes45: return "每 45 分钟"
        case .minutes60: return "每 60 分钟"
        }
    }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .never: return nil
        default: return TimeInterval(rawValue)
        }
    }
}

struct Constants {
    // UserDefaults Keys
    struct Settings {
        static let minValidDuration = "minValidDuration"
        static let selectedCalendarId = "selectedCalendarId"
        static let calendarSyncEnabled = "calendarSyncEnabled"
        static let notificationInterval = "notificationInterval"
        nonisolated(unsafe) static let defaultMinDuration: TimeInterval = 300 // 5分钟
    }
    
    // Notification
    struct Notification {
        static let hourlyReminderIdentifier = "hourlyReminder"
        nonisolated(unsafe) static let reminderInterval: TimeInterval = 3600 // 1小时（默认，已废弃）
    }
    
    // UI
    struct UI {
        nonisolated(unsafe) static let gridSpacing: CGFloat = 16
        nonisolated(unsafe) static let cornerRadius: CGFloat = 12
        nonisolated(unsafe) static let iconSize: CGFloat = 24
    }
}

