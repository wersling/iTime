//
//  SettingsViewModel.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import Foundation
import SwiftUI
import EventKit
import UserNotifications
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(Constants.Settings.minValidDuration) var minValidDuration: Double = Constants.Settings.defaultMinDuration
    @AppStorage(Constants.Settings.selectedCalendarId) var selectedCalendarId: String = ""
    @AppStorage(Constants.Settings.calendarSyncEnabled) var calendarSyncEnabled: Bool = false
    
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var calendarStatus: EKAuthorizationStatus = .notDetermined
    
    private let notificationService = NotificationService.shared
    private let calendarService = CalendarService.shared
    
    init() {
        Task {
            await loadPermissionStatus()
        }
    }
    
    func loadPermissionStatus() async {
        await notificationService.checkAuthorizationStatus()
        notificationStatus = notificationService.authorizationStatus
        
        calendarService.checkAuthorizationStatus()
        calendarStatus = calendarService.authorizationStatus
    }
    
    func requestNotificationPermission() async {
        _ = await notificationService.requestAuthorization()
        await loadPermissionStatus()
    }
    
    func requestCalendarPermission() async {
        _ = await calendarService.requestAuthorization()
        await loadPermissionStatus()
    }
    
    var minValidDurationInMinutes: Int {
        get { Int(minValidDuration / 60) }
        set { minValidDuration = Double(newValue * 60) }
    }
    
    var notificationStatusText: String {
        switch notificationStatus {
        case .notDetermined:
            return "未请求"
        case .denied:
            return "已拒绝"
        case .authorized, .provisional, .ephemeral:
            return "已授权"
        @unknown default:
            return "未知"
        }
    }
    
    var calendarStatusText: String {
        switch calendarStatus {
        case .notDetermined:
            return "未请求"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorized, .fullAccess:
            return "已授权"
        case .writeOnly:
            return "仅写入"
        @unknown default:
            return "未知"
        }
    }
    
    var availableCalendars: [EKCalendar] {
        calendarService.availableCalendars
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

