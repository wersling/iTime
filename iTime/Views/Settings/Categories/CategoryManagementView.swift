//
//  CategoryManagementView.swift
//  iTime
//
//  Created by Linus Torvalds on 2025/11/21.
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EventCategory.sortOrder) private var categories: [EventCategory]
    
    @State private var editingCategory: EventCategory?
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    @State private var categoryToDelete: EventCategory?
    @State private var showDeleteAlert = false
    
    var filteredCategories: [EventCategory] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCategories) { category in
                Button {
                    // 编辑模式下点击行通常是选择，但在这种管理视图中，
                    // 我们保持点击进入编辑详情的逻辑，或者仅允许通过菜单编辑
                    editingCategory = category
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 30)
                        Text(category.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if editMode == .inactive {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                // 在编辑模式下禁用普通点击，防止误触，或者让它行为一致
                .disabled(editMode == .active)
            }
            .onDelete(perform: confirmDelete)
            .onMove(perform: moveCategories)
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("管理分类")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索分类")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "完成" : "编辑") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        showAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("新建分类")
                        }
                        .font(.headline)
                    }
                    Spacer()
                }
            }
        }
        .sheet(item: $editingCategory) { category in
            NavigationStack {
                CategoryEditView(category: category)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                CategoryEditView(category: nil)
            }
        }
        .alert("确认删除分类？", isPresented: $showDeleteAlert, presenting: categoryToDelete) { category in
            Button("删除", role: .destructive) {
                deleteCategory(category)
            }
            Button("取消", role: .cancel) {
                categoryToDelete = nil
            }
        } message: { category in
            Text("删除“\(category.name)”分类将同时删除其下所有事件。此操作不可撤销。")
        }
    }
    
    private func confirmDelete(at offsets: IndexSet) {
        // 这里我们只处理单选删除的情况，因为 List 的滑动删除一次只能删一个
        if let index = offsets.first {
            let category = filteredCategories[index]
            categoryToDelete = category
            showDeleteAlert = true
        }
    }
    
    private func deleteCategory(_ category: EventCategory) {
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
        categoryToDelete = nil
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var updatedItems = categories
        updatedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in updatedItems.enumerated() {
            item.sortOrder = index
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
            .modelContainer(for: EventCategory.self, inMemory: true)
    }
}
