//
//  CategoryInitializer.swift
//  iTime
//
//  用于管理预设分类的初始化，避免重复插入
//

import Foundation
import SwiftData

@MainActor
class CategoryInitializer {
    private static let hasInitializedKey = "hasInitializedPresetCategories"
    
    /// 检查并初始化预设分类（仅首次安装时）
    static func initializeIfNeeded(modelContext: ModelContext) {
        // 检查是否已经初始化过
        if UserDefaults.standard.bool(forKey: hasInitializedKey) {
            print("📦 预设分类已初始化过，跳过")
            return
        }
        
        // 检查数据库中是否已有分类（可能从 iCloud 同步恢复）
        let descriptor = FetchDescriptor<EventCategory>()
        if let existingCount = try? modelContext.fetchCount(descriptor), existingCount > 0 {
            print("📦 检测到已有分类数据（可能从 iCloud 恢复），标记为已初始化")
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            return
        }
        
        // 首次安装，插入预设分类
        print("📦 首次安装，初始化预设分类")
        for preset in EventCategory.presetCategories {
            modelContext.insert(preset)
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            print("✅ 预设分类初始化成功")
        } catch {
            print("❌ 预设分类初始化失败: \(error)")
        }
    }
    
    /// 重置初始化状态（仅用于调试）
    static func resetInitializationFlag() {
        UserDefaults.standard.removeObject(forKey: hasInitializedKey)
        print("🔄 已重置预设分类初始化标记")
    }
    
    /// 检查是否需要合并重复的分类
    static func checkAndMergeDuplicates(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<EventCategory>(sortBy: [SortDescriptor(\.name)])
        guard let allCategories = try? modelContext.fetch(descriptor) else { return }
        
        var seenNames = Set<String>()
        var duplicates: [EventCategory] = []
        
        for category in allCategories {
            if seenNames.contains(category.name) {
                duplicates.append(category)
            } else {
                seenNames.insert(category.name)
            }
        }
        
        if !duplicates.isEmpty {
            print("⚠️ 检测到 \(duplicates.count) 个重复分类")
            
            // 删除重复的分类
            for duplicate in duplicates {
                // 如果有关联的事件类型，需要重新关联到保留的分类
                if let eventTypes = duplicate.eventTypes, !eventTypes.isEmpty {
                    // 找到同名的保留分类
                    if let keepCategory = allCategories.first(where: { $0.name == duplicate.name && $0.id != duplicate.id }) {
                        for eventType in eventTypes {
                            eventType.category = keepCategory
                        }
                    }
                }
                
                modelContext.delete(duplicate)
            }
            
            do {
                try modelContext.save()
                print("✅ 已清理 \(duplicates.count) 个重复分类")
            } catch {
                print("❌ 清理重复分类失败: \(error)")
            }
        }
    }
}

