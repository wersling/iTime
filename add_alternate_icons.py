#!/usr/bin/env python3
import os
import sys

pbxproj_path = "iTime.xcodeproj/project.pbxproj"

# 读取项目文件
with open(pbxproj_path, 'r') as f:
    content = f.read()

# 检查是否已经添加
if "AppIcon-Recording.appiconset" in content:
    print("备用图标已存在于项目中")
    sys.exit(0)

print("需要手动在Xcode中添加AppIcon-Recording.appiconset文件夹到项目")
print("请按照以下步骤操作：")
print("1. 在Xcode中右键点击iTime文件夹")
print("2. 选择 'Add Files to iTime...'")
print("3. 选择 iTime/AppIcon-Recording.appiconset 文件夹")
print("4. 确保勾选 'Copy items if needed' 和 'Create folder references'")
print("5. 点击 Add")
