//
//  EventCategory.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class EventCategory {
    var id: UUID = UUID()  // CloudKit 不支持 unique 约束，改为有默认值
    var name: String = ""  // 添加默认值
    var colorHex: String = "#3B82F6"  // 存储颜色的十六进制值，添加默认值
    var icon: String = "circle.fill"  // SF Symbol 名称，添加默认值
    var sortOrder: Int = 0  // 排序顺序，添加默认值
    
    @Relationship(deleteRule: .cascade, inverse: \EventType.category)
    var eventTypes: [EventType]?
    
    init(id: UUID = UUID(), name: String, colorHex: String, icon: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.sortOrder = sortOrder
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // 预设类别
    static let presetCategories: [EventCategory] = [
        EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill", sortOrder: 0),
        EventCategory(name: "学习", colorHex: "#10B981", icon: "book.fill", sortOrder: 1),
        EventCategory(name: "家庭", colorHex: "#EC4899", icon: "house.fill", sortOrder: 2),
        EventCategory(name: "教育", colorHex: "#14B8A6", icon: "graduationcap.fill", sortOrder: 3),
        EventCategory(name: "娱乐", colorHex: "#F59E0B", icon: "gamecontroller.fill", sortOrder: 4),
        EventCategory(name: "运动", colorHex: "#EF4444", icon: "figure.run", sortOrder: 5),
        EventCategory(name: "休息", colorHex: "#8B5CF6", icon: "bed.double.fill", sortOrder: 6),
        EventCategory(name: "其他", colorHex: "#6B7280", icon: "ellipsis.circle.fill", sortOrder: 7)
    ]
}

