//
//  StatisticsView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedPeriod: StatisticsPeriod = .day
    @State private var selectedDate: Date = Date()
    @State private var showingRecordList = false
    @State private var selectedCategory: EventCategory? = nil  // 选中的分类，用于过滤记录
    
    // 动态查询当前时间段的记录
    private var timeRecords: [TimeRecord] {
        let (startDate, endDate) = getPeriodRange()
        let descriptor = FetchDescriptor<TimeRecord>(
            predicate: #Predicate<TimeRecord> { record in
                record.isValid && record.startTime >= startDate && record.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // 计算事件统计（按事件统计，用于图表）
    private var eventTypeStatistics: [EventTypeStatistics] {
        var statDict: [UUID: (eventType: EventType, duration: TimeInterval, count: Int)] = [:]
        
        for record in timeRecords {
            guard let eventType = record.eventType else { continue }
            
            if var stat = statDict[eventType.id] {
                stat.duration += record.duration
                stat.count += 1
                statDict[eventType.id] = stat
            } else {
                statDict[eventType.id] = (eventType, record.duration, 1)
            }
        }
        
        let stats = statDict.map { EventTypeStatistics(eventType: $0.value.eventType, totalDuration: $0.value.duration, recordCount: $0.value.count) }
        return stats.sorted { $0.totalDuration > $1.totalDuration }
    }
    
    // 计算类别统计（按类别统计，用于列表）
    private var statistics: [EventStatistics] {
        var statDict: [UUID: (category: EventCategory, duration: TimeInterval, count: Int)] = [:]
        
        for record in timeRecords {
            guard let eventType = record.eventType,
                  let category = eventType.category else { continue }
            
            if var stat = statDict[category.id] {
                stat.duration += record.duration
                stat.count += 1
                statDict[category.id] = stat
            } else {
                statDict[category.id] = (category, record.duration, 1)
            }
        }
        
        var stats = statDict.map { EventStatistics(category: $0.value.category, totalDuration: $0.value.duration, recordCount: $0.value.count) }
        
        // 计算百分比
        let totalDuration = stats.reduce(0) { $0 + $1.totalDuration }
        if totalDuration > 0 {
            stats = stats.map { stat in
                var newStat = stat
                newStat.percentage = stat.totalDuration / totalDuration
                return newStat
            }
        }
        
        return stats.sorted { $0.totalDuration > $1.totalDuration }
    }
    
    private var totalDuration: TimeInterval {
        timeRecords.reduce(0) { $0 + $1.duration }
    }
    
    // 过滤后的记录（用于显示详情）
    private var filteredRecords: [TimeRecord] {
        if let category = selectedCategory {
            return timeRecords.filter { record in
                record.eventType?.category?.id == category.id
            }
        }
        return timeRecords
    }
    
    // 记录列表标题
    private var recordListTitle: String {
        if let category = selectedCategory {
            return "\(category.name) - 详细记录"
        }
        return "详细记录"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间段选择器
                    Picker("时间段", selection: $selectedPeriod) {
                        ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 日期导航
                    HStack {
                        Button {
                            previousPeriod()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        
                        Spacer()
                        
                        Text(periodTitle)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            nextPeriod()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 总计时长
                    VStack(spacing: 8) {
                        Text("总计")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(totalDuration.formattedDuration)
                            .font(.system(size: 36, weight: .bold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // 图表（显示事件级别统计）
                    // if !eventTypeStatistics.isEmpty {
                    //     EventTypeChartView(statistics: eventTypeStatistics)
                    //         .frame(height: 250)
                    //         .padding()
                    // }
                    
                    // 统计列表
                    if !statistics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("分类统计")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(statistics) { stat in
                                Button {
                                    selectedCategory = stat.category
                                    showingRecordList = true
                                } label: {
                                    StatisticRow(statistic: stat)
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
                    
                    // 查看全部详细记录按钮
                    if !timeRecords.isEmpty {
                        Button {
                            selectedCategory = nil  // 清空分类过滤，显示全部记录
                            showingRecordList = true
                        } label: {
                            HStack {
                                Text("查看全部详细记录")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("统计")
            .sheet(isPresented: $showingRecordList) {
                RecordListView(records: filteredRecords, title: recordListTitle)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPeriodRange() -> (Date, Date) {
        switch selectedPeriod {
        case .day:
            return (selectedDate.startOfDay(), selectedDate.endOfDay())
        case .week:
            return (selectedDate.startOfWeek(), selectedDate.endOfWeek())
        case .month:
            return (selectedDate.startOfMonth(), selectedDate.endOfMonth())
        case .year:
            return (selectedDate.startOfYear(), selectedDate.endOfYear())
        }
    }
    
    private func previousPeriod() {
        switch selectedPeriod {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)!
        case .year:
            selectedDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate)!
        }
    }
    
    private func nextPeriod() {
        switch selectedPeriod {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
        case .year:
            selectedDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate)!
        }
    }
    
    private var periodTitle: String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "yyyy年M月d日"
        case .week:
            formatter.dateFormat = "yyyy年第w周"
        case .month:
            formatter.dateFormat = "yyyy年M月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        return formatter.string(from: selectedDate)
    }
}

// 统计行
struct StatisticRow: View {
    let statistic: EventStatistics
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 图标和名称
                Image(systemName: statistic.category.icon)
                    .foregroundColor(statistic.category.color)
                    .frame(width: 20)
                
                Text(statistic.category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
                        .fill(statistic.category.color)
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
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(statistic.category.color.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [EventCategory.self, EventType.self, TimeRecord.self], inMemory: true)
}

