//
//  TimeRecord.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData

@Model
final class TimeRecord {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval  // 秒
    var calendarEventId: String?  // 日历事件ID
    var isValid: Bool  // 是否有效记录（超过最小时长）
    
    var eventType: EventType?
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, eventType: EventType? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = 0
        self.isValid = false
        self.eventType = eventType
    }
    
    // 完成记录
    func complete(at endTime: Date, minValidDuration: TimeInterval) {
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.isValid = duration >= minValidDuration
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

