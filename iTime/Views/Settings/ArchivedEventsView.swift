//
//  ArchivedEventsView.swift
//  iTime
//
//  归档事件管理视图
//

import SwiftUI
import SwiftData

struct ArchivedEventsView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    
    @Query(filter: #Predicate<EventType> { $0.isArchived }, sort: \EventType.createdAt) private var archivedEvents: [EventType]
    
    var body: some View {
        NavigationStack {
            Group {
                if archivedEvents.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("暂无归档事件")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("归档的事件类型会显示在这里")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 归档事件列表
                    List {
                        ForEach(archivedEvents) { eventType in
                            HStack(spacing: 12) {
                                // 图标
                                if let category = eventType.category {
                                    Image(systemName: category.icon)
                                        .font(.title2)
                                        .foregroundColor(eventType.displayColor)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(eventType.displayColor.opacity(0.1))
                                        )
                                }
                                
                                // 事件信息
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(eventType.name)
                                        .font(.headline)
                                    
                                    if let category = eventType.category {
                                        Text(category.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // 恢复按钮
                                Button {
                                    unarchiveEventType(eventType)
                                } label: {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteEventTypes)
                    }
                }
            }
            .navigationTitle("归档事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if !archivedEvents.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func unarchiveEventType(_ eventType: EventType) {
        eventType.isArchived = false
        try? modelContext.save()
    }
    
    private func deleteEventTypes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(archivedEvents[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: EventCategory.self, EventType.self, configurations: config)
    
    // 创建测试数据
    let category = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    container.mainContext.insert(category)
    
    let eventType1 = EventType(name: "编程", category: category)
    eventType1.isArchived = true
    container.mainContext.insert(eventType1)
    
    let eventType2 = EventType(name: "会议", category: category)
    eventType2.isArchived = true
    container.mainContext.insert(eventType2)
    
    return ArchivedEventsView(modelContext: container.mainContext)
}

