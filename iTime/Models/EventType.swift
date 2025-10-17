//
//  EventType.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class EventType {
    @Attribute(.unique) var id: UUID
    var name: String
    var customColorHex: String?  // 可选的自定义颜色
    var createdAt: Date
    
    var category: EventCategory?
    
    @Relationship(deleteRule: .cascade, inverse: \TimeRecord.eventType)
    var timeRecords: [TimeRecord]?
    
    init(id: UUID = UUID(), name: String, customColorHex: String? = nil, category: EventCategory? = nil) {
        self.id = id
        self.name = name
        self.customColorHex = customColorHex
        self.createdAt = Date()
        self.category = category
    }
    
    var displayColor: Color {
        if let hex = customColorHex {
            return Color(hex: hex) ?? category?.color ?? .blue
        }
        return category?.color ?? .blue
    }
}

