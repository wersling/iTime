//
//  EventTypeStatisticsView.swift
//  iTime
//
//  按事件类型显示统计信息
//

import SwiftUI
import SwiftData

struct EventTypeStatisticsView: View {
    let eventTypeStatistics: [EventTypeStatistics]
    let onSelectEventType: (EventType) -> Void  // 点击事件类型的回调
    @Environment(\.dismiss) private var dismiss
    
    // 计算总时长
    private var totalDuration: TimeInterval {
        eventTypeStatistics.reduce(0) { $0 + $1.totalDuration }
    }
    
    // 计算百分比
    private var statisticsWithPercentage: [EventTypeStatisticsWithPercentage] {
        guard totalDuration > 0 else { return [] }
        
        return eventTypeStatistics.map { stat in
            EventTypeStatisticsWithPercentage(
                eventType: stat.eventType,
                totalDuration: stat.totalDuration,
                recordCount: stat.recordCount,
                percentage: stat.totalDuration / totalDuration
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 总计卡片
                    VStack(spacing: 8) {
                        Text("总计")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(totalDuration.formattedDuration)
                            .font(.system(size: 28, weight: .bold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // 统计列表
                    if !statisticsWithPercentage.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("事件统计")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(statisticsWithPercentage) { stat in
                                Button {
                                    onSelectEventType(stat.eventType)
                                    dismiss()
                                } label: {
                                    EventTypeStatisticRow(statistic: stat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("暂无数据")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("事件统计")
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
}

// 带百分比的事件统计
struct EventTypeStatisticsWithPercentage: Identifiable {
    let id = UUID()
    let eventType: EventType
    let totalDuration: TimeInterval
    let recordCount: Int
    let percentage: Double
}

// 事件统计行
struct EventTypeStatisticRow: View {
    let statistic: EventTypeStatisticsWithPercentage
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 分类图标
                if let category = statistic.eventType.category {
                    Image(systemName: category.icon)
                        .foregroundColor(statistic.eventType.displayColor)
                        .frame(width: 20)
                }
                
                // 事件名称和分类
                HStack(spacing: 4) {
                    Text(statistic.eventType.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let category = statistic.eventType.category {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 时长
                Text(statistic.totalDuration.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 箭头提示可以点击
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(statistic.eventType.displayColor)
                        .frame(width: geometry.size.width * statistic.percentage)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
            
            // 百分比和次数
            HStack {
                Text(String(format: "%.1f%%", statistic.percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(statistic.recordCount)次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statistic.eventType.displayColor.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

#Preview {
    EventTypeStatisticsView(eventTypeStatistics: [], onSelectEventType: { _ in })
}

