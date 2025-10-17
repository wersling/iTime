//
//  RecordListView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI

struct RecordListView: View {
    let records: [TimeRecord]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    RecordRow(record: record)
                }
            }
            .navigationTitle("详细记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RecordRow: View {
    let record: TimeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let eventType = record.eventType {
                    Circle()
                        .fill(eventType.displayColor)
                        .frame(width: 10, height: 10)
                    
                    Text(eventType.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(record.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(record.startTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let endTime = record.endTime {
                    Text(endTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if record.calendarEventId != nil {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let category = EventCategory(name: "工作", colorHex: "#3B82F6", icon: "briefcase.fill")
    let eventType = EventType(name: "编程", category: category)
    let record = TimeRecord(startTime: Date().addingTimeInterval(-3600), endTime: Date(), eventType: eventType)
    record.duration = 3600
    record.isValid = true
    
    return RecordListView(records: [record, record, record])
}

