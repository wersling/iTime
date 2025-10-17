//
//  EventTypeCell.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI

struct EventTypeCell: View {
    let eventType: EventType
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // 图标
                if let category = eventType.category {
                    Image(systemName: category.icon)
                        .font(.system(size: Constants.UI.iconSize))
                        .foregroundColor(isActive ? .white : eventType.displayColor)
                }
                
                // 名称
                Text(eventType.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isActive ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // 活动状态指示
                if isActive {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .scaleEffect(isActive ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: isActive
                            )
                        
                        Text("进行中")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(isActive ? eventType.displayColor : eventType.displayColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(eventType.displayColor, lineWidth: isActive ? 3 : 1)
            )
            .shadow(color: isActive ? eventType.displayColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("确定要删除「\(eventType.name)」吗？相关的时间记录将会保留。")
        }
    }
}

#Preview {
    let category = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    let eventType = EventType(name: "编程", category: category)
    
    return HStack {
        EventTypeCell(eventType: eventType, isActive: false, onTap: {}, onDelete: {})
        EventTypeCell(eventType: eventType, isActive: true, onTap: {}, onDelete: nil)
    }
    .padding()
}

