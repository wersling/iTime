//
//  CalendarPickerView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import EventKit

struct CalendarPickerView: View {
    let calendars: [EKCalendar]
    @Binding var selectedCalendarId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // 默认日历选项
                Button {
                    selectedCalendarId = ""
                    dismiss()
                } label: {
                    HStack {
                        Text("默认日历")
                        Spacer()
                        if selectedCalendarId.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                // 可用日历列表
                ForEach(calendars, id: \.calendarIdentifier) { calendar in
                    Button {
                        selectedCalendarId = calendar.calendarIdentifier
                        dismiss()
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(cgColor: calendar.cgColor))
                                .frame(width: 12, height: 12)
                            
                            Text(calendar.title)
                            
                            Spacer()
                            
                            if selectedCalendarId == calendar.calendarIdentifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("选择日历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarPickerView(calendars: [], selectedCalendarId: .constant(""))
}

