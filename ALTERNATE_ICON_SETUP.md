# 备用图标设置指南

## ⚠️ 重要：手动添加步骤

由于iOS备用图标的特殊要求，需要在Xcode中手动添加图标文件夹到项目。

### 步骤

1. **打开Xcode项目**
   ```
   打开 iTime.xcodeproj
   ```

2. **添加图标文件夹**
   - 在左侧项目导航中，右键点击 `iTime` 文件夹
   - 选择 `Add Files to "iTime"...`
   - 导航到 `iTime/AppIcon-Recording.appiconset` 文件夹
   - **重要**：选中该文件夹后，确保：
     - ✅ 勾选 `Create folder references`（蓝色文件夹图标）
     - ❌ 不要勾选 `Create groups`（黄色文件夹图标）
     - ✅ Target membership 勾选 `iTime`
   - 点击 `Add`

3. **验证添加成功**
   - 在项目导航中应该看到蓝色的 `AppIcon-Recording.appiconset` 文件夹
   - 展开后可以看到所有 `.png` 文件
   - 文件名格式：`AppIcon-Recording-XX@Xx.png`

4. **清理并重新编译**
   ```
   Product → Clean Build Folder (⌘⇧K)
   Product → Build (⌘B)
   ```

5. **运行测试**
   - 在真机上运行应用
   - 开始记录一个事件
   - 返回主屏幕查看图标是否切换

### 文件结构

添加成功后，项目结构应该如下：

```
iTime/
├── Assets.xcassets/
│   └── AppIcon.appiconset/          # 主图标（在Assets中）
└── AppIcon-Recording.appiconset/    # 备用图标（作为文件夹引用）
    ├── AppIcon-Recording@2x.png
    ├── AppIcon-Recording@3x.png
    ├── AppIcon-Recording-20@2x.png
    └── ... (其他尺寸)
```

### 关键点

1. **位置要求**
   - ✅ 主图标：放在 `Assets.xcassets/AppIcon.appiconset/`
   - ✅ 备用图标：直接放在 `iTime/AppIcon-Recording.appiconset/` 作为文件夹引用

2. **文件名要求**
   - 主图标文件名：`AppIcon@2x.png`, `AppIcon@3x.png` 等
   - 备用图标文件名：`AppIcon-Recording@2x.png`, `AppIcon-Recording@3x.png` 等

3. **Info.plist 配置**
   ```xml
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
   ```

### 常见问题

**Q: 切换后图标变成空白？**
A: 确认 `AppIcon-Recording.appiconset` 已作为文件夹引用（蓝色图标）添加到项目

**Q: 编译后找不到图标文件？**
A: 检查 Build Phases → Copy Bundle Resources 中是否包含所有 `.png` 文件

**Q: 图标切换有系统提示？**
A: iOS系统限制，首次切换会提示，后续不会。代码已使用completion handler最小化提示。

### 验证清单

- [ ] `AppIcon-Recording.appiconset` 文件夹在项目中显示为蓝色
- [ ] 展开文件夹可以看到21个 `.png` 文件
- [ ] 文件名格式正确（包含 `AppIcon-Recording` 前缀）
- [ ] Build Phases 中包含这些图标文件
- [ ] Info.plist 配置正确
- [ ] Clean + Build 成功
- [ ] 真机运行测试通过

---

*添加完成后可以删除此文件*

