//
//  ActiveTimerView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI

struct ActiveTimerView: View {
    let eventType: EventType
    let elapsedTime: TimeInterval
    let formattedTime: String
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 事件名称
            HStack {
                Circle()
                    .fill(eventType.displayColor)
                    .frame(width: 12, height: 12)
                
                Text(eventType.name)
                    .font(.headline)
                
                Spacer()
            }
            
            // 计时器显示
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(eventType.displayColor)
            
            // 持续时长文字
            // Text(elapsedTime.formattedDuration)
            //     .font(.subheadline)
            //     .foregroundColor(.secondary)
            
            // 停止按钮
            Button(action: onStop) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("停止")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(Constants.UI.cornerRadius)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(eventType.displayColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(eventType.displayColor, lineWidth: 2)
        )
        .padding()
    }
}

#Preview {
    let category = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    let eventType = EventType(name: "编程", category: category)
    
    return ActiveTimerView(
        eventType: eventType,
        elapsedTime: 3725,
        formattedTime: "01:02:05",
        onStop: {}
    )
}

