#!/bin/bash

echo "🔧 修复备用图标配置..."

# 1. 检查图标文件
echo "📁 检查图标文件..."
ls -la iTime/AppIcon-Recording.appiconset/ | grep "AppIcon-Recording@" | head -3

# 2. 在Xcode项目中添加文件引用
echo ""
echo "⚠️  需要在Xcode中手动操作："
echo ""
echo "1️⃣  在Xcode左侧项目导航中，右键点击 'iTime' 文件夹（与 Assets.xcassets 同级）"
echo ""
echo "2️⃣  选择 'Add Files to \"iTime\"...'"
echo ""
echo "3️⃣  选择 'iTime/AppIcon-Recording.appiconset' 文件夹"
echo ""
echo "4️⃣  在弹出的对话框中，确保："
echo "    ✅ 选中 'Create folder references' （会显示为蓝色文件夹）"
echo "    ❌ 不要选 'Create groups' （黄色文件夹）"
echo "    ✅ 勾选 'Copy items if needed'"
echo "    ✅ Add to targets: 勾选 'iTime'"
echo ""
echo "5️⃣  点击 'Add' 按钮"
echo ""
echo "6️⃣  验证：项目中应该看到蓝色的 'AppIcon-Recording.appiconset' 文件夹"
echo ""
echo "7️⃣  Clean Build Folder (⌘⇧K) 然后重新运行"
echo ""
echo "✅ 完成后图标切换功能即可正常工作！"
