//
//  ChartView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import Charts

struct ChartView: View {
    let statistics: [EventStatistics]
    
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

#Preview {
    let category1 = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    let category2 = EventCategory(name: "学习", colorHex: "#10B981", icon: "book.fill")
    
    let eventType1 = EventType(name: "编程", category: category1)
    let eventType2 = EventType(name: "阅读", category: category2)
    
    let stats = [
        EventStatistics(eventType: eventType1, totalDuration: 3600, recordCount: 3),
        EventStatistics(eventType: eventType2, totalDuration: 1800, recordCount: 2)
    ]
    
    return ChartView(statistics: stats)
        .frame(height: 250)
        .padding()
}

