//
//  SettingsView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import EventKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingCalendarPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 时间设置
                Section {
                    Stepper(value: $viewModel.minValidDurationInMinutes, in: 1...60) {
                        HStack {
                            Text("有效记录时长")
                            Spacer()
                            Text("\(viewModel.minValidDurationInMinutes)分钟")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("时间设置")
                } footer: {
                    Text("少于此时长的记录将不会被保存")
                }
                
                // 通知设置
                Section {
                    HStack {
                        Text("通知权限")
                        Spacer()
                        Text(viewModel.notificationStatusText)
                            .foregroundColor(viewModel.notificationStatus == .authorized ? .green : .secondary)
                    }
                    
                    if viewModel.notificationStatus == .notDetermined {
                        Button("请求通知权限") {
                            Task {
                                await viewModel.requestNotificationPermission()
                            }
                        }
                    } else if viewModel.notificationStatus == .denied {
                        Button("前往设置") {
                            viewModel.openAppSettings()
                        }
                    }
                } header: {
                    Text("通知设置")
                } footer: {
                    Text("开启通知后，单次事件超过1小时会收到提醒")
                }
                
                // 日历同步
                Section {
                    Toggle("启用日历同步", isOn: $viewModel.calendarSyncEnabled)
                    
                    if viewModel.calendarSyncEnabled {
                        HStack {
                            Text("日历权限")
                            Spacer()
                            Text(viewModel.calendarStatusText)
                                .foregroundColor(
                                    (viewModel.calendarStatus == .authorized || viewModel.calendarStatus == .fullAccess) ? .green : .secondary
                                )
                        }
                        
                        if viewModel.calendarStatus == .notDetermined {
                            Button("请求日历权限") {
                                Task {
                                    await viewModel.requestCalendarPermission()
                                }
                            }
                        } else if viewModel.calendarStatus == .denied {
                            Button("前往设置") {
                                viewModel.openAppSettings()
                            }
                        } else if viewModel.calendarStatus == .authorized || viewModel.calendarStatus == .fullAccess {
                            Button {
                                showingCalendarPicker = true
                            } label: {
                                HStack {
                                    Text("选择日历")
                                    Spacer()
                                    if !viewModel.selectedCalendarId.isEmpty,
                                       let calendarName = CalendarService.shared.getCalendarName(for: viewModel.selectedCalendarId) {
                                        Text(calendarName)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("默认日历")
                                            .foregroundColor(.secondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("日历同步")
                } footer: {
                    Text("完成的有效记录会自动同步到选中的日历")
                }
                
                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingCalendarPicker) {
                CalendarPickerView(
                    calendars: viewModel.availableCalendars,
                    selectedCalendarId: $viewModel.selectedCalendarId
                )
            }
        }
    }
}

#Preview {
    SettingsView()
}

