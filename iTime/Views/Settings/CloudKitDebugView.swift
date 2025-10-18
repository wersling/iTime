//
//  CloudKitDebugView.swift
//  iTime
//
//  用于调试 CloudKit 同步状态
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudKitDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [EventCategory]
    @Query private var eventTypes: [EventType]
    @Query private var timeRecords: [TimeRecord]
    
    @State private var iCloudStatus: String = "检查中..."
    @State private var containerStatus: String = "检查中..."
    @State private var showingDeleteRecordsAlert = false
    @State private var showingDeleteAllDataAlert = false
    
    var body: some View {
        List {
            Section("iCloud 状态") {
                HStack {
                    Text("iCloud 账户")
                    Spacer()
                    Text(iCloudStatus)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("CloudKit 容器")
                    Spacer()
                    Text(containerStatus)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("本地数据统计") {
                HStack {
                    Text("事件分类")
                    Spacer()
                    Text("\(categories.count) 个")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("事件类型")
                    Spacer()
                    Text("\(eventTypes.count) 个")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("时间记录")
                    Spacer()
                    Text("\(timeRecords.count) 条")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("操作") {
                Button("刷新状态") {
                    checkCloudKitStatus()
                }
                
                Button("触发同步") {
                    triggerSync()
                }
                
                Button("查看容器 ID") {
                    showContainerInfo()
                }
            }
            
            Section("数据维护") {
                Button("检查并清理重复分类") {
                    CategoryInitializer.checkAndMergeDuplicates(modelContext: modelContext)
                }
                .foregroundColor(.orange)
                
                Button("重置初始化标记") {
                    CategoryInitializer.resetInitializationFlag()
                }
                .foregroundColor(.orange)
            }
            
            Section {
                Button("清除所有时间记录") {
                    showingDeleteRecordsAlert = true
                }
                .foregroundColor(.red)
                
                Button("清除所有数据") {
                    showingDeleteAllDataAlert = true
                }
                .foregroundColor(.red)
            } header: {
                Text("危险操作")
            } footer: {
                Text("⚠️ 危险操作：删除后数据无法恢复，且会通过 iCloud 同步到所有设备")
            }
            
            Section {
                Button("创建测试分类") {
                    createTestCategory()
                }
                .foregroundColor(.blue)
                
                Button("创建测试记录") {
                    createTestRecord()
                }
                .foregroundColor(.blue)
                
                Button("删除所有测试分类") {
                    deleteTestCategories()
                }
                .foregroundColor(.orange)
                
                Button("删除所有测试记录") {
                    deleteTestRecords()
                }
                .foregroundColor(.orange)
            } header: {
                Text("测试数据")
            } footer: {
                Text("测试分类以「测试分类」开头，测试记录关联的事件类型以「测试事件」开头")
            }
        }
        .navigationTitle("CloudKit 调试")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCloudKitStatus()
        }
        .alert("确认清除所有时间记录？", isPresented: $showingDeleteRecordsAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                deleteAllTimeRecords()
            }
        } message: {
            Text("将删除所有时间记录（\(timeRecords.count) 条），但保留分类和事件类型。此操作无法撤销，且会同步到所有设备。")
        }
        .alert("确认清除所有数据？", isPresented: $showingDeleteAllDataAlert) {
            Button("取消", role: .cancel) { }
            Button("清除全部数据", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("将删除所有分类（\(categories.count) 个）、事件类型（\(eventTypes.count) 个）和时间记录（\(timeRecords.count) 条）。此操作无法撤销，且会同步到所有设备。")
        }
    }
    
    // 检查 iCloud 状态
    private func checkCloudKitStatus() {
        // 检查 iCloud 账户状态
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    iCloudStatus = "❌ 错误: \(error.localizedDescription)"
                    return
                }
                
                switch status {
                case .available:
                    iCloudStatus = "✅ 已登录"
                    checkContainerStatus()
                case .noAccount:
                    iCloudStatus = "❌ 未登录"
                case .restricted:
                    iCloudStatus = "⚠️ 受限制"
                case .couldNotDetermine:
                    iCloudStatus = "❓ 无法确定"
                case .temporarilyUnavailable:
                    iCloudStatus = "⏳ 暂时不可用"
                @unknown default:
                    iCloudStatus = "❓ 未知状态"
                }
            }
        }
    }
    
    // 检查 CloudKit 容器状态
    private func checkContainerStatus() {
        let container = CKContainer(identifier: "iCloud.cn.wersling.itime.iTime")
        
        // 检查私有数据库
        let database = container.privateCloudDatabase
        
        // 使用 fetchAllRecordZones 来验证容器可用性
        database.fetchAllRecordZones { zones, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    // 如果是权限错误或其他严重错误
                    if nsError.code == CKError.notAuthenticated.rawValue {
                        self.containerStatus = "❌ 未登录 iCloud"
                    } else {
                        self.containerStatus = "⚠️ \(error.localizedDescription)"
                    }
                } else {
                    // 容器可用，显示区域信息
                    let zoneCount = zones?.count ?? 0
                    self.containerStatus = "✅ 可用 (\(zoneCount) 个记录区域)"
                    
                    // 打印更多信息到控制台
                    print("📦 CloudKit 容器状态:")
                    print("   - 容器 ID: \(container.containerIdentifier ?? "未知")")
                    print("   - 记录区域: \(zoneCount) 个")
                    if let zones = zones {
                        for zone in zones {
                            print("   - 区域: \(zone.zoneID.zoneName)")
                        }
                    }
                }
            }
        }
    }
    
    // 触发同步
    private func triggerSync() {
        do {
            try modelContext.save()
            print("✅ 数据已保存，CloudKit 将自动同步")
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }
    
    // 显示容器信息
    private func showContainerInfo() {
        let container = CKContainer(identifier: "iCloud.cn.wersling.itime.iTime")
        print("📦 容器 ID: \(container.containerIdentifier ?? "未知")")
        print("📦 默认容器: \(CKContainer.default().containerIdentifier ?? "未知")")
    }
    
    // 创建测试分类
    private func createTestCategory() {
        let testCategory = EventCategory(
            name: "测试分类 \(Date().timeIntervalSince1970)",
            colorHex: "#FF5733",
            icon: "star.fill",
            sortOrder: 999
        )
        
        modelContext.insert(testCategory)
        
        do {
            try modelContext.save()
            print("✅ 测试分类已创建: \(testCategory.name)")
        } catch {
            print("❌ 创建测试分类失败: \(error)")
        }
    }
    
    // 创建测试记录
    private func createTestRecord() {
        guard let firstCategory = categories.first else {
            print("⚠️ 请先创建分类")
            return
        }
        
        // 创建事件类型
        let testEventType = EventType(
            name: "测试事件 \(Date().timeIntervalSince1970)",
            category: firstCategory
        )
        modelContext.insert(testEventType)
        
        // 创建时间记录
        let testRecord = TimeRecord(
            startTime: Date(),
            endTime: Date().addingTimeInterval(300), // 5分钟后
            eventType: testEventType
        )
        testRecord.duration = 300
        testRecord.isValid = true
        
        modelContext.insert(testRecord)
        
        do {
            try modelContext.save()
            print("✅ 测试记录已创建")
        } catch {
            print("❌ 创建测试记录失败: \(error)")
        }
    }
    
    // 删除所有时间记录
    private func deleteAllTimeRecords() {
        let recordCount = timeRecords.count
        
        print("🗑️ 开始删除 \(recordCount) 条时间记录...")
        
        for record in timeRecords {
            modelContext.delete(record)
        }
        
        do {
            try modelContext.save()
            print("✅ 已删除 \(recordCount) 条时间记录")
        } catch {
            print("❌ 删除时间记录失败: \(error)")
        }
    }
    
    // 删除所有数据
    private func deleteAllData() {
        let categoryCount = categories.count
        let eventTypeCount = eventTypes.count
        let recordCount = timeRecords.count
        
        print("🗑️ 开始清除所有数据...")
        print("   - 分类: \(categoryCount) 个")
        print("   - 事件类型: \(eventTypeCount) 个")
        print("   - 时间记录: \(recordCount) 条")
        
        // 删除所有时间记录
        for record in timeRecords {
            modelContext.delete(record)
        }
        
        // 删除所有事件类型
        for eventType in eventTypes {
            modelContext.delete(eventType)
        }
        
        // 删除所有分类
        for category in categories {
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
            print("✅ 所有数据已清除")
            
            // 重置初始化标记，以便重新初始化预设分类
            CategoryInitializer.resetInitializationFlag()
            print("✅ 已重置初始化标记，下次启动将重新创建预设分类")
        } catch {
            print("❌ 清除数据失败: \(error)")
        }
    }
    
    // 删除所有测试分类
    private func deleteTestCategories() {
        let testCategories = categories.filter { $0.name.hasPrefix("测试分类") }
        
        if testCategories.isEmpty {
            print("ℹ️ 没有找到测试分类")
            return
        }
        
        print("🗑️ 开始删除 \(testCategories.count) 个测试分类...")
        
        for category in testCategories {
            // 同时删除关联的事件类型和记录（cascade delete）
            if let eventTypes = category.eventTypes {
                print("   - 将同时删除 \(eventTypes.count) 个关联的事件类型")
            }
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
            print("✅ 已删除 \(testCategories.count) 个测试分类")
        } catch {
            print("❌ 删除测试分类失败: \(error)")
        }
    }
    
    // 删除所有测试记录
    private func deleteTestRecords() {
        // 找到所有测试事件类型
        let testEventTypes = eventTypes.filter { $0.name.hasPrefix("测试事件") }
        
        if testEventTypes.isEmpty {
            print("ℹ️ 没有找到测试事件类型")
            return
        }
        
        // 找到所有关联的时间记录
        var testRecords: [TimeRecord] = []
        for eventType in testEventTypes {
            if let records = eventType.timeRecords {
                testRecords.append(contentsOf: records)
            }
        }
        
        print("🗑️ 开始删除测试数据...")
        print("   - 测试事件类型: \(testEventTypes.count) 个")
        print("   - 测试时间记录: \(testRecords.count) 条")
        
        // 删除时间记录
        for record in testRecords {
            modelContext.delete(record)
        }
        
        // 删除事件类型
        for eventType in testEventTypes {
            modelContext.delete(eventType)
        }
        
        do {
            try modelContext.save()
            print("✅ 已删除 \(testEventTypes.count) 个测试事件和 \(testRecords.count) 条测试记录")
        } catch {
            print("❌ 删除测试记录失败: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        CloudKitDebugView()
    }
}

