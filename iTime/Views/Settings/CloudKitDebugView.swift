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
            
            Section("测试数据") {
                Button("创建测试分类") {
                    createTestCategory()
                }
                .foregroundColor(.blue)
                
                Button("创建测试记录") {
                    createTestRecord()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("CloudKit 调试")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCloudKitStatus()
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
        
        // 使用 fetchAllRecordZones 来验证容器可用性，而不是直接查询
        database.fetchAllRecordZones { zones, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    // 如果是权限错误或其他严重错误
                    if nsError.code == CKError.notAuthenticated.rawValue {
                        containerStatus = "❌ 未登录 iCloud"
                    } else {
                        containerStatus = "⚠️ \(error.localizedDescription)"
                    }
                } else if zones != nil {
                    // 容器可用，尝试获取记录数量
                    fetchRecordCount(from: database)
                } else {
                    containerStatus = "✅ 可用"
                }
            }
        }
    }
    
    // 获取记录数量（不依赖 queryable 字段）
    private func fetchRecordCount(from database: CKDatabase) {
        // 使用 modificationDate 字段查询，这是 CloudKit 内置字段，总是可查询的
        let query = CKQuery(recordType: "CD_EventCategory", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    // 如果查询失败，只显示容器可用但无法获取详细信息
                    containerStatus = "✅ 可用 (无法查询详情)"
                    print("⚠️ CloudKit 查询错误: \(error.localizedDescription)")
                } else {
                    let count = records?.count ?? 0
                    containerStatus = "✅ 可用 (云端 \(count) 条分类记录)"
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
}

#Preview {
    NavigationStack {
        CloudKitDebugView()
    }
}

