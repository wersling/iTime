//
//  CalendarService.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import EventKit
import Combine

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // 检查日历权限状态
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            loadCalendars()
        }
    }
    
    // 请求日历权限
    func requestAuthorization() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                checkAuthorizationStatus()
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                checkAuthorizationStatus()
                return granted
            }
        } catch {
            print("请求日历权限失败: \(error)")
            return false
        }
    }
    
    // 加载可用日历
    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }
    
    // 创建日历事件
    func createEvent(title: String, startDate: Date, endDate: Date, calendarId: String?) -> String? {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            print("没有日历访问权限")
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        
        // 选择日历
        if let calendarId = calendarId,
           let calendar = eventStore.calendar(withIdentifier: calendarId) {
            event.calendar = calendar
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("保存日历事件失败: \(error)")
            return nil
        }
    }
    
    // 删除日历事件
    func deleteEvent(with identifier: String) -> Bool {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            return false
        }
        
        guard let event = eventStore.event(withIdentifier: identifier) else {
            return false
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            return true
        } catch {
            print("删除日历事件失败: \(error)")
            return false
        }
    }
    
    // 获取日历显示名称
    func getCalendarName(for identifier: String?) -> String? {
        guard let identifier = identifier else { return nil }
        return eventStore.calendar(withIdentifier: identifier)?.title
    }
}

