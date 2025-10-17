//
//  ContentView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//
//  此文件已被MainTabView替代，保留用于向后兼容

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [EventCategory.self, EventType.self, TimeRecord.self], inMemory: true)
}
