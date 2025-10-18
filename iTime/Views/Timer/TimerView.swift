//
//  TimerView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var timerService = TimerService.shared
    
    // 使用 @Query 直接查询数据，确保实时更新
    @Query(sort: \EventCategory.sortOrder) private var categories: [EventCategory]
    @Query(sort: \EventType.createdAt) private var eventTypes: [EventType]
    
    @AppStorage(Constants.Settings.minValidDuration) private var minValidDuration: Double = Constants.Settings.defaultMinDuration
    @AppStorage(Constants.Settings.calendarSyncEnabled) private var calendarSyncEnabled: Bool = false
    @AppStorage(Constants.Settings.selectedCalendarId) private var selectedCalendarId: String = ""
    
    @State private var showingAddEventType = false
    @State private var selectedCategory: EventCategory?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前计时器
                    if let currentRecord = timerService.currentRecord,
                       let eventType = currentRecord.eventType {
                        ActiveTimerView(
                            eventType: eventType,
                            elapsedTime: timerService.elapsedTime,
                            formattedTime: timerService.formattedElapsedTime,
                            onStop: {
                                stopTimer()
                            }
                        )
                    }
                    
                    // 按分类展示事件类型
                    ForEach(categories) { category in
                        let categoryEventTypes = eventTypes.filter { $0.category?.id == category.id }
                        
                        if !categoryEventTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // 分类标题
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(category.name)
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                // 事件类型网格
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: Constants.UI.gridSpacing) {
                                    ForEach(categoryEventTypes) { eventType in
                                        EventTypeCell(
                                            eventType: eventType,
                                            isActive: timerService.currentRecord?.eventType?.id == eventType.id,
                                            onTap: {
                                                handleEventTap(eventType)
                                            },
                                            onDelete: {
                                                deleteEventType(eventType)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("时间记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedCategory = nil  // 清空预选分类
                        showingAddEventType = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showingAddEventType) {
                AddEventTypeSheet(
                    categories: Array(categories),
                    preselectedCategory: selectedCategory,
                    onAdd: { name, category, color in
                        addEventType(name: name, category: category, customColor: color)
                        showingAddEventType = false
                    },
                    onCancel: {
                        showingAddEventType = false
                    }
                )
            }
            .onAppear {
                // 配置timer service
                timerService.configure(modelContext: modelContext)
                // 初始化预设分类（仅首次安装）
                CategoryInitializer.initializeIfNeeded(modelContext: modelContext)
                // 检查并清理重复分类（修复旧版本遗留问题）
                CategoryInitializer.checkAndMergeDuplicates(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addEventType(name: String, category: EventCategory, customColor: String?) {
        let eventType = EventType(name: name, customColorHex: customColor, category: category)
        modelContext.insert(eventType)
        try? modelContext.save()
    }
    
    private func deleteEventType(_ eventType: EventType) {
        modelContext.delete(eventType)
        try? modelContext.save()
    }
    
    private func handleEventTap(_ eventType: EventType) {
        if timerService.currentRecord?.eventType?.id == eventType.id {
            // 点击当前活动事件，停止计时
            stopTimer()
        } else if timerService.currentRecord != nil {
            // 切换到其他事件
            switchEventType(to: eventType)
        } else {
            // 开始新计时
            startTimer(for: eventType)
        }
    }
    
    private func startTimer(for eventType: EventType) {
        timerService.startTimer(for: eventType)
    }
    
    private func stopTimer() {
        timerService.stopTimer(
            minValidDuration: minValidDuration,
            calendarSyncEnabled: calendarSyncEnabled,
            selectedCalendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
        )
    }
    
    private func switchEventType(to eventType: EventType) {
        timerService.switchEventType(
            to: eventType,
            minValidDuration: minValidDuration,
            calendarSyncEnabled: calendarSyncEnabled,
            selectedCalendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
        )
    }
}

// 添加事件类型表单
struct AddEventTypeSheet: View {
    let categories: [EventCategory]
    let preselectedCategory: EventCategory?
    let onAdd: (String, EventCategory, String?) -> Void
    let onCancel: () -> Void
    
    @State private var name = ""
    @State private var selectedCategory: EventCategory?
    @State private var useCustomColor = false
    @State private var customColor: Color = .blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("事件名称") {
                    TextField("输入事件名称", text: $name)
                }
                
                Section("选择分类") {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.name)
                            }
                            .tag(category as EventCategory?)
                        }
                    }
                }
                
                Section {
                    Toggle("使用自定义颜色", isOn: $useCustomColor)
                    
                    if useCustomColor {
                        ColorPicker("选择颜色", selection: $customColor)
                    }
                } header: {
                    Text("颜色设置")
                } footer: {
                    Text("不使用自定义颜色时，将使用分类的默认颜色")
                }
            }
            .navigationTitle("添加事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let category = selectedCategory, !name.isEmpty else { return }
                        let colorHex = useCustomColor ? customColor.toHex() : nil
                        onAdd(name, category, colorHex)
                    }
                    .disabled(name.isEmpty || selectedCategory == nil)
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = preselectedCategory ?? categories.first
                }
            }
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [EventCategory.self, EventType.self, TimeRecord.self], inMemory: true)
}

