//
//  Constants.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation

struct Constants {
    // UserDefaults Keys
    struct Settings {
        static let minValidDuration = "minValidDuration"
        static let selectedCalendarId = "selectedCalendarId"
        static let calendarSyncEnabled = "calendarSyncEnabled"
        nonisolated(unsafe) static let defaultMinDuration: TimeInterval = 300 // 5分钟
    }
    
    // Notification
    struct Notification {
        static let hourlyReminderIdentifier = "hourlyReminder"
        nonisolated(unsafe) static let reminderInterval: TimeInterval = 3600 // 1小时
    }
    
    // UI
    struct UI {
        nonisolated(unsafe) static let gridSpacing: CGFloat = 16
        nonisolated(unsafe) static let cornerRadius: CGFloat = 12
        nonisolated(unsafe) static let iconSize: CGFloat = 24
    }
}

