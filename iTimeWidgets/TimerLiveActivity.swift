//
//  TimerLiveActivity.swift
//  iTimeWidgets
//
//  Live Activity Widget 视图
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // 锁屏界面展示
            LockScreenLiveActivityView(context: context)
            
        } dynamicIsland: { context in
            // 不显示在灵动岛，返回空的 DynamicIsland
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

// 锁屏界面视图
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 左侧：图标和事件信息
                Image(systemName: context.state.categoryIcon)
                    .font(.title2)
                    .foregroundColor(Color(hex: context.state.categoryColor))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: context.state.categoryColor).opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.eventName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(context.state.categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 右侧：计时器
                Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .activityBackgroundTint(.clear)
        .activitySystemActionForegroundColor(.white)
    }
}

// 颜色扩展（从十六进制字符串转换）
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

