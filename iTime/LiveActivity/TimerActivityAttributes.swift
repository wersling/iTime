//
//  TimerActivityAttributes.swift
//  iTime
//
//  Live Activity 数据定义（主 App 和 Widget Extension 共享）
//

import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 动态内容：计时开始时间
        var startTime: Date
        // 事件名称
        var eventName: String
        // 分类名称
        var categoryName: String
        // 分类图标
        var categoryIcon: String
        // 分类颜色
        var categoryColor: String
    }
    
    // 静态内容：事件ID（用于停止计时）
    var eventTypeID: String
}
