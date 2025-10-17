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
    @State private var viewModel: TimerViewModel?
    
    @AppStorage(Constants.Settings.minValidDuration) private var minValidDuration: Double = Constants.Settings.defaultMinDuration
    @AppStorage(Constants.Settings.calendarSyncEnabled) private var calendarSyncEnabled: Bool = false
    @AppStorage(Constants.Settings.selectedCalendarId) private var selectedCalendarId: String = ""
    
    @State private var showingAddEventType = false
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
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
                                        viewModel.stopTimer(
                                            minValidDuration: minValidDuration,
                                            calendarSyncEnabled: calendarSyncEnabled,
                                            selectedCalendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
                                        )
                                    }
                                )
                            }
                            
                            // 按分类展示事件类型
                            ForEach(viewModel.categories) { category in
                                let categoryEventTypes = viewModel.eventTypes.filter { $0.category?.id == category.id }
                        
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
                                                if timerService.currentRecord?.eventType?.id == eventType.id {
                                                    // 点击当前活动事件，停止计时
                                                    viewModel.stopTimer(
                                                        minValidDuration: minValidDuration,
                                                        calendarSyncEnabled: calendarSyncEnabled,
                                                        selectedCalendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
                                                    )
                                                } else if timerService.currentRecord != nil {
                                                    // 切换到其他事件
                                                    viewModel.switchEventType(
                                                        to: eventType,
                                                        minValidDuration: minValidDuration,
                                                        calendarSyncEnabled: calendarSyncEnabled,
                                                        selectedCalendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
                                                    )
                                                } else {
                                                    // 开始新计时
                                                    viewModel.startTimer(for: eventType)
                                                }
                                            },
                                            onDelete: {
                                                viewModel.deleteEventType(eventType)
                                            }
                                        )
                                    }
                                    
                                    // 添加按钮
                                    AddEventTypeButton {
                                        viewModel.selectedCategory = category
                                        showingAddEventType = true
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
                            showingAddEventType = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingAddEventType) {
                    AddEventTypeSheet(
                        categories: viewModel.categories,
                        preselectedCategory: viewModel.selectedCategory,
                        onAdd: { name, category, color in
                            viewModel.addEventType(name: name, category: category, customColor: color)
                            showingAddEventType = false
                        },
                        onCancel: {
                            showingAddEventType = false
                        }
                    )
                }
            }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                // 配置timer service
                timerService.configure(modelContext: modelContext)
                // 创建viewModel
                viewModel = TimerViewModel(modelContext: modelContext, timerService: timerService)
            }
        }
    }
}

// 添加事件类型按钮
struct AddEventTypeButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: Constants.UI.iconSize))
                    .foregroundColor(.secondary)
                
                Text("添加")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
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

