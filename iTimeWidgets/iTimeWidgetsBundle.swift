//
//  iTimeWidgetsBundle.swift
//  iTimeWidgets
//
//  Created by Sean Zou on 2025/10/18.
//

import WidgetKit
import SwiftUI

@main
struct iTimeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // 注册 Timer Live Activity
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
