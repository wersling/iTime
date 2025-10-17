//
//  AppIconManager.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import UIKit

/// 管理应用图标切换
@MainActor
class AppIconManager {
    static let shared = AppIconManager()
    
    private init() {}
    
    /// 图标名称
    enum IconName: String {
        case `default` = "AppIcon"           // 正常状态（主图标，传nil）
        case recording = "AppIcon-Recording" // 记录状态
        
        var alternateIconName: String? {
            switch self {
            case .default:
                return nil // 主图标用nil
            case .recording:
                return rawValue
            }
        }
    }
    
    /// 当前图标名称
    var currentIcon: IconName {
        if let iconName = UIApplication.shared.alternateIconName {
            return IconName(rawValue: iconName) ?? .default
        }
        return .default
    }
    
    /// 切换图标
    /// - Parameter icon: 目标图标
    func setIcon(_ icon: IconName) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("⚠️ 设备不支持备用图标")
            return
        }
        
        // 如果已经是目标图标，直接返回
        if currentIcon == icon {
            return
        }
        
        let iconName = icon.alternateIconName
        
        Task {
            do {
                try await UIApplication.shared.setAlternateIconName(iconName)
                print("✅ 图标已切换至: \(icon.rawValue)")
            } catch {
                print("❌ 图标切换失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 设置为默认图标
    func setDefaultIcon() {
        setIcon(.default)
    }
    
    /// 设置为记录中图标
    func setRecordingIcon() {
        setIcon(.recording)
    }
}

