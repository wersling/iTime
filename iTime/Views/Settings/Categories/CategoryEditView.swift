//
//  CategoryEditView.swift
//  iTime
//
//  Created by Linus Torvalds on 2025/11/21.
//

import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: EventCategory?
    
    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var icon: String = "circle.fill"
    @State private var showIconPicker = false
    @State private var isInitialized = false
    
    // 常用图标集合
    private let availableIcons = [
        "briefcase.fill", "book.fill", "house.fill", "graduationcap.fill",
        "gamecontroller.fill", "figure.run", "bed.double.fill", "ellipsis.circle.fill",
        "pencil", "folder.fill", "star.fill", "heart.fill", "bolt.fill",
        "cart.fill", "gift.fill", "airplane", "car.fill", "leaf.fill",
        "person.fill", "clock.fill", "tag.fill", "bookmark.fill"
    ]
    
    private var displayedIcons: [String] {
        var icons = availableIcons
        // 如果当前图标不在预设列表中，将其添加到开头显示
        // 并且排除默认的 "circle.fill" (如果它不在可用列表中)，避免显示空白/默认占位符
        if !icons.contains(icon) && icon != "circle.fill" {
            icons.insert(icon, at: 0)
        }
        return icons
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("分类名称", text: $name)
            }
            
            Section("图标") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                    ForEach(displayedIcons, id: \.self) { iconName in
                        Image(systemName: iconName)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(icon == iconName ? color.opacity(0.2) : Color.clear)
                            .foregroundColor(icon == iconName ? color : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                withAnimation {
                                    icon = iconName
                                }
                            }
                    }
                    
                    Button {
                        showIconPicker = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 5)
            }
            
            Section("颜色") {
                ColorPicker("选择颜色", selection: $color)
            }
        }
        .navigationTitle(category == nil ? "新建分类" : "编辑分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
        }
        .onAppear {
            guard !isInitialized else { return }
            isInitialized = true
            if let category {
                name = category.name
                color = category.color
                icon = category.icon
            }
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selection: $icon)
        }
    }
    
    private func save() {
        if let category {
            category.name = name
            category.colorHex = color.toHex() ?? "#3B82F6"
            category.icon = icon
        } else {
            let newCategory = EventCategory(
                name: name,
                colorHex: color.toHex() ?? "#3B82F6",
                icon: icon,
                sortOrder: 999
            )
            modelContext.insert(newCategory)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoryEditView(category: nil)
            .modelContainer(for: EventCategory.self, inMemory: true)
    }
}
