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
    
    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 30)
                        Text(category.name)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onDelete(perform: deleteCategories)
            .onMove(perform: moveCategories)
        }
        .navigationTitle("管理分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    EditButton()
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("完成") {
                    dismiss()
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
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(categories[index])
            }
            try? modelContext.save()
        }
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
