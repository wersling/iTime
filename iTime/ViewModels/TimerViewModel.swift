//
//  TimerViewModel.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    @Published var categories: [EventCategory] = []
    @Published var eventTypes: [EventType] = []
    @Published var showingAddEventType = false
    @Published var selectedCategory: EventCategory?
    
    private var modelContext: ModelContext
    private var timerService: TimerService
    
    init(modelContext: ModelContext, timerService: TimerService) {
        self.modelContext = modelContext
        self.timerService = timerService
        loadData()
    }
    
    func loadData() {
        // 初始化预设分类（仅首次安装）
        CategoryInitializer.initializeIfNeeded(modelContext: modelContext)
        
        // 加载分类
        let categoryDescriptor = FetchDescriptor<EventCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? modelContext.fetch(categoryDescriptor)) ?? []
        
        // 加载事件类型
        let eventTypeDescriptor = FetchDescriptor<EventType>(sortBy: [SortDescriptor(\.createdAt)])
        eventTypes = (try? modelContext.fetch(eventTypeDescriptor)) ?? []
    }
    
    func addEventType(name: String, category: EventCategory, customColor: String? = nil) {
        let eventType = EventType(name: name, customColorHex: customColor, category: category)
        modelContext.insert(eventType)
        try? modelContext.save()
        loadData()
    }
    
    func deleteEventType(_ eventType: EventType) {
        modelContext.delete(eventType)
        try? modelContext.save()
        loadData()
    }
    
    func startTimer(for eventType: EventType) {
        timerService.startTimer(for: eventType)
    }
    
    func stopTimer(minValidDuration: TimeInterval, calendarSyncEnabled: Bool, selectedCalendarId: String?) {
        timerService.stopTimer(
            minValidDuration: minValidDuration,
            calendarSyncEnabled: calendarSyncEnabled,
            selectedCalendarId: selectedCalendarId
        )
    }
    
    func switchEventType(to eventType: EventType, minValidDuration: TimeInterval, calendarSyncEnabled: Bool, selectedCalendarId: String?) {
        timerService.switchEventType(
            to: eventType,
            minValidDuration: minValidDuration,
            calendarSyncEnabled: calendarSyncEnabled,
            selectedCalendarId: selectedCalendarId
        )
    }
}

