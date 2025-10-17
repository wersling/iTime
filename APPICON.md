# APP 图标切换功能

## 功能说明

iTime 支持动态切换应用图标，根据当前是否有事件在记录来自动切换图标：

- **默认图标（icon1）**：没有事件记录时显示
- **记录中图标（icon2）**：有事件正在记录时显示

## 技术实现

### 1. 图标资源

两套完整的图标资源已添加到项目中：

```
iTime/Assets.xcassets/
  ├── AppIcon.appiconset/              # 默认图标 (icon1)
  └── AppIcon-Recording.appiconset/    # 记录中图标 (icon2)
```

每套图标包含所有必需的尺寸：
- iPhone: 60x60 (@2x, @3x)
- iPad: 76x76, 83.5x83.5
- Spotlight: 40x40
- Settings: 29x29
- Notification: 20x20
- CarPlay: 60x60
- App Store: 1024x1024

### 2. Info.plist 配置

已在 `Info.plist` 中配置备用图标：

```xml
<key>CFBundleIcons</key>
<dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconFiles</key>
        <array>
            <string>AppIcon</string>
        </array>
    </dict>
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>AppIcon-Recording</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-Recording</string>
            </array>
        </dict>
    </dict>
</dict>
```

### 3. AppIconManager 服务

创建了专门的图标管理服务 `AppIconManager.swift`：

```swift
// 切换到记录中图标
AppIconManager.shared.setRecordingIcon()

// 切换回默认图标
AppIconManager.shared.setDefaultIcon()

// 获取当前图标
let current = AppIconManager.shared.currentIcon
```

### 4. 集成到 TimerService

图标切换已自动集成到计时器服务中：

- **开始计时时**：自动切换到记录中图标
- **停止计时时**：自动切换回默认图标
- **应用恢复时**：如果有活动记录，恢复记录中图标

## 用户体验

### 图标切换时机

| 操作 | 图标变化 |
|------|---------|
| 点击事件开始记录 | 默认 → 记录中 |
| 点击停止或切换事件 | 记录中 → 默认 |
| 应用在后台被杀死后恢复 | 根据是否有活动记录自动恢复 |
| 应用从后台返回前台 | 保持当前状态 |

### 图标切换特点

✅ **无缝切换**：使用 iOS 系统 API，切换流畅
✅ **自动管理**：无需用户手动操作
✅ **状态同步**：图标始终反映当前记录状态
✅ **持久化支持**：应用重启后自动恢复正确图标

## 注意事项

### iOS 限制

1. **首次切换会弹出系统提示**
   - iOS 系统限制，无法避免
   - 提示内容：「您已更改"iTime"的图标」
   - 用户体验：只在首次切换时出现

2. **需要真机测试**
   - 模拟器可能不完全支持图标切换
   - 建议在真机上测试完整功能

3. **最低系统版本**
   - iOS 10.3+ 支持备用图标
   - 本项目最低支持 iOS 16+，完全兼容

### 开发建议

**更新图标资源时：**

1. 替换 `icon1/` 目录下的所有图标文件（默认图标）
2. 替换 `icon2/` 目录下的所有图标文件（记录中图标）
3. 运行以下命令更新 Assets：
   ```bash
   # 更新默认图标
   cp icon1/* iTime/Assets.xcassets/AppIcon.appiconset/
   
   # 更新记录中图标
   cp icon2/* iTime/Assets.xcassets/AppIcon-Recording.appiconset/
   ```
4. 在 Xcode 中 Clean Build Folder (⌘⇧K)
5. 重新编译运行

**调试图标切换：**

查看控制台日志：
```
✅ 图标已切换至: AppIcon-Recording
✅ 图标已切换至: AppIcon
⚠️ 设备不支持备用图标
❌ 图标切换失败: [错误信息]
```

## 文件结构

```
iTime/
├── icon1/                          # 源文件：默认图标
│   ├── AppIcon@2x.png
│   ├── AppIcon@3x.png
│   └── ... (其他尺寸)
│
├── icon2/                          # 源文件：记录中图标
│   ├── AppIcon@2x.png
│   ├── AppIcon@3x.png
│   └── ... (其他尺寸)
│
└── iTime/
    ├── Assets.xcassets/
    │   ├── AppIcon.appiconset/              # 项目中使用：默认
    │   └── AppIcon-Recording.appiconset/    # 项目中使用：记录中
    │
    ├── Services/
    │   └── AppIconManager.swift             # 图标管理服务
    │
    └── Info.plist                           # 图标配置
```

## 相关文件

- `iTime/Services/AppIconManager.swift` - 图标切换管理
- `iTime/Services/TimerService.swift` - 集成图标切换逻辑
- `iTime/Info.plist` - 备用图标配置
- `iTime/Assets.xcassets/AppIcon.appiconset/` - 默认图标资源
- `iTime/Assets.xcassets/AppIcon-Recording.appiconset/` - 记录图标资源

## 测试建议

### 功能测试

1. **正常切换测试**
   - 启动应用（默认图标）
   - 开始记录一个事件
   - 查看主屏幕图标是否变为记录中图标
   - 停止记录
   - 查看图标是否恢复为默认图标

2. **后台恢复测试**
   - 开始记录事件
   - 切换到后台
   - 等待系统回收内存（或手动杀死应用）
   - 重新打开应用
   - 验证图标是否为记录中图标

3. **切换事件测试**
   - 开始记录事件A
   - 验证图标已切换
   - 切换到事件B
   - 验证图标保持记录状态

4. **异常情况测试**
   - 快速开始/停止记录
   - 多次切换事件
   - 验证图标状态始终正确

### 性能考虑

- 图标切换是异步操作，不会阻塞主线程
- 重复调用会自动去重（已有保护逻辑）
- 系统会缓存图标，切换后立即生效

## 未来优化方向

1. **更多图标状态**
   - 可以添加更多备用图标（如不同颜色主题）
   - 根据用户偏好选择图标

2. **用户手动切换**
   - 在设置页面提供图标选择功能
   - 允许用户自定义图标样式

3. **动态角标**
   - 结合图标切换显示记录时长
   - 使用角标提示活动状态

---

*最后更新：2025-10-17*

