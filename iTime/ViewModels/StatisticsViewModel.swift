//
//  StatisticsViewModel.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import Combine

enum StatisticsPeriod: String, CaseIterable {
    case day = "日"
    case week = "周"
    case month = "月"
    case year = "年"
}

// 类别统计
struct EventStatistics: Identifiable {
    let id = UUID()
    let category: EventCategory
    let totalDuration: TimeInterval
    let recordCount: Int
    
    var percentage: Double = 0.0  // 百分比，由外部计算
}

// 事件统计（用于图表）
struct EventTypeStatistics: Identifiable {
    let id = UUID()
    let eventType: EventType
    let totalDuration: TimeInterval
    let recordCount: Int
}

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var selectedPeriod: StatisticsPeriod = .day
    @Published var selectedDate: Date = Date()
    @Published var timeRecords: [TimeRecord] = []
    @Published var statistics: [EventStatistics] = []
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    func loadData() {
        let (startDate, endDate) = getPeriodRange()
        
        // 获取时间范围内的记录
        let predicate = #Predicate<TimeRecord> { record in
            record.isValid && record.startTime >= startDate && record.startTime <= endDate
        }
        
        var descriptor = FetchDescriptor<TimeRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        timeRecords = (try? modelContext.fetch(descriptor)) ?? []
        
        // 计算统计数据
        calculateStatistics()
    }
    
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
    
    private func calculateStatistics() {
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
        
        // 转换为统计数组
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
        
        // 按时长排序
        statistics = stats.sorted { $0.totalDuration > $1.totalDuration }
    }
    
    func changePeriod(to period: StatisticsPeriod) {
        selectedPeriod = period
        loadData()
    }
    
    func changeDate(to date: Date) {
        selectedDate = date
        loadData()
    }
    
    func previousPeriod() {
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
        loadData()
    }
    
    func nextPeriod() {
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
        loadData()
    }
    
    var periodTitle: String {
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
    
    var totalDuration: TimeInterval {
        timeRecords.reduce(0) { $0 + $1.duration }
    }
}

