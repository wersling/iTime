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
    }
}
