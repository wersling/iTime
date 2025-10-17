//
//  ChartView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import Charts

// 事件统计图表
struct EventTypeChartView: View {
    let statistics: [EventTypeStatistics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时长分布")
                .font(.headline)
            
            Chart(statistics) { stat in
                BarMark(
                    x: .value("时长", stat.totalDuration / 60),  // 转换为分钟
                    y: .value("事件", stat.eventType.name)
                )
                .foregroundStyle(stat.eventType.displayColor)
                .annotation(position: .trailing) {
                    Text(stat.totalDuration.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxisLabel("时长（分钟）")
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// 类别统计图表（保留以备用）
struct ChartView: View {
    let statistics: [EventStatistics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("类别分布")
                .font(.headline)
            
            Chart(statistics) { stat in
                BarMark(
                    x: .value("时长", stat.totalDuration / 60),  // 转换为分钟
                    y: .value("类别", stat.category.name)
                )
                .foregroundStyle(stat.category.color)
                .annotation(position: .trailing) {
                    Text(stat.totalDuration.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxisLabel("时长（分钟）")
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

#Preview {
    let category1 = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    let category2 = EventCategory(name: "学习", colorHex: "#10B981", icon: "book.fill")
    
    let eventType1 = EventType(name: "编程", category: category1)
    let eventType2 = EventType(name: "阅读", category: category2)
    
    let eventStats = [
        EventTypeStatistics(eventType: eventType1, totalDuration: 3600, recordCount: 3),
        EventTypeStatistics(eventType: eventType2, totalDuration: 1800, recordCount: 2)
    ]
    
    return EventTypeChartView(statistics: eventStats)
        .frame(height: 250)
        .padding()
}

