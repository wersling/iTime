//
//  RecordListView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import SwiftData

struct RecordListView: View {
    let records: [TimeRecord]
    @Environment(\.dismiss) private var dismiss
    
    // 按日期分组的记录
    private var groupedRecords: [(date: Date, records: [TimeRecord])] {
        let calendar = Calendar.current
        
        // 按日期分组
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.startTime)
        }
        
        // 排序：最新的日期在前
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, records: $0.value.sorted { $0.startTime > $1.startTime }) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    ContentUnavailableView(
                        "暂无记录",
                        systemImage: "clock.fill",
                        description: Text("开始计时后，记录会显示在这里")
                    )
                } else {
                    ForEach(groupedRecords, id: \.date) { group in
                        Section {
                            ForEach(group.records) { record in
                                RecordRow(record: record)
                            }
                        } header: {
                            HStack {
                                Text(formatSectionDate(group.date))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text(formatDayTotalDuration(group.records))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("详细记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 格式化日期标题
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "EEEE"  // 星期几
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: date)
        }
    }
    
    // 计算当天总时长
    private func formatDayTotalDuration(_ records: [TimeRecord]) -> String {
        let totalSeconds = records.reduce(0.0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) / 60 % 60
        
        if hours > 0 {
            return "共 \(hours)小时\(minutes)分钟"
        } else {
            return "共 \(minutes)分钟"
        }
    }
}

struct RecordRow: View {
    let record: TimeRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 主要信息
            VStack(alignment: .leading, spacing: 6) {
                // 事件名称
                if let eventType = record.eventType {
                    HStack(spacing: 6) {
                        // 分类图标与文字对齐
                        if let category = eventType.category {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(category.color)
                        }
                        
                        Text(eventType.name)
                            .font(.headline)
                        
                        if let category = eventType.category {
                            Text("·")
                                .foregroundColor(.secondary)
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 时间范围
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(record.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let endTime = record.endTime {
                        Text(endTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("进行中")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if record.calendarEventId != nil {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // 右侧：时长
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.formattedDuration)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !record.isValid {
                    Text("未达标")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecordListView(records: [])
}

