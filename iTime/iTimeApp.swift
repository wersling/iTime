//
//  iTimeApp.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import SwiftData

@main
struct iTimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            EventCategory.self,
            EventType.self,
            TimeRecord.self,
        ])
        
        // 配置支持iCloud同步
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // 处理应用生命周期变化
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // 进入后台时保存计时器状态
            print("📱 应用进入后台，保存计时器状态")
        case .inactive:
            // 即将进入非活动状态
            break
        case .active:
            // 应用激活（从后台返回或首次启动）
            print("📱 应用进入前台")
        @unknown default:
            break
        }
    }
}
